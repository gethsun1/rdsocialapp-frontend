import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foap/helper/device_info.dart';
import 'package:foap/util/app_config_constants.dart';
import 'package:get/get.dart';
import '../../helper/localization_strings.dart';
import '../../util/app_util.dart';
import '../../util/shared_prefs.dart';
import '../api_wrapper.dart';

class AuthApi {
  static Future<void> login(
      {required String email,
      required String password,
      required Function(String) successCallback,
        required Function(String) verifyOtpCallback}) async {
    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();
    dynamic param = {
      "email": email,
      "password": password,
      "device_type": DeviceInfoManager.info.deviceType,
      "device_token": fcmToken ?? '',
      "device_token_voip_ios": voipToken ?? '',
      'device_model': DeviceInfoManager.info.model,
      'device_os_version': DeviceInfoManager.info.osVersion,
      'device_app_release_version': AppConfigConstants.currentVersion,
      'login_ip': DeviceInfoManager.info.ip,
      'login_location': '',
    };
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(url: NetworkConstantsUtil.login, param: param)
        .then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        String authKey = response!.data!['auth_key'];
        successCallback(authKey);
      } else {
        if (response?.data != null) {
          if (response!.data['token'] != null) {
            String authKey = response.data!['token'];
            verifyOtpCallback(authKey);
          }
        }
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> logout() async {
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApi(url: NetworkConstantsUtil.logout, param: {}).then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> loginWithPhone(
      {required String code,
      required String phone,
      required Function(String) successCallback}) async {

    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();

    dynamic param = {
      "country_code": code,
      "phone": phone,
      "device_type": DeviceInfoManager.info.deviceType,
      "device_token": fcmToken ?? '',
      "device_token_voip_ios": voipToken ?? '',
      'device_model': DeviceInfoManager.info.model,
      'device_os_version': DeviceInfoManager.info.osVersion,
      'device_app_release_version': AppConfigConstants.currentVersion,
      'login_ip': DeviceInfoManager.info.ip,
      'login_location': '',
    };
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(
            url: NetworkConstantsUtil.loginWithPhone, param: param)
        .then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        String token = response!.data!['verify_token'];

        successCallback(token);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> socialLogin(
      {required String name,
      required String socialType,
      required String socialId,
      required String email,
      required Function(String) successCallback}) async {
    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(url: NetworkConstantsUtil.socialLogin, param: {
      "name": name,
      "username": "",
      "social_type": socialType,
      "social_id": socialId,
      "email": email,
      "device_type": DeviceInfoManager.info.deviceType,
      "device_token": fcmToken ?? '',
      "device_token_voip_ios": voipToken ?? '',
      'device_model': DeviceInfoManager.info.model,
      'device_os_version': DeviceInfoManager.info.osVersion,
      'device_app_release_version': AppConfigConstants.currentVersion,
      'login_ip': DeviceInfoManager.info.ip,
      'login_location': '',
    }).then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        String authKey = response!.data!['auth_key'];

        successCallback(authKey);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<String?> loginWithFirebaseUser(
      {required User firebaseUser,
      String? socialTypeOverride,
      bool showErrorToast = true}) async {
    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();

    final socialType = socialTypeOverride ??
        AppConfigConstants.firebaseBackendSocialType;
    final localPart = (firebaseUser.email ?? '').split('@').first;
    final fallbackName = localPart.isNotEmpty ? localPart : 'user';
    final name = (firebaseUser.displayName ?? fallbackName).trim();
    final email = (firebaseUser.email ?? '').trim();

    if (email.isEmpty) {
      if (showErrorToast) {
        AppUtil.showToast(
            message:
                'Signed in with Firebase, but no email is available to create backend session.',
            isSuccess: false);
      }
      return null;
    }

    final response = await ApiWrapper().postApiWithoutToken(
        url: NetworkConstantsUtil.socialLogin,
        param: {
          "name": name,
          "username": "",
          "social_type": socialType,
          "social_id": firebaseUser.uid,
          "email": email,
          "device_type": DeviceInfoManager.info.deviceType,
          "device_token": fcmToken ?? '',
          "device_token_voip_ios": voipToken ?? '',
          'device_model': DeviceInfoManager.info.model,
          'device_os_version': DeviceInfoManager.info.osVersion,
          'device_app_release_version': AppConfigConstants.currentVersion,
          'login_ip': DeviceInfoManager.info.ip,
          'login_location': '',
        });

    if (response?.success == true) {
      return response!.data?['auth_key'];
    }

    if (showErrorToast) {
      AppUtil.showToast(
          message: response?.message ??
              'Backend session creation failed after Firebase sign-in.',
          isSuccess: false);
    }
    return null;
  }

  static Future<void> register(
      {required String email,
      required String name,
      required String password,
      required Function(String) successCallback}) async {
    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();
    EasyLoading.show(status: loadingString.tr);
    await ApiWrapper()
        .postApiWithoutToken(url: NetworkConstantsUtil.register, param: {
      "username": name,
      "name": name,
      "email": email,
      "password": password,
      "role":'3',
      "device_type": DeviceInfoManager.info.deviceType,
      "device_token": fcmToken ?? '',
      "device_token_voip_ios": voipToken ?? '',
      'device_model': DeviceInfoManager.info.model,
      'device_os_version': DeviceInfoManager.info.osVersion,
      'device_app_release_version': AppConfigConstants.currentVersion,
      'login_ip': DeviceInfoManager.info.ip,
      'login_location': '',
    }).then((response) {
      EasyLoading.dismiss();
      if (response?.success == true) {
        String token = response!.data!['token'];

        successCallback(token);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> deleteAccount({required VoidCallback successCallback}) async {
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApi(url: NetworkConstantsUtil.deleteAccount, param: null)
        .then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        successCallback();
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> updateFcmToken() async {
    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();
    // EasyLoading.show(status: loadingString.tr);

    await ApiWrapper().postApi(url: NetworkConstantsUtil.updatedDeviceToken, param: {
      "device_type": Platform.isAndroid ? '1' : '2',
      "device_token": fcmToken ?? '',
      "device_token_voip_ios": voipToken ?? ''
    }).then((response) {
      // EasyLoading.dismiss();

      if (response?.success == true) {
        // successCallback();
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> checkUsername(
      {required String username,
      required VoidCallback successCallback,
      required VoidCallback failureCallback}) async {
    // EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(url: NetworkConstantsUtil.checkUserName, param: {
      "username": username,
    }).then((response) {
      // EasyLoading.dismiss();

      if (response?.success == true) {
        successCallback();
      } else {
        failureCallback();
      }
    });
  }

  static Future<void> forgotPassword(
      {required String email,
      required Function(String) successCallback}) async {
    dynamic param = {
      "verification_with": '1',
      "email": email,
      "country_code": '',
      "phone": ''
    };
    EasyLoading.show(status: loadingString.tr);
    await ApiWrapper()
        .postApiWithoutToken(
            url: NetworkConstantsUtil.forgotPassword, param: param)
        .then((response) {
      EasyLoading.dismiss();
      if (response?.success == true) {
        String token = response!.data!['token'];

        successCallback(token);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> resetPassword(
      {required String token,
      required String newPassword,
      required VoidCallback successCallback}) async {
    dynamic param = {
      "token": token,
      "password": newPassword,
    };
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(
            url: NetworkConstantsUtil.resetPassword, param: param)
        .then((response) {
      EasyLoading.dismiss();
      if (response?.success == true) {
        successCallback();
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> resendOTP(
      {required String token, required VoidCallback successCallback}) async {
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(url: NetworkConstantsUtil.resendOTP, param: {
      "token": token,
    }).then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        successCallback();
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> verifyRegistrationOTP(
      {required String otp,
      required String token,
      required Function(String) successCallback}) async {
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper().postApiWithoutToken(
        url: NetworkConstantsUtil.verifyRegistrationOTP,
        param: {
          "otp": otp,
          "token": token,
        }).then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        String authKey = response!.data!['auth_key'];

        successCallback(authKey);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> verifyForgotPasswordOTP(
      {required String otp,
      required String token,
      required Function(String) successCallback}) async {
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApiWithoutToken(url: NetworkConstantsUtil.verifyFwdPWDOTP, param: {
      "otp": otp,
      "token": token,
    }).then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        String token = response!.data!['verify_token'];

        successCallback(token);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static Future<void> verifyChangePhoneOTP(
      {required String otp,
      required String token,
      required VoidCallback successCallback}) async {
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .postApi(url: NetworkConstantsUtil.verifyChangePhoneOTP, param: {
      "otp": otp,
      "verify_token": token,
    }).then((response) {
      EasyLoading.dismiss();

      if (response?.success == true) {
        successCallback();
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }
}
