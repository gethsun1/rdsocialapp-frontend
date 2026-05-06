import 'package:foap/api_handler/apis/post_api.dart';
import 'package:foap/api_handler/apis/users_api.dart';
import 'package:foap/controllers/misc/misc_controller.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/post/post_controller.dart';
import '../controllers/post/archived_post_controller.dart';
import '../controllers/post/saved_post_controller.dart';
import '../model/post_model.dart';

class PostCardController extends GetxController {
  final PostController postController = Get.find();
  RxMap<int, int> postScrollIndexMapping = <int, int>{}.obs;
  RxInt currentIndex = 0.obs;
  int currentPostId = 0;
  RxList<PostModel> likedPosts = <PostModel>[].obs;
  RxList<PostModel> savedPosts = <PostModel>[].obs;
  RxBool enableComments = true.obs;

  void toggleEnableComments() {
    enableComments.value = !enableComments.value;
    update();
  }

  void updateGallerySlider(int index, int postId) {
    postScrollIndexMapping[postId] = index;
    currentIndex.value = index;
    currentPostId = postId;
  }

  void reportPost({required PostModel post, required VoidCallback callback}) {
    PostApi.reportPost(postId: post.id, resultCallback: callback);
  }

  void deletePost({required PostModel post, required VoidCallback callback}) {
    PostApi.deletePost(postId: post.id, resultCallback: callback);
  }

  Future<void> archiveUnarchivePost({
    required PostModel post,
    VoidCallback? callback,
  }) async {
    final shouldArchive = !post.isArchived;
    final response = await PostApi.archiveUnarchivePost(
        archive: shouldArchive, postId: post.id);

    if (response?.success != true) {
      final message = response?.message;
      AppUtil.showToast(
          message:
              message == null || message.isEmpty ? errorString.tr : message.tr,
          isSuccess: false);
      return;
    }

    post.isArchived = shouldArchive;
    postController.posts.removeWhere((item) => item.id == post.id);
    postController.posts.refresh();
    postController.update();

    if (Get.isRegistered<ArchivedPostController>()) {
      final archivedPostController = Get.find<ArchivedPostController>();
      if (shouldArchive) {
        final exists = archivedPostController.posts
            .any((archivedPost) => archivedPost.id == post.id);
        if (!exists) {
          archivedPostController.posts.insert(0, post);
        }
      } else {
        archivedPostController.posts
            .removeWhere((archivedPost) => archivedPost.id == post.id);
      }
      archivedPostController.posts.refresh();
      archivedPostController.update();
    }

    callback?.call();
  }

  void sharePost({required PostModel post}) {
    SharePlus.instance.share(ShareParams(text: post.shareLink));

    // downloadAndShareMedia(post);
  }

  void blockUser({required int userId, required VoidCallback callback}) {
    UsersApi.blockUser(userId: userId, resultCallback: callback);
  }

  void likeUnlikePost({
    required PostModel post,
  }) {
    post.isLike = !post.isLike;
    if (post.isLike) {
      likedPosts.add(post);
    } else {
      likedPosts.remove(post);
    }
    likedPosts.refresh();
    post.totalLike = post.isLike ? (post.totalLike) + 1 : (post.totalLike) - 1;

    PostApi.likeUnlikePost(like: post.isLike, postId: post.id);
  }

  Future<bool> pinUnpinPost({required PostModel post}) async {
    final miscController = Get.find<MiscController>();

    if (post.isPinned) {
      final pinId = post.pinId;
      if (pinId == null) {
        AppUtil.showToast(message: errorString.tr, isSuccess: false);
        return false;
      }

      final success =
          await miscController.removeFromPin(PinContentType.post, pinId);
      if (success) {
        post.isPinned = false;
        post.pinId = null;
        postController.sortPostsForDisplay();
        update();
      } else {
        AppUtil.showToast(message: errorString.tr, isSuccess: false);
      }
      return success;
    }

    final pinId =
        await miscController.addToPin(PinContentType.post, post.id, (id) {
      post.pinId = id;
    });
    final success = pinId != null;
    if (success) {
      post.pinId = pinId;
      post.isPinned = true;
      postController.sortPostsForDisplay();
      update();
    } else {
      AppUtil.showToast(message: errorString.tr, isSuccess: false);
    }
    return success;
  }

  Future<void> saveUnSavePost({
    required PostModel post,
  }) async {
    final previousValue = post.isSaved;
    post.isSaved = !post.isSaved;
    if (post.isSaved) {
      savedPosts.add(post);
      if (Get.isRegistered<SavedPostController>()) {
        final savedPostController = Get.find<SavedPostController>();
        final exists = savedPostController.posts
            .any((savedPost) => savedPost.id == post.id);
        if (!exists) {
          savedPostController.posts.insert(0, post);
          savedPostController.posts.refresh();
        }
      }
    } else {
      savedPosts.remove(post);
      if (Get.isRegistered<SavedPostController>()) {
        Get.find<SavedPostController>()
            .posts
            .removeWhere((savedPost) => savedPost.id == post.id);
      }
    }
    savedPosts.refresh();

    final success =
        await PostApi.saveUnSavePost(save: post.isSaved, postId: post.id);
    if (!success) {
      post.isSaved = previousValue;
      if (post.isSaved) {
        savedPosts.add(post);
        if (Get.isRegistered<SavedPostController>()) {
          final savedPostController = Get.find<SavedPostController>();
          final exists = savedPostController.posts
              .any((savedPost) => savedPost.id == post.id);
          if (!exists) {
            savedPostController.posts.insert(0, post);
          }
          savedPostController.posts.refresh();
        }
      } else {
        savedPosts.remove(post);
        if (Get.isRegistered<SavedPostController>()) {
          Get.find<SavedPostController>()
              .posts
              .removeWhere((savedPost) => savedPost.id == post.id);
        }
      }
      savedPosts.refresh();
      AppUtil.showToast(message: errorString.tr, isSuccess: false);
      return;
    }

    if (post.isSaved) {
      AppUtil.showToast(message: postBookmarkedString.tr, isSuccess: true);
    }
  }

  void reSharePost(
      {required int postId,
      required String comment,
      required bool enableComments,
      VoidCallback? successHandler}) {
    EasyLoading.show(status: loadingString.tr);
    PostApi.addPost(
        sharingPostId: postId,
        allowComments: enableComments,
        postType: PostType.reshare,
        postContentType: PostContentType.text,
        gallery: [],
        title: comment,
        resultCallback: (value) {
          EasyLoading.dismiss();
          if (value != null) {
            successHandler?.call();
          }
          update();
        });
  }
}
