import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/helper/list_extension.dart';
import 'package:foap/model/data_wrapper.dart';

import '../../api_handler/apis/post_api.dart';
import '../../model/post_model.dart';

class ArchivedPostController extends GetxController {
  RxList<PostModel> posts = <PostModel>[].obs;
  DataWrapper postDataWrapper = DataWrapper();

  void clear() {
    postDataWrapper = DataWrapper();
    posts.value = [];
    update();
  }

  @override
  void onInit() {
    super.onInit();
    refreshData(() {});
  }

  void refreshData(VoidCallback callback) {
    clear();
    getPosts(callback);
  }

  void loadMore(VoidCallback callback) {
    if (postDataWrapper.haveMoreData.value == true) {
      getPosts(callback);
    } else {
      callback();
    }
  }

  void getPosts(VoidCallback callback) async {
    postDataWrapper.isLoading.value = true;
    PostApi.getPosts(
        isMine: 1,
        isArchived: 1,
        page: postDataWrapper.page,
        resultCallback: (result, metadata) {
          for (final post in result) {
            post.isArchived = true;
          }
          posts.addAll(result);
          posts.sort((a, b) => b.createDate!.compareTo(a.createDate!));
          posts.unique((e) => e.id);
          postDataWrapper.processCompletedWithData(metadata);

          callback();
          update();
        });
  }
}
