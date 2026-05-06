import 'package:foap/helper/imports/common_import.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api_handler/apis/auth_api.dart';
import '../../screens/login_sign_up/verify_phone_login_otp.dart';
import '../../util/shared_prefs.dart';
import 'dart:async';
import 'package:foap/manager/socket_manager.dart';
import 'package:foap/util/form_validator.dart';
import 'package:foap/screens/dashboard/dashboard_screen.dart';
import 'package:foap/screens/login_sign_up/signup_profile_setup.dart';
import 'package:foap/screens/settings_menu/settings_controller.dart';
import 'package:foap/screens/login_sign_up/reset_password.dart';

bool isLoginFirstTime = false;

class LoginController extends GetxController {
  final SettingsController _settingsController = Get.find();
  final UserProfileManager _userProfileManager = Get.find();

  bool passwordReset = false;
  int userNameCheckStatus = -1;
  RxBool canResendOTP = true.obs;

  RxString passwordStrengthText = ''.obs;
  RxDouble passwordStrength = 0.toDouble().obs;
  RxString phoneCountryCode = '+1'.obs;

  int pinLength = 6;
  RxBool hasError = false.obs;
  RxBool otpFilled = false.obs;

  RegExp numReg = RegExp(r".*[0-9].*");
  RegExp letterReg = RegExp(r".*[A-Za-z].*");

  Future<void> _routeAfterAuthenticated({required bool isNewSignup}) async {
    final user = _userProfileManager.user.value;
    if (isNewSignup || (user?.requiresSignupProfileSetup ?? false)) {
      await SharedPrefs().setSignupProfileSetupPending(true);
      Get.offAll(() => const SignupProfileSetup());
      return;
    }

    Get.offAll(() => const DashboardScreen());
    getIt<SocketManager>().connect();
  }

  Future<void> _completeFirebaseOnlySession(User firebaseUser,
      {bool isNewSignup = false}) async {
    final localPart = (firebaseUser.email ?? '').split('@').first;
    final fallbackName = localPart.isNotEmpty ? localPart : 'user';
    final normalizedUserName = fallbackName.replaceAll(' ', '_');

    final user = UserModel();
    user.id = firebaseUser.uid.hashCode.abs();
    user.email = firebaseUser.email ?? '';
    user.name = firebaseUser.displayName ?? fallbackName;
    user.userName = (firebaseUser.displayName ?? normalizedUserName)
        .replaceAll(' ', '_')
        .toLowerCase();
    user.picture = firebaseUser.photoURL;
    _userProfileManager.user.value = user;

    await SharedPrefs().setAuthorizationKey('firebase_${firebaseUser.uid}');
    EasyLoading.dismiss();
    await _routeAfterAuthenticated(isNewSignup: isNewSignup);
  }

  Future<void> completeFirebaseLogin(User firebaseUser,
      {String? socialTypeOverride, bool isNewSignup = false}) async {
    if (AppConfigConstants.requireBackendSessionAfterFirebaseAuth) {
      try {
        final authKey = await AuthApi.loginWithFirebaseUser(
          firebaseUser: firebaseUser,
          socialTypeOverride: socialTypeOverride,
          showErrorToast: false,
        );

        if (authKey == null) {
          final backendReason = AuthApi.lastFirebaseBridgeError?.trim();
          if (AppConfigConstants.allowFirebaseLoginWithoutBackendSession) {
            AppUtil.showToast(
                message: backendReason != null && backendReason.isNotEmpty
                    ? 'Signed in with Firebase. Backend session failed: $backendReason'
                    : 'Signed in with Firebase. Backend is unavailable, so some features may not work yet.',
                isSuccess: true);
            await _completeFirebaseOnlySession(firebaseUser,
                isNewSignup: isNewSignup);
            return;
          }

          EasyLoading.dismiss();
          await FirebaseAuth.instance.signOut();
          return;
        }

        await SharedPrefs().setAuthorizationKey(authKey);
        await _userProfileManager.refreshProfile();
        await _settingsController.getSettings();

        if (_userProfileManager.user.value == null) {
          EasyLoading.dismiss();
          await FirebaseAuth.instance.signOut();
          showErrorMessage(
              'Unable to load profile after login. Please try again.');
          return;
        }

        await _routeAfterAuthenticated(isNewSignup: isNewSignup);
        EasyLoading.dismiss();
        return;
      } catch (e, st) {
        debugPrint('[Auth] Backend bridge failed after Firebase sign-in: $e');
        debugPrint(st.toString());
        final detailedError =
            (AuthApi.lastFirebaseBridgeError ?? e.toString()).trim();

        if (AppConfigConstants.allowFirebaseLoginWithoutBackendSession) {
          AppUtil.showToast(
              message: detailedError.isNotEmpty
                  ? 'Signed in with Firebase. Backend session failed: $detailedError'
                  : 'Signed in with Firebase. Backend session failed, so some features may be limited.',
              isSuccess: true);
          await _completeFirebaseOnlySession(firebaseUser,
              isNewSignup: isNewSignup);
          return;
        }

        EasyLoading.dismiss();
        await FirebaseAuth.instance.signOut();
        showErrorMessage(detailedError.isNotEmpty
            ? 'Login succeeded, but backend session failed: $detailedError'
            : 'Login succeeded, but backend session failed. Please try again later.');
      }
      return;
    }

    await _completeFirebaseOnlySession(firebaseUser, isNewSignup: isNewSignup);
  }

