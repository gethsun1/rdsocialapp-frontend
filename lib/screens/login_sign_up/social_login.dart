import 'dart:io';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:foap/api_handler/apis/auth_api.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/screens/login_sign_up/phone_login.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:foap/helper/imports/login_signup_imports.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../manager/location_manager.dart';
import '../../manager/socket_manager.dart';
import '../../util/shared_prefs.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings_menu/settings_controller.dart';

/// Returns the sha256 hash of [input] in hex notation.
String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class SocialLogin extends StatefulWidget {
  final bool hidePhoneLogin;

  const SocialLogin({super.key, required this.hidePhoneLogin});

  @override
  State<SocialLogin> createState() => _SocialLoginState();
}

class _SocialLoginState extends State<SocialLogin> {
  final SettingsController _settingsController = Get.find();
  final UserProfileManager _userProfileManager = Get.find();
  final LoginController _loginController = Get.find();

  @override
  Widget build(BuildContext context) {
    final showPhoneLoginOption =
        !AppConfigConstants.useFirebaseOnlyMode && !widget.hidePhoneLogin;
    final showLegacySocialButtons = !AppConfigConstants.useFirebaseOnlyMode;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        showPhoneLoginOption
            ? Container(
                height: 40,
                width: 40,
                color: AppColorConstants.themeColor.withValues(alpha: 0.2),
                child: Center(
                    child: Image.asset(
                  'assets/phone.png',
                  height: 20,
                  width: 20,
                  color: Colors.white,
                ))).round(10).ripple(() {
                Get.offAll(() => const PhoneLoginScreen());
              })
            : Container(
                height: 40,
                width: 40,
                color: AppColorConstants.themeColor.withValues(alpha: 0.2),
                child: Center(
                    child: Image.asset(
                  'assets/email.png',
                  height: 20,
                  width: 20,
                  color: Colors.white,
                ))).round(10).ripple(() {
                Get.offAll(() => const LoginScreen());
              }),
        Container(
            height: 40,
            width: 40,
            color: AppColorConstants.themeColor.withValues(alpha: 0.2),
            child: Center(
                child: Image.asset(
              'assets/google.png',
              height: 20,
              width: 20,
            ))).round(10).ripple(() {
          signInWithGoogle();
        }),
        if (Platform.isIOS && showLegacySocialButtons)
          Container(
              height: 40,
              width: 40,
              color: AppColorConstants.themeColor.withValues(alpha: 0.2),
              child: Center(
                  child: Image.asset(
                'assets/apple.png',
                height: 20,
                width: 20,
                color: Colors.white,
              ))).round(10).ripple(() {
            //signInWithGoogle();
            _handleAppleSignIn();
            // Get.to(() => const InstagramView());
          }),
        if (showLegacySocialButtons)
          Container(
              height: 40,
              width: 40,
              color: AppColorConstants.themeColor.withValues(alpha: 0.2),
              child: Center(
                  child: Image.asset(
                'assets/facebook.png',
                height: 20,
                width: 20,
              ))).round(10).ripple(() {
            fbSignInAction();
          }),
      ],
    );
  }

  String _mapGoogleSignInError(Object error) {
    if (error is PlatformException) {
      final lowered = '${error.code} ${error.message} ${error.details}'
          .toLowerCase()
          .trim();

      if (lowered.contains('10') ||
          lowered.contains('developer_error') ||
          lowered.contains('12500')) {
        return 'Google Sign-In config mismatch (SHA/OAuth). Verify SHA fingerprints and web client id in Firebase.';
      }
      if (lowered.contains('12501') || lowered.contains('canceled')) {
        return cancelledByUserString.tr;
      }
      if (lowered.contains('network') || lowered.contains('7')) {
        return noInternetString.tr;
      }
      return error.message ?? errorMessageString.tr;
    }

    if (error is FirebaseAuthException) {
      return error.message ?? errorMessageString.tr;
    }

    final lowered = error.toString().toLowerCase();
    if (lowered.contains('canceled') || lowered.contains('cancelled')) {
      return cancelledByUserString.tr;
    }
    if (lowered.contains('network')) {
      return noInternetString.tr;
    }
    if (lowered.contains('failed host lookup') ||
        lowered.contains('could not resolve host') ||
        lowered.contains('no address associated with hostname')) {
      return 'Google sign-in succeeded, but backend host is unreachable.';
    }
    if (lowered.contains('10')) {
      return 'Google Sign-In is blocked by SHA mismatch. Add this APK signing SHA-1/SHA-256 in Firebase and download a fresh google-services.json.';
    }

    return errorMessageString.tr;
  }

  Future<void> signInWithGoogle() async {
    try {
      if (!AppConfigConstants.useFirebaseAuthForGoogleSignIn) {
        AppUtil.showToast(message: errorMessageString.tr, isSuccess: false);
        return;
      }

      EasyLoading.show(status: loadingString.tr);
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: const <String>['email'],
        serverClientId: AppConfigConstants.firebaseWebClientId,
      );

      // Force account chooser instead of silently reusing a previously-selected account.
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        EasyLoading.dismiss();
        AppUtil.showToast(message: cancelledByUserString.tr, isSuccess: false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        EasyLoading.dismiss();
        AppUtil.showToast(message: errorMessageString.tr, isSuccess: false);
        return;
      }

      await _loginController.completeFirebaseLogin(
        firebaseUser,
        socialTypeOverride: AppConfigConstants.firebaseBackendSocialType,
      );
    } catch (error, stackTrace) {
      EasyLoading.dismiss();
      debugPrint('Google sign-in error: $error');
      debugPrint(stackTrace.toString());
      AppUtil.showToast(
          message: _mapGoogleSignInError(error), isSuccess: false);
    }
  }

  void fbSignInAction() async {
    FocusScope.of(context).requestFocus(FocusNode());
    final facebookLogin = FacebookLogin();
    facebookLogin.logOut();
    final result = await facebookLogin.logIn(permissions: [
      FacebookPermission.publicProfile,
      FacebookPermission.email,
    ]);

    switch (result.status) {
      case FacebookLoginStatus.success:
        // Get profile data
        final profile = await facebookLogin.getUserProfile();
        String name = profile?.name ?? '';
        String socialId = profile?.userId ?? '';
        final email = await facebookLogin.getUserEmail();

        AppUtil.checkInternet().then((value) {
          if (value) {
            socialLogin('fb', socialId, name, email!);
          } else {
            AppUtil.showToast(message: noInternetString.tr, isSuccess: false);
          }
        });

        break;
      case FacebookLoginStatus.cancel:
        AppUtil.showToast(message: cancelledByUserString.tr, isSuccess: false);
        break;
      case FacebookLoginStatus.error:
        AppUtil.showToast(
            message: result.error!.localizedDescription!, isSuccess: false);
        break;
    }
  }

  void socialLogin(String type, String userId, String name, String email) {
    if (AppConfigConstants.useFirebaseOnlyMode) {
      showErrorMessage(
          'This sign-in method is disabled in Firebase-only mode.');
      return;
    }

    EasyLoading.show(status: loadingString.tr);

    AuthApi.socialLogin(
        name: name,
        socialType: type,
        socialId: userId,
        email: email,
        successCallback: (authKey, isNewUser) async {
          EasyLoading.dismiss();
          await SharedPrefs().setAuthorizationKey(authKey);
          await _userProfileManager.refreshProfile();
          await _settingsController.getSettings();

          if (_userProfileManager.user.value != null) {
            // ask for location
            if (isNewUser) {
              await SharedPrefs().setSignupProfileSetupPending(true);
              Get.offAll(() => const SignupProfileSetup());
            } else {
              isLoginFirstTime = false;
              getIt<LocationManager>().postLocation();
              Get.offAll(() => const DashboardScreen());
              getIt<SocketManager>().connect();
            }
          }
        });
  }

  Future<void> _handleAppleSignIn() async {
    if (AppConfigConstants.useFirebaseOnlyMode) {
      showErrorMessage(
          'This sign-in method is disabled in Firebase-only mode.');
      return;
    }

    EasyLoading.show(status: 'loading...');

    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    if (appleCredential.givenName != null) {
      SharedPrefs().setAppleIdName(
          forAppleId: '${appleCredential.userIdentifier}',
          email: appleCredential.givenName!);
    }
    if (appleCredential.email != null) {
      SharedPrefs().setAppleIdEmail(
          forAppleId: '${appleCredential.userIdentifier}',
          email: appleCredential.email!);
    }

    String? email = await SharedPrefs()
        .getAppleIdEmail(forAppleId: '${appleCredential.userIdentifier}');
    String? name = await SharedPrefs()
        .getAppleIdName(forAppleId: '${appleCredential.userIdentifier}');

    if (appleCredential.userIdentifier != null) {
      socialLogin('apple', appleCredential.userIdentifier!, name!, email!);
    }
  }

  void showErrorMessage(String message) {
    AppUtil.showToast(message: message, isSuccess: false);
  }
}
