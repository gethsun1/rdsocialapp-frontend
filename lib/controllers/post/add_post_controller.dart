import 'dart:async';
import 'dart:io';
import 'package:foap/api_handler/apis/post_api.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/helper/string_extension.dart';
import 'package:video_compress/video_compress.dart';
import '../../api_handler/apis/misc_api.dart';
import '../../helper/enum_linking.dart';
import '../../model/location.dart';
import '../../screens/chat/media.dart';
import '../../util/constant_util.dart';
import '../home/home_controller.dart';
import 'package:path_provider/path_provider.dart';

class AddPostController extends GetxController {
  final HomeController _homeController = Get.find();

  RxInt currentIndex = 0.obs;

  Rx<PostingStatus> postingStatus = PostingStatus.none.obs;
  RxBool isErrorInPosting = false.obs;

  RxBool enableComments = true.obs;

  List<Media> postingMedia = [];
  late String postingTitle;

  RxBool isPreviewMode = false.obs;

  Rx<LocationModel?> taggedLocation = Rx<LocationModel?>(null);
  RxList<UserModel> collaborators = <UserModel>[].obs;

  PostType? currentPostType;

  void clear() {
    currentIndex.value = 0;
    postingStatus.value = PostingStatus.none;
    isErrorInPosting.value = false;
    isPreviewMode.value = false;
    enableComments.value = true;
    taggedLocation.value = null;
    collaborators.clear();

    update();
  }

  void updateGallerySlider(int index) {
    currentIndex.value = index;
    update();
  }

  void togglePreviewMode() {
    isPreviewMode.value = !isPreviewMode.value;
    update();
  }

  void toggleEnableComments() {
    enableComments.value = !enableComments.value;
    update();
  }

  void discardFailedPost() {
    postingMedia = [];
    postingTitle = '';
    postingStatus.value = PostingStatus.none;
    isErrorInPosting.value = false;
    clear();
  }

  void retryPublish() {
    submitPost(
        items: postingMedia,
        title: postingTitle,
        postType: currentPostType!,
        allowComments: true,
        postCompletionHandler: () {});
  }

  void submitPost(
      {required PostType postType,
      required List<Media> items,
      required String title,
      required bool allowComments,
      required VoidCallback postCompletionHandler,
      int? competitionId,
      int? clubId,
      int? eventId,
      int? fundRaisingCampaignId,
      bool isReel = false,
      int? audioId,
      double? audioStartTime,
      double? audioEndTime}) async {
    final trimmedTitle = title.trim();
    if (items.isEmpty && trimmedTitle.isEmpty) {
      AppUtil.showToast(
          message: 'Please add text or media to publish a post.',
          isSuccess: false);
      return;
    }

    currentPostType = postType;
    postingMedia = items;
    postingTitle = trimmedTitle;
    postingStatus.value = PostingStatus.posting;

    try {
      final responses = await Future.wait([
        for (Media media in items)
          uploadMedia(
            media,
            competitionId,
          )
      ]);

      final galleryItems = responses.where((e) => e.isNotEmpty).toList();
      if (galleryItems.length != items.length) {
        postingStatus.value = PostingStatus.none;
        isErrorInPosting.value = true;
        AppUtil.showToast(
            message: 'Media upload failed. Please check network and try again.',
            isSuccess: false);
        return;
      }

      publishAction(
        postType: postType,
        galleryItems: galleryItems,
        postCompletionHandler: postCompletionHandler,
        title: trimmedTitle,
        tags: trimmedTitle.getHashtags(),
        location: taggedLocation.value,
        mentions: trimmedTitle.getMentions(),
        allowComments: allowComments,
        competitionId: competitionId,
        clubId: clubId,
        eventId: eventId,
        fundRaisingCampaignId: fundRaisingCampaignId,
        isReel: isReel,
        audioId: audioId,
        audioStartTime: audioStartTime,
        audioEndTime: audioEndTime,
      );
    } catch (e) {
      postingStatus.value = PostingStatus.none;
      isErrorInPosting.value = true;
      debugPrint('[AddPost] submitPost failed: $e');
      AppUtil.showToast(
          message: 'Unable to publish post right now. Please try again.',
          isSuccess: false);
    }
  }

