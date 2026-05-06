import 'package:foap/api_handler/api_wrapper.dart';
import '../../helper/imports/common_import.dart';
import '../../model/api_meta_data.dart';
import '../../model/search_model.dart';

class UsersApi {
  static Future<void> getSuggestedUsers(
      {required int page,
      required Function(List<UserModel>) resultCallback}) async {
    var url = '${NetworkConstantsUtil.getSuggestedUsers}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var topUsers = result!.data['topUser'];

        resultCallback(
          List<UserModel>.from(topUsers.map((x) => UserModel.fromJson(x))),
        );
      }
    });
  }

  static Future<void> searchUsers(
      {required UserSearchModel searchModel,
      required int page,
      required Function(List<UserModel>, APIMetaData) resultCallback}) async {
    var url = NetworkConstantsUtil.findFriends;
    //searchFrom  ----- 1=username,2=email,3=phone
    String searchFromValue = searchModel.searchFrom == null
        ? ''
        : searchModel.searchFrom == SearchFrom.username
            ? '1'
            : searchModel.searchFrom == SearchFrom.email
                ? '2'
                : '3';
    url =
        '${url}searchText=${searchModel.searchText ?? ''}&searchFrom=$searchFromValue&isExactMatch=${searchModel.isExactMatch ?? ''}&is_chat_user_online=${searchModel.isOnline == 1 ? '1' : ''}&page=$page';
    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var topUsers = result!.data['user']['items'];
        resultCallback(
            List<UserModel>.from(topUsers.map((x) => UserModel.fromJson(x))),
            APIMetaData.fromJson(result.data['user']['_meta']));
      }
    });
  }

  static Future<void> getOtherUser(
      {required int userId,
      required Function(UserModel) resultCallback}) async {
    var url = NetworkConstantsUtil.otherUser;
    url = url.replaceFirst('{{id}}', userId.toString());

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        resultCallback(UserModel.fromJson(result!.data['user']));
        return;
      }
    });
  }

  static Future<void> otherUserProfileView(
      {required int refId, required int sourceType}) async {
    var url = NetworkConstantsUtil.userView;

    await ApiWrapper().postApi(url: url, param: {
      'reference_id': refId.toString(),
      'source_type': sourceType.toString()
    });
  }

  static Future<void> followUnfollowUser(
      {required bool isFollowing, required UserModel user}) async {
    var url = (isFollowing
        ? user.isPrivate
            ? NetworkConstantsUtil.followRequest
            : NetworkConstantsUtil.followUser
        : NetworkConstantsUtil.unfollowUser);

    await ApiWrapper().postApi(url: url, param: {
      "user_id": user.id.toString(),
    }).then((result) {
      if (result?.success == true) {
        return;
      }
    });
  }

  static Future<void> followMultipleUsers({required String userIds}) async {
    var url = NetworkConstantsUtil.followMultipleUser;

    await ApiWrapper().postApi(url: url, param: {
      "user_ids": userIds,
    }).then((result) {
      if (result?.success == true) {
        return;
      }
    });
  }

  static Future<void> reportUser(
      {required int userId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.reportUser;
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper().postApi(
        url: url,
        param: {"report_to_user_id": userId.toString()}).then((result) {
      EasyLoading.dismiss();

      if (result?.success == true) {
        resultCallback();
        return;
      }
    });
  }

  static Future<bool> blockUser(
      {required int userId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.blockUser;
    EasyLoading.show(status: loadingString.tr);

    try {
      final result = await ApiWrapper()
          .postApi(url: url, param: {"blocked_user_id": userId.toString()});

      EasyLoading.dismiss();

      if (result?.success == true) {
        AppUtil.showToast(
            message: 'User is blocked successfully'.tr, isSuccess: true);
        resultCallback();
        return true;
      }

      AppUtil.showToast(
          message: result?.message ?? 'Something went wrong'.tr,
          isSuccess: false);
      return false;
    } catch (error) {
      EasyLoading.dismiss();
      AppUtil.showToast(message: error.toString(), isSuccess: false);
      return false;
    }
  }

  static Future<bool> unBlockUser(
      {required int userId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.unBlockUser;
    EasyLoading.show(status: loadingString.tr);

    try {
      final result = await ApiWrapper()
          .postApi(url: url, param: {"blocked_user_id": userId.toString()});

      EasyLoading.dismiss();

      if (result?.success == true) {
        resultCallback();
        return true;
      }

      AppUtil.showToast(
          message: result?.message ?? 'Something went wrong'.tr,
          isSuccess: false);
      return false;
    } catch (error) {
      EasyLoading.dismiss();
      AppUtil.showToast(message: error.toString(), isSuccess: false);
      return false;
    }
  }

  static Future<bool> getBlockedUsers(
      {required int page,
      required Function(List<UserModel>, APIMetaData) resultCallback}) async {
    var url = '${NetworkConstantsUtil.blockedUsers}&page=$page';

    EasyLoading.show(status: loadingString.tr);
    try {
      final result = await ApiWrapper().getApi(url: url);
      EasyLoading.dismiss();

      if (result?.success == true) {
        final blockedUserNode = result!.data['blockedUser'];
        final blockedUserItems =
            blockedUserNode is Map ? blockedUserNode['items'] : null;

        final items = blockedUserItems is List
            ? blockedUserItems
                .where((element) =>
                    element is Map && element['blockedUserDetail'] != null)
                .map((e) => e['blockedUserDetail'])
                .toList()
            : [];

        final meta = blockedUserNode is Map && blockedUserNode['_meta'] is Map
            ? APIMetaData.fromJson(
                Map<String, dynamic>.from(blockedUserNode['_meta']))
            : APIMetaData(
                totalCount: items.length,
                pageCount: page,
                currentPage: page,
                perPage: 20,
              );

        resultCallback(
            List<UserModel>.from(items.map((x) => UserModel.fromJson(x))),
            meta);
        return true;
      }

      AppUtil.showToast(
          message: result?.message ?? 'Something went wrong'.tr,
          isSuccess: false);
      return false;
    } catch (error) {
      EasyLoading.dismiss();
      AppUtil.showToast(message: error.toString(), isSuccess: false);
      return false;
    }
  }

  static Future<void> getFollowerUsers(
      {required int? userId,
      int page = 1,
      required Function(List<UserModel>, APIMetaData) resultCallback}) async {
    final UserProfileManager userProfileManager = Get.find();

    var url =
        '${NetworkConstantsUtil.followers}${userId ?? userProfileManager.user.value!.id}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = (result!.data['follower']['items'] as List<dynamic>)
            .map((e) => e['followerUserDetail'])
            .toList();
        resultCallback(
            List<UserModel>.from(items.map((x) => UserModel.fromJson(x))),
            APIMetaData.fromJson(result.data['follower']['_meta']));
      }
    });
  }

  static Future<void> getFollowingUsers(
      {int? userId,
      int page = 1,
      required Function(List<UserModel>, APIMetaData) resultCallback}) async {
    final UserProfileManager userProfileManager = Get.find();

    var url =
        '${NetworkConstantsUtil.following}${userId ?? userProfileManager.user.value!.id}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = (result!.data['following']['items'] as List<dynamic>)
            .map((e) => e['followingUserDetail'])
            .toList();
        resultCallback(
            List<UserModel>.from(items.map((x) => UserModel.fromJson(x))),
            APIMetaData.fromJson(result.data['following']['_meta']));
      }
    });
  }
}
