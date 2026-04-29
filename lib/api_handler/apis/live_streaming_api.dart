import '../../helper/imports/common_import.dart';
import '../../model/api_meta_data.dart';
import '../../model/live_model.dart';
import '../api_wrapper.dart';

class LiveStreamingApi {
  static Future<void> getAllLiveUsers(
      {required int page,
        String? name,
        String? profileCategoryType,
        bool? isFollowing,
        required Function(List<UserLiveCallDetail>, APIMetaData)
        resultCallback}) async {
    var url =
        '${NetworkConstantsUtil.liveUsers}?expand=userdetails&name=&profile_category_type=&is_following=&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final liverStreamUser = result!.data['liveStreamUser']['items'];
        resultCallback(
            List<UserLiveCallDetail>.from(liverStreamUser.map((user) {
              final item = UserLiveCallDetail.fromJson(user);
              return item;
            })), APIMetaData.fromJson(result.data['liveStreamUser']['_meta']));
      }
    });
  }

  static Future<void> getLiveDetail(
      {required String channelName,
        required Function(LiveModel) resultCallback}) async {
    var url = '${NetworkConstantsUtil.liveDetailByChannel}$channelName';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var live = result!.data['live_history'];
        resultCallback(LiveModel.fromJson(live));
      }
    });
  }

  static Future<void> getCurrentLiveUsers(
      {required Function(List<UserModel>) resultCallback}) async {
    UserProfileManager userProfileManager = Get.find();
    var url =
        '${NetworkConstantsUtil.currentLiveUsers}${userProfileManager.user.value!.id}';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = (result!.data['following'] as List<dynamic>)
            .map((e) => e['followingUserDetail'])
            .toList();
        if (items.isNotEmpty) {
          resultCallback(
              List<UserModel>.from(items.map((x) => UserModel.fromJson(x))));
        }
      }
    });
  }

  static Future<void> getLiveHistory(
      {required int page,
        required Function(List<LiveModel>, APIMetaData) resultCallback}) async {
    var url = '${NetworkConstantsUtil.liveHistory}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = result!.data['live_history']['items'];
        resultCallback(
            List<LiveModel>.from(items.map((x) => LiveModel.fromJson(x))),
            APIMetaData.fromJson(result.data['live_history']['_meta']));
      }
    });
  }

  static Future<void> getLiveViewers(
      {required int liveId,
        int? role,
        bool? isBanned,
        required Function(List<LiveViewer>, APIMetaData) resultCallback}) async {
    var url = '${NetworkConstantsUtil.liveCallViewers}$liveId';

    if (role != null) {
      url = '$url&role=$role';
    }
    if (isBanned != null) {
      url = '$url&is_ban=1';
    }
    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = result!.data['live_user_view']['items'];
        if (items.isNotEmpty) {
          resultCallback(
              List<LiveViewer>.from(items.map((x) => LiveViewer.fromJson(x))),
              APIMetaData.fromJson(result.data['live_user_view']['_meta']));
        }
      }
    });
  }
}