  Future<Map<String, String>> uploadMedia(
      Media media, int? competitionId) async {
    final completer = Completer<Map<String, String>>();
    final mediaId = (media.id ?? randomId()).replaceAll('/', '');
    media.id ??= mediaId;

    final tempDir = await getTemporaryDirectory();
    File file;
    String? videoThumbnailPath;

    if (media.mediaType == GalleryMediaType.photo && media.file != null) {
      // ImagePicker already constrains post images before this point. Uploading
      // the picked file directly avoids Android-side recompression edge cases
      // that can produce an empty gallery payload even when the server is up.
      uploadMainFile(
          media.file!, media, videoThumbnailPath, competitionId, completer);
    } else if (media.mediaType == GalleryMediaType.gif) {
      final gallery = {
        'filename': media.filePath!,
        'video_thumb': videoThumbnailPath ?? '',
        'type': competitionId == null ? '1' : '2',
        'media_type': mediaTypeIdFromMediaType(media.mediaType!).toString(),
        'is_default': '1',
      };
      completer.complete(gallery);
    } else if (media.mediaType == GalleryMediaType.video &&
        media.file != null) {
      EasyLoading.show(status: loadingString.tr);
      try {
        MediaInfo? mediaInfo = await VideoCompress.compressVideo(
          media.file!.path,
          quality: VideoQuality.DefaultQuality,
          deleteOrigin: false, // It's false by default
        );

        file = mediaInfo?.file ?? media.file!;

        if (media.thumbnail != null) {
          final videoThumbnail =
              await File('${tempDir.path}/${mediaId}_thumbnail.png').create();

          videoThumbnail.writeAsBytesSync(media.thumbnail!);

          await MiscApi.uploadFile(
            videoThumbnail.path,
            mediaType: media.mediaType!,
            type: UploadMediaType.post,
            resultCallback: (fileName, filePath) async {
              videoThumbnailPath = fileName;
              try {
                await videoThumbnail.delete();
              } catch (_) {}
            },
          );
        }
      } catch (e) {
        debugPrint('[AddPost] video preprocessing failed: $e');
        file = media.file!;
      }

      uploadMainFile(file, media, videoThumbnailPath, competitionId, completer);
    } else if (media.file != null) {
      // for audio files
      uploadMainFile(
          media.file!, media, videoThumbnailPath, competitionId, completer);
    } else {
      if (!completer.isCompleted) {
        completer.complete({});
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => {},
    );
  }

  Future<void> uploadMainFile(
      File file,
      Media media,
      String? videoThumbnailPath,
      int? competitionId,
      Completer<Map<String, String>> completer) async {
    Map<String, String> gallery = {};

    try {
      final uploadFile = await _uploadableFile(file, media);
      if (uploadFile == null) {
        debugPrint('[AddPost] upload source file is missing: ${file.path}');
        return;
      }

      await MiscApi.uploadFile(uploadFile.path,
          type: UploadMediaType.post,
          mediaType: media.mediaType!, resultCallback: (fileName, filePath) {
        final imagePath = fileName;

        gallery = {
          'filename': imagePath,
          'video_thumb': videoThumbnailPath ?? '',
          'type': competitionId == null ? '1' : '2',
          'media_type': mediaTypeIdFromMediaType(media.mediaType!).toString(),
          'is_default': '1',
          'height': (media.size?.height ?? 0).toString(),
          'width': (media.size?.width ?? 0).toString(),
          'audio_time': (media.duration ?? 0).toString()
        };
        if (!completer.isCompleted) {
          completer.complete(gallery);
        }

        unawaited(uploadFile.delete().catchError((_) => uploadFile));
      });
    } catch (e) {
      debugPrint('[AddPost] uploadMainFile failed: $e');
    }

    if (!completer.isCompleted) {
      completer.complete({});
    }
  }

  Future<File?> _uploadableFile(File file, Media media) async {
    if (await file.exists()) {
      return file;
    }

    final bytes = media.mainFileBytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final mediaId = (media.id ?? randomId()).replaceAll('/', '');
    media.id ??= mediaId;
    final tempDir = await getTemporaryDirectory();
    final extension = _uploadExtension(media);
    final fallbackFile =
        await File('${tempDir.path}/${mediaId}_upload$extension')
            .create(recursive: true);
    await fallbackFile.writeAsBytes(bytes, flush: true);
    media.file = fallbackFile;
    return fallbackFile;
  }

  String _uploadExtension(Media media) {
    switch (media.mediaType) {
      case GalleryMediaType.video:
        return '.mp4';
      case GalleryMediaType.audio:
        return '.mp3';
      default:
        return '.jpg';
    }
  }

  void publishAction({
    required PostType postType,
    required List<Map<String, String>> galleryItems,
    required String title,
    required List<String> tags,
    required List<String> mentions,
    required bool allowComments,
    required VoidCallback postCompletionHandler,
    LocationModel? location,
    int? competitionId,
    int? clubId,
    int? eventId,
    int? fundRaisingCampaignId,
    bool isReel = false,
    int? audioId,
    double? audioStartTime,
    double? audioEndTime,
  }) {
    PostApi.addPost(
        postType: postType,
        postContentType:
            galleryItems.isEmpty ? PostContentType.text : PostContentType.media,
        title: title,
        gallery: galleryItems,
        allowComments: allowComments,
        hashTag: tags.join(','),
        mentions: mentions.join(','),
        location: location,
        competitionId: competitionId,
        clubId: clubId,
        audioId: audioId,
        audioStartTime: audioStartTime,
        audioEndTime: audioEndTime,
        resultCallback: (postId) async {
          if (postId != null) {
            Get.back();
            postCompletionHandler();
            AppUtil.showToast(message: postedString.tr, isSuccess: true);

            postingMedia = [];
            postingTitle = '';
            if (postId > 0) {
              await linkCollaboratorsToPost(postId);

              PostApi.getPostDetail(postId, resultCallback: (result) {
                if (result != null) {
                  _homeController.addNewPost(result);
                } else {
                  _homeController.getPosts(callback: () {}, isRecent: true);
                }
                postingStatus.value = PostingStatus.posted;

                Future.delayed(const Duration(seconds: 2), () {
                  postingStatus.value = PostingStatus.none;
                });
              });
            } else {
              _homeController.getPosts(callback: () {}, isRecent: true);
              postingStatus.value = PostingStatus.posted;

              Future.delayed(const Duration(seconds: 2), () {
                postingStatus.value = PostingStatus.none;
              });
            }

            clear();
          } else {
            isErrorInPosting.value = true;
            postingStatus.value = PostingStatus.none;
            AppUtil.showToast(
                message: 'Post publish failed. Please try again in a moment.',
                isSuccess: false);
          }
        });
  }

  void updatePost({
    required int postId,
    required String title,
    required bool allowComments,
  }) {
    HomeController homeController = Get.find();

    PostApi.updatePost(
        postId: postId,
        title: title,
        allowComments: allowComments,
        successHandler: () {
          PostApi.getPostDetail(postId, resultCallback: (post) {
            if (post != null) {
              homeController.postEdited(post);
            }
          });
          Get.back();
        });
  }

  void setTaggedLocation(LocationModel? location) {
    taggedLocation.value = location;
  }

  void shareToFeed(
      {required int productId, required PostContentType contentType}) {
    PostApi.addPost(
        postType: PostType.basic,
        postContentType: contentType,
        contentRefId: productId,
        title: '',
        gallery: [],
        allowComments: true,
        hashTag: '',
        mentions: '',
        location: null,
        competitionId: null,
        clubId: null,
        audioId: null,
        audioStartTime: null,
        audioEndTime: null,
        resultCallback: (postId) {
          if (postId != null) {
            HomeController homeController = Get.find();
            homeController.getPosts(callback: () {}, isRecent: true);
            AppUtil.showToast(message: postedString.tr, isSuccess: true);
          }
        });
  }

  //*************** add collaborate ***************//

  void addCollaborator(UserModel user) {
    if (collaborators.where((e) => e.id == user.id).isNotEmpty) {
      collaborators.removeWhere((e) => e.id == user.id);
    } else {
      if (collaborators.length == 5) {
        AppUtil.showToast(
            message: max5CollaboratorsInPostString.tr, isSuccess: false);
      } else {
        collaborators.add(user);
      }
    }
  }

  Future<void> linkCollaboratorsToPost(int postId) async {
    for (UserModel user in collaborators) {
      await PostApi.linkCollaborator(postId: postId, collaboratorId: user.id);
    }

    collaborators.clear();
  }

  void updateCollaborationStatus(
      {required int id, required CollaborationStatusType status}) {
    PostApi.updateCollaborationStatus(id: id, status: status);
  }
}
