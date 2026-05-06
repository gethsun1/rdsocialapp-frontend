import 'package:foap/helper/imports/common_import.dart';
import '../../api_handler/apis/users_api.dart';
import 'package:foap/helper/list_extension.dart';

class BlockedUsersController extends GetxController {
  RxList<UserModel> usersList = <UserModel>[].obs;
  bool isLoading = false;

  int blockedUserPage = 1;
  bool canLoadMoreBlockedUser = true;

  void clear() {
    usersList.value = [];
    isLoading = false;
    blockedUserPage = 1;
    canLoadMoreBlockedUser = true;
  }

  void getBlockedUsers() async {
    if (canLoadMoreBlockedUser) {
      isLoading = true;
      update();

      final success = await UsersApi.getBlockedUsers(
          page: blockedUserPage,
          resultCallback: (result, metadata) {
            usersList.addAll(result);
            usersList.unique((e) => e.id);

            blockedUserPage += 1;
            canLoadMoreBlockedUser = result.length >= metadata.perPage;
          });

      isLoading = false;
      if (success) {
        usersList.refresh();
      }
      update();
    }
  }

  void unBlockUser(int userId) async {
    isLoading = true;
    update();

    final success = await UsersApi.unBlockUser(
        userId: userId,
        resultCallback: () {
          usersList.removeWhere((element) => element.id == userId);
        });

    isLoading = false;
    if (success) {
      usersList.refresh();
    }
    update();
  }
}
