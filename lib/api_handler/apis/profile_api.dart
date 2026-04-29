import 'dart:developer';
import 'dart:typed_data';
import 'package:foap/helper/imports/models.dart';
import 'package:latlng/latlng.dart';
import 'package:foap/api_handler/api_wrapper.dart';
import '../../helper/imports/common_import.dart';

class ProfileApi {
  static Future<void> getMyProfile({required Function(UserModel) resultCallback}) async {
    var url = NetworkConstantsUtil.getMyProfile;
    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        log('user profile ${result!.data['user']}');
        resultCallback(UserModel.fromJson(result.data['user']));
      }
    });
  }

  static Future<void> updateUserName(
      {required String userName, required VoidCallback resultCallback}) async{
    var url = NetworkConstantsUtil.updateUserProfile;

    await ApiWrapper().postApi(url: url, param: {
      "username": userName,
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> updateProfileCategoryType(
      {required int categoryType, required VoidCallback resultCallback}) async{
    var url = NetworkConstantsUtil.updateUserProfile;

    await ApiWrapper().postApi(url: url, param: {
      "profile_category_type": categoryType.toString(),
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> updateBiometricSetting(
      {required int setting, required VoidCallback resultCallback}) async{
    var url = NetworkConstantsUtil.updateUserProfile;

    await ApiWrapper().postApi(url: url, param: {
      "is_biometric_login": setting.toString(),
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> updatePhone(
      {required String countryCode,
      required String phone,
      required Function(String) resultCallback})async {
    var url = NetworkConstantsUtil.updatePhone;

    await ApiWrapper().postApi(
        url: url,
        param: {"country_code": countryCode, "phone": phone}).then((result) {
      if (result?.success == true) {
        resultCallback(result!.data['verify_token']);
      }
    });
  }

  static Future<void> updatePaymentDetails(
      {required String paypalId, required Function() resultCallback}) async{
    var url = NetworkConstantsUtil.updatePaymentDetail;
    var params = {"paypal_id": paypalId};

    await ApiWrapper().postApi(url: url, param: params).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> updateCountryCity(
      {required String country,
      required String city,
      required Function() resultCallback})async {
    var url = NetworkConstantsUtil.updateUserProfile;

    await ApiWrapper().postApi(
        url: url, param: {"country": country, "city": city}).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> updateUserLocation(
      {required LatLng location, required Function() resultCallback})async {
    var url = NetworkConstantsUtil.updateLocation;

    await ApiWrapper().postApi(url: url, param: {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'location': ''
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> pauseUserLocation(
      {required LatLng location, required Function() resultCallback})async {
    var url = NetworkConstantsUtil.updateLocation;

    await ApiWrapper().postApi(url: url, param: {
      'latitude': '',
      'longitude': '',
      'location': ''
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> changePassword(
      {required String oldPassword,
      required String newPassword,
      required VoidCallback resultCallback}) async{
    var url = NetworkConstantsUtil.updatePassword;

    await ApiWrapper().postApi(url: url, param: {
      "old_password": oldPassword,
      "password": newPassword
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> postRelationInviteUnInvite(
      {required int relationShipId,
      required int userId,
      required VoidCallback resultCallback}) async{
    var url = NetworkConstantsUtil.postInviteUnInvite;

    await ApiWrapper().postApi(url: url, param: {
      "relation_ship_id": relationShipId.toString(),
      "user_id": userId.toString(),
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> acceptRejectInvitation(
      {required int invitationId,
      required int status,
      required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.putAcceptRejectInvite;

    await ApiWrapper().postApi(url: url, param: {
      "id": invitationId.toString(),
      "status": status.toString(),
    }).then((result) {
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> sendProfileVerificationRequest(
      {required String userMessage,
      required String documentType,
      required List<Map<String, String>> images,
      required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.requestVerification;

    await ApiWrapper().postApi(url: url, param: {
      "user_message": userMessage,
      'document': images,
      'document_type': documentType,
    }).then((result) {
      resultCallback();
    });
  }

  static Future<void> cancelProfileVerificationRequest(
      {required int id,
      required String userMessage,
      required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.cancelVerification;

    await ApiWrapper().postApi(url: url, param: {
      'user_message': userMessage,
      'id': id.toString(),
    }).then((result) {
      resultCallback();
    });
  }

  static Future<void> getVerificationRequestHistory(
      {required Function(List<VerificationRequest>) resultCallback}) async {
    var url = NetworkConstantsUtil.requestVerificationHistory;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = result!.data['verification']['items'];

        resultCallback(List<VerificationRequest>.from(
            items.map((x) => VerificationRequest.fromJson(x))));
      }
    });
  }

  static Future<void> uploadProfileImage(Uint8List imageData,
      {required VoidCallback resultCallback}) async{
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .multipartImageUpload(
            url: NetworkConstantsUtil.updateProfileImage,
            imageFileData: imageData)
        .then((result) {
      EasyLoading.dismiss();
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> uploadProfileCoverImage(Uint8List imageData,
      {required VoidCallback resultCallback}) async{
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper()
        .multipartImageUpload(
            url: NetworkConstantsUtil.updateProfileCoverImage,
            imageFileData: imageData)
        .then((result) {
      EasyLoading.dismiss();
      if (result?.success == true) {
        resultCallback();
      }
    });
  }

  static Future<void> updateAccountPrivacy(
      {required bool isPrivate, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.updateAccountPrivacy;

    await ApiWrapper().postApi(url: url, param: {
      'profile_visibility': isPrivate ? 2 : 1,
    }).then((result) {
      resultCallback();
    });
  }

  static Future<void> updateOnlineStatusSetting(
      {required int status, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.updateOnlineStatusSetting;

    await ApiWrapper().postApi(url: url, param: {
      'is_show_online_chat_status': status.toString(),
    }).then((result) {
      resultCallback();
    });
  }
}
