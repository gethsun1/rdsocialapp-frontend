import 'dart:async';
import 'package:foap/api_handler/apis/auth_api.dart';
import 'package:foap/api_handler/apis/profile_api.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/manager/db_manager.dart';
import 'package:foap/manager/socket_manager.dart';
import 'package:foap/screens/dashboard/dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/login_sign_up/auth_tab.dart';
import '../util/shared_prefs.dart';

class UserProfileManager extends GetxController {
  final DashboardController _dashboardController = Get.find();

  Rx<UserModel?> user = Rx<UserModel?>(null);

  bool get isLogin {
    return user.value != null;
  }

  Future<void> logout() async {
    user.value = null;

    if (AppConfigConstants.useFirebaseAuthForEmailPassword) {
      await FirebaseAuth.instance.signOut();
    } else {
      await AuthApi.logout();
    }

    SharedPrefs().clearPreferences();
    Get.offAll(() => const AuthTab());
    getIt<SocketManager>().disconnect();
    getIt<DBManager>().clearAllUnreadCount();
    getIt<DBManager>().deleteAllChatHistory();

    try {
      GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
    } catch (_) {
      // Ignore disconnect errors for environments where GoogleSignIn channel
      // is unavailable; Firebase signOut above has already cleared auth state.
    }
    Future.delayed(const Duration(seconds: 2), () {
      _dashboardController.indexChanged(0);
    });
    SharedPrefs().setBioMetricAuthStatus(false);
  }

  Future refreshProfile() async {
    if (AppConfigConstants.useFirebaseAuthForEmailPassword) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        user.value = _buildUserFromFirebase(firebaseUser);
      }
      return;
    }

    String? authKey = await SharedPrefs().getAuthorizationKey();

    if (authKey != null) {
      await ProfileApi.getMyProfile(resultCallback: (result) {
        user.value = result;

        print('user.value ${user.value!.isShareOnlineStatus}');
        if (user.value != null) {
          setupSocketServiceLocator1();
        }
        return;
      });
    } else {
      return;
      // print('no auth token found');
    }
  }

  UserModel _buildUserFromFirebase(User firebaseUser) {
    final localPart = (firebaseUser.email ?? '').split('@').first;
    final fallbackName = localPart.isNotEmpty ? localPart : 'user';
    final normalizedUserName = fallbackName.replaceAll(' ', '_');

    final model = UserModel();
    model.id = firebaseUser.uid.hashCode.abs();
    model.email = firebaseUser.email ?? '';
    model.name = firebaseUser.displayName ?? fallbackName;
    model.userName = (firebaseUser.displayName ?? normalizedUserName)
        .replaceAll(' ', '_')
        .toLowerCase();
    model.picture = firebaseUser.photoURL;
    return model;
  }
}
