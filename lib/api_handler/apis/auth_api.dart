import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foap/helper/device_info.dart';
import 'package:foap/util/app_config_constants.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../helper/localization_strings.dart';
import '../../util/app_util.dart';
import '../../util/shared_prefs.dart';
import '../api_wrapper.dart';

class AuthApi {
  static String? lastFirebaseBridgeError;

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
      required Function(String, bool) successCallback}) async {
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
        final data = response!.data;
        String authKey = data!['auth_key'];
        final isNewUser = _readBool(data['is_new_user'] ??
            data['isNewUser'] ??
            data['is_login_first_time'] ??
            data['isLoginFirstTime'] ??
            data['is_registered']);

        successCallback(authKey, isNewUser);
      } else {
        AppUtil.showToast(
            message: response?.message ?? errorMessageString.tr,
            isSuccess: false);
      }
    });
  }

  static bool _readBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static Future<String?> loginWithFirebaseUser(
      {required User firebaseUser,
      String? socialTypeOverride,
      bool showErrorToast = true}) async {
    lastFirebaseBridgeError = null;
    String? fcmToken = await SharedPrefs().getFCMToken();
    String? voipToken = await SharedPrefs().getVoipToken();

    final socialType =
        socialTypeOverride ?? AppConfigConstants.firebaseBackendSocialType;
    final localPart = (firebaseUser.email ?? '').split('@').first;
    final fallbackName = localPart.isNotEmpty ? localPart : 'user';
    final name = (firebaseUser.displayName ?? fallbackName).trim();
    final email = (firebaseUser.email ?? '').trim();
    final firebaseToken = await firebaseUser.getIdToken(true);

    if (email.isEmpty) {
      lastFirebaseBridgeError =
          'No email is available from Firebase account for backend login.';
      if (showErrorToast) {
        AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
      }
      return null;
    }
    if (firebaseToken == null || firebaseToken.isEmpty) {
      lastFirebaseBridgeError =
          'Unable to get Firebase token for backend login.';
      if (showErrorToast) {
        AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
      }
      return null;
    }

    Future<ApiResponse?> callLoginSocial(String type) {
      final payload = {
        "name": name,
        "username": "",
        "social_type": type,
        "social_id": firebaseUser.uid,
        "email": email,
        "firebase_token": firebaseToken,
        "device_type": DeviceInfoManager.info.deviceType,
        "device_token": fcmToken ?? '',
        "device_token_voip_ios": voipToken ?? '',
        'device_model': DeviceInfoManager.info.model.toString(),
        'device_os_version': DeviceInfoManager.info.osVersion.toString(),
        'device_app_release_version': AppConfigConstants.currentVersion,
        'login_ip': DeviceInfoManager.info.ip.toString(),
        'login_location': '',
      };

      final url =
          '${NetworkConstantsUtil.baseUrl}${NetworkConstantsUtil.socialLogin}';

      return http
          .post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .then((http.Response response) {
        try {
          final dynamic decoded = jsonDecode(response.body);
          return ApiResponse.fromJson(decoded);
        } catch (e) {
          final fallback = ApiResponse();
          fallback.success = false;
          fallback.message =
              'Invalid backend response (${response.statusCode}): $e';
          fallback.data = {'raw': response.body};
          return fallback;
        }
      });
    }

    String? extractAuthKey(dynamic responseData) {
      if (responseData is! Map) return null;
      final map = Map<String, dynamic>.from(responseData);
      final directAuthKey = map['auth_key'];
      final directToken = map['token'];
      final nestedUser = map['user'];

      String? normalizeToken(dynamic value) {
        if (value == null) return null;
        final token = value.toString().trim();
        return token.isEmpty ? null : token;
      }

      final token =
          normalizeToken(directAuthKey) ?? normalizeToken(directToken);
      if (token != null) {
        return token;
      }

      if (nestedUser is Map) {
        final nestedMap = Map<String, dynamic>.from(nestedUser);
        return normalizeToken(nestedMap['auth_key']) ??
            normalizeToken(nestedMap['token']);
      }

      return null;
    }

    var attemptedTypes = <String>[socialType];
    ApiResponse? response;
    String? extractedAuthKey;
    try {
      response = await callLoginSocial(socialType);
      extractedAuthKey = extractAuthKey(response?.data);

      // Optional legacy fallback for deployments that still expect provider
      // "google" even when Firebase token bridging is enabled.
      if (extractedAuthKey == null &&
          socialType == 'firebase' &&
          AppConfigConstants.allowLegacyGoogleSocialTypeFallback) {
        response = await callLoginSocial('google');
        attemptedTypes.add('google');
        extractedAuthKey = extractAuthKey(response?.data);
      }
    } on SocketException catch (e) {
      lastFirebaseBridgeError = 'Network error reaching backend: ${e.message}';
      if (showErrorToast) {
        AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
      }
      return null;
    } on HttpException catch (e) {
      lastFirebaseBridgeError = 'HTTP error during backend login: ${e.message}';
      if (showErrorToast) {
        AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
      }
      return null;
    } on FormatException catch (e) {
      lastFirebaseBridgeError =
          'Backend returned invalid response format: ${e.message}';
      if (showErrorToast) {
        AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
      }
      return null;
    } catch (e) {
      lastFirebaseBridgeError = 'Unexpected backend bridge error: $e';
      if (showErrorToast) {
        AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
      }
      return null;
    }

    // Accept auth key even if backend returns non-200 custom status,
    // as long as token is present and usable.
    if (extractedAuthKey != null) {
      return extractedAuthKey;
    }

    lastFirebaseBridgeError = response?.message ??
        'No response from backend while creating session after Firebase sign-in.';

    debugPrint(
        '[AuthApi] loginWithFirebaseUser failed. attemptedSocialTypes=$attemptedTypes, success=${response?.success}, message=${response?.message}, data=${response?.data}');

    if (showErrorToast) {
      AppUtil.showToast(message: lastFirebaseBridgeError!, isSuccess: false);
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
      "role": '3',
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

  static Future<void> deleteAccount(
      {required VoidCallback successCallback}) async {
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

    await ApiWrapper()
        .postApi(url: NetworkConstantsUtil.updatedDeviceToken, param: {
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