  void login(String email, String password) {
    if (FormValidator().isTextEmpty(email)) {
      showErrorMessage(
        pleaseEnterValidEmailString.tr,
      );
    } else if (FormValidator().isTextEmpty(password)) {
      showErrorMessage(
        pleaseEnterPasswordString.tr,
      );
    } else {
      if (AppConfigConstants.useFirebaseAuthForEmailPassword) {
        EasyLoading.show(status: loadingString.tr);
        FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password)
            .then((credential) async {
          EasyLoading.dismiss();
          final firebaseUser = credential.user;
          if (firebaseUser == null) {
            showErrorMessage(errorMessageString.tr);
            return;
          }
          await completeFirebaseLogin(firebaseUser,
              socialTypeOverride: AppConfigConstants.firebaseBackendSocialType);
        }).catchError((error) {
          EasyLoading.dismiss();
          if (error is FirebaseAuthException) {
            showErrorMessage(error.message ?? errorMessageString.tr);
          } else {
            showErrorMessage(errorMessageString.tr);
          }
        });
        return;
      }

      AuthApi.login(
          email: email,
          password: password,
          successCallback: (authKey) async {
            await SharedPrefs().setAuthorizationKey(authKey);
            await _userProfileManager.refreshProfile();
            await _settingsController.getSettings();
            getIt<SocketManager>().connect();

            Get.offAll(() => const DashboardScreen());
            getIt<SocketManager>().connect();
          },
          verifyOtpCallback: (token) {
            Get.to(() => VerifyRegistrationOTP(
                  token: token,
                ));
          });
      // AppUtil.checkInternet().then((value) {
      //   if (value) {
      //     ApiController().login(email, password).then((response) async {
      //       if (response.success) {
      //       } else {
      //         EasyLoading.dismiss();
      //         if (response.token != null) {
      //           Get.to(() => VerifyOTPScreen(
      //                 isVerifyingEmail: true,
      //                 isVerifyingPhone: false,
      //                 token: response.token!,
      //               ));
      //         } else {
      //           EasyLoading.dismiss();
      //           showErrorMessage(
      //             response.message,
      //           );
      //         }
      //       }
      //     });
      //   } else {
      //     showErrorMessage(
      //       noInternet,
      //     );
      //   }
      // });
    }
  }

  void phoneLogin({required String countryCode, required String phone}) {
    if (FormValidator().isTextEmpty(phone)) {
      showErrorMessage(pleaseEnterValidPhoneString.tr);
    } else {
      AuthApi.loginWithPhone(
          code: countryCode,
          phone: phone,
          successCallback: (token) {
            Get.to(() => VerifyRegistrationOTP(
                  token: token,
                ));
          });
    }
  }

  void checkPassword(String password) {
    password = password.trim();

    if (password.isEmpty) {
      passwordStrength.value = 0;
      passwordStrengthText.value = pleaseEnterYourPassword.tr;
    } else if (password.length < 6) {
      passwordStrength.value = 1 / 4;
      passwordStrengthText.value = passwordIsToShort.tr;
    } else if (password.length < 8) {
      passwordStrength.value = 2 / 4;
      passwordStrengthText.value = passwordIsShortButAcceptable.tr;
    } else {
      if (!letterReg.hasMatch(password) || !numReg.hasMatch(password)) {
        // Password length >= 8
        // But doesn't contain both letter and digit characters
        passwordStrength.value = 3 / 4;
        passwordStrengthText.value = passwordMustByAlphanumeric.tr;
      } else {
        // Password length >= 8
        // Password contains both letter and digit characters
        passwordStrength.value = 1;
        passwordStrengthText.value = passwordIsGreat.tr;
      }
    }

    update();
  }

  void register({
    required String email,
    required String name,
    required String password,
    required String confirmPassword,
  }) {
    final bool requireBackendUsernameCheck =
        !AppConfigConstants.useFirebaseAuthForEmailPassword;

    if (FormValidator().isTextEmpty(name) ||
        (requireBackendUsernameCheck && userNameCheckStatus != 1)) {
      showErrorMessage(
        pleaseEnterValidUserNameString.tr,
      );
    }
    if (name.contains(' ')) {
      showErrorMessage(
        userNameCanNotHaveSpaceString.tr,
      );
    } else if (FormValidator().isTextEmpty(email)) {
      showErrorMessage(
        pleaseEnterValidEmailString.tr,
      );
    } else if (FormValidator().isNotValidEmail(email)) {
      showErrorMessage(
        pleaseEnterValidEmailString.tr,
      );
    } else if (FormValidator().isTextEmpty(password)) {
      showErrorMessage(
        pleaseEnterPasswordString.tr,
      );
    } else if (FormValidator().isTextEmpty(confirmPassword)) {
      showErrorMessage(
        pleaseEnterConfirmPasswordString.tr,
      );
    } else if (password != confirmPassword) {
      showErrorMessage(
        passwordsDoesNotMatchedString.tr,
      );
    } else {
      if (AppConfigConstants.useFirebaseAuthForEmailPassword) {
        EasyLoading.show(status: loadingString.tr);
        FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password)
            .then((credential) async {
          final firebaseUser = credential.user;
          if (firebaseUser == null) {
            EasyLoading.dismiss();
            showErrorMessage(errorMessageString.tr);
            return;
          }
          await firebaseUser.updateDisplayName(name.trim());
          await firebaseUser.reload();
          final reloadedUser =
              FirebaseAuth.instance.currentUser ?? firebaseUser;
          EasyLoading.dismiss();
          await completeFirebaseLogin(reloadedUser,
              socialTypeOverride: AppConfigConstants.firebaseBackendSocialType,
              isNewSignup: true);
        }).catchError((error) {
          EasyLoading.dismiss();
          if (error is FirebaseAuthException) {
            showErrorMessage(error.message ?? errorMessageString.tr);
          } else {
            showErrorMessage(errorMessageString.tr);
          }
        });
        return;
      }

      AuthApi.register(
          email: email,
          name: name,
          password: password,
          successCallback: (token) {
            Get.to(() => VerifyRegistrationOTP(
                  // isVerifyingEmail: true,
                  // isVerifyingPhone: false,
                  token: token,
                  isFromSignup: true,
                ));
          });
    }
  }

  void resetPassword({
    required String newPassword,
    required String confirmPassword,
    required String token,
  }) {
    if (FormValidator().isTextEmpty(newPassword)) {
      showErrorMessage(
        pleaseEnterPasswordString.tr,
      );
    } else if (FormValidator().isTextEmpty(confirmPassword)) {
      showErrorMessage(
        pleaseEnterConfirmPasswordString.tr,
      );
    } else if (newPassword != confirmPassword) {
      showErrorMessage(
        passwordsDoesNotMatchedString.tr,
      );
    } else {
      AuthApi.resetPassword(
          token: token,
          newPassword: newPassword,
          successCallback: () {
            passwordReset = true;
            update();
          });
    }
  }

  void verifyUsername(String userName) {
    if (AppConfigConstants.useFirebaseAuthForEmailPassword) {
      if (userName.contains(' ') || userName.trim().length < 3) {
        userNameCheckStatus = 0;
      } else {
        userNameCheckStatus = 1;
      }
      update();
      return;
    }

    if (userName.contains(' ')) {
      userNameCheckStatus = 0;
      update();
      return;
    }

    AuthApi.checkUsername(
        username: userName,
        successCallback: () {
          userNameCheckStatus = 1;
          update();
        },
        failureCallback: () {
          userNameCheckStatus = 0;
          update();
        });
  }

  void phoneCodeSelected(String code) {
    phoneCountryCode.value = code;
  }

  void otpTextFilled(String otp) {
    otpFilled.value = otp.length == pinLength;
    hasError.value = false;

    update();
  }

  void otpCompleted() {
    otpFilled.value = true;
    hasError.value = false;

    update();
  }

  void resendOTP({required String token}) {
    EasyLoading.show(status: loadingString.tr);
    AuthApi.resendOTP(
        token: token,
        successCallback: () {
          EasyLoading.dismiss();
          canResendOTP.value = false;
          update();
        });
  }

  void callVerifyOTP({
    required bool isVerifyingEmail,
    required bool isVerifyingPhone,
    required String otp,
    required String token,
  }) {
    EasyLoading.show(status: loadingString.tr);

    if (isVerifyingEmail == true || isVerifyingPhone == true) {
      AuthApi.verifyRegistrationOTP(
          otp: otp,
          token: token,
          successCallback: (authKey) {
            EasyLoading.dismiss();

            Future.delayed(const Duration(milliseconds: 500), () async {
              await SharedPrefs().setAuthorizationKey(authKey);
              await _userProfileManager.refreshProfile();
              await _settingsController.getSettings();
              if (_userProfileManager.user.value != null) {
                // ask for location
                // AppUtil.showToast(
                //     message: registeredSuccessFully,
                //     isSuccess: true);
                await SharedPrefs().setSignupProfileSetupPending(true);
                Get.offAll(() => const SignupProfileSetup());
              }
            });
          });
    } else {
      AuthApi.verifyForgotPasswordOTP(
          otp: otp,
          token: token,
          successCallback: (token) {
            EasyLoading.dismiss();

            Future.delayed(const Duration(milliseconds: 500), () async {
              Get.to(() => ResetPasswordScreen(token: token));
            });
          });
    }
  }

  void callVerifyOTPForPhoneLogin({
    required String otp,
    required String token,
  }) {
    EasyLoading.show(status: loadingString.tr);

    AuthApi.verifyRegistrationOTP(
        otp: otp,
        token: token,
        successCallback: (authKey) {
          EasyLoading.dismiss();
          Future.delayed(const Duration(milliseconds: 500), () async {
            await SharedPrefs().setAuthorizationKey(authKey);
            await _userProfileManager.refreshProfile();
            await _settingsController.getSettings();

            if (_userProfileManager.user.value != null) {
              Get.to(() => const DashboardScreen());
            }
          });
        });
  }

  void callVerifyOTPForChangePhone({
    required String otp,
    required String token,
  }) {
    AuthApi.verifyChangePhoneOTP(
        otp: otp,
        token: token,
        successCallback: () {
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.back();
          });
        });
  }

  void forgotPassword({required String email}) {
    if (FormValidator().isTextEmpty(email)) {
      AppUtil.showToast(message: pleaseEnterEmailString.tr, isSuccess: false);
    } else if (FormValidator().isNotValidEmail(email)) {
      AppUtil.showToast(
          message: pleaseEnterValidEmailString.tr, isSuccess: false);
    } else {
      if (AppConfigConstants.useFirebaseAuthForEmailPassword) {
        EasyLoading.show(status: loadingString.tr);
        FirebaseAuth.instance.sendPasswordResetEmail(email: email).then((_) {
          EasyLoading.dismiss();
          showSuccessMessage('Password reset email sent');
        }).catchError((error) {
          EasyLoading.dismiss();
          if (error is FirebaseAuthException) {
            showErrorMessage(error.message ?? errorMessageString.tr);
          } else {
            showErrorMessage(errorMessageString.tr);
          }
        });
        return;
      }

      AuthApi.forgotPassword(
          email: email,
          successCallback: (token) {
            Get.to(() => VerifyRegistrationOTP(
                  // isVerifyingEmail: false,
                  // isVerifyingPhone: false,
                  token: token,
                ));
          });
    }
  }

  Future<void> launchUrlInBrowser(String url) async {
    await launchUrl(Uri.parse(url));
  }

  void showSuccessMessage(String message) {
    AppUtil.showToast(message: message, isSuccess: true);
  }

  void showErrorMessage(String message) {
    AppUtil.showToast(message: message, isSuccess: false);
  }
}
