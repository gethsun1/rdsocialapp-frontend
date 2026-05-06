import 'package:foap/api_handler/api_wrapper.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/helper/imports/models.dart';

import '../../helper/enum_linking.dart';
import '../../model/follow_request.dart';
import '../../model/support_request_response.dart';

class _PagedNode {
  final List items;
  final APIMetaData metaData;

  _PagedNode({required this.items, required this.metaData});
}

class MiscApi {
  static APIMetaData _fallbackMetaData(int page) {
    return APIMetaData(
      totalCount: 0,
      pageCount: page,
      currentPage: page,
      perPage: 20,
    );
  }

  static APIMetaData _parseMetaData(dynamic value, int page) {
    if (value is Map<String, dynamic>) {
      return APIMetaData.fromJson(value);
    }
    if (value is Map) {
      return APIMetaData.fromJson(Map<String, dynamic>.from(value));
    }
    return _fallbackMetaData(page);
  }

  static _PagedNode _parsePagedNode(
    dynamic data,
    List<String> keys,
    int page,
  ) {
    final fallbackMetaData = _fallbackMetaData(page);
    if (data is! Map) {
      return _PagedNode(items: [], metaData: fallbackMetaData);
    }

    final map = Map<String, dynamic>.from(data);
    for (final key in keys) {
      final node = map[key];
      if (node is Map) {
        final nodeMap = Map<String, dynamic>.from(node);
        final items = nodeMap['items'];
        return _PagedNode(
          items: items is List ? items : [],
          metaData: _parseMetaData(nodeMap['_meta'] ?? nodeMap['meta'], page),
        );
      }
      if (node is List) {
        return _PagedNode(items: node, metaData: fallbackMetaData);
      }
    }

    final directItems = map['items'];
    if (directItems is List) {
      return _PagedNode(
        items: directItems,
        metaData: _parseMetaData(map['_meta'] ?? map['meta'], page),
      );
    }

    return _PagedNode(items: [], metaData: fallbackMetaData);
  }

  static Future<void> getProfileCategoryType(
      {required Function(List<CategoryModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.profileCategoryTypes;

    EasyLoading.show(status: loadingString.tr);
    await ApiWrapper().getApi(url: url).then((result) {
      EasyLoading.dismiss();
      if (result?.success == true) {
        var items = result!.data['profileCategoryType'];
        resultCallback(List<CategoryModel>.from(
            items.map((x) => CategoryModel.fromJson(x))));
      }
    });
  }

  static Future<void> getPolls(
      {required Function(List<PollsModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.getPolls;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['poll', 'polls', 'results'],
          1,
        );
        resultCallback(List<PollsModel>.from(
            parsed.items.map((x) => PollsModel.fromJson(x))));
      }
    });
  }

  static Future<void> postPollAnswer(
      {required int pollId,
      // required int pollQuestionId,
      required int questionOptionId,
      required Function(List<PollsModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.postPoll;

    await ApiWrapper().postApi(url: url, param: {
      "poll_id": pollId.toString(),
      // "poll_question_id": pollQuestionId.toString(),
      "question_option_id": questionOptionId.toString(),
    }).then((response) {
      if (response?.success == true) {
        final data = response?.data;
        final polls = <PollsModel>[];

        if (data is Map) {
          final poll = data['poll'] ?? data['question'];
          if (poll is Map) {
            polls.add(PollsModel.fromJson(Map<String, dynamic>.from(poll)));
          } else if (poll is List) {
            polls.addAll(poll
                .whereType<Map>()
                .map((x) => PollsModel.fromJson(Map<String, dynamic>.from(x))));
          }

          final result = data['result'];
          if (polls.isEmpty && result is Map) {
            final question = result['question'];
            final questionOption =
                result['questionOption'] ?? result['pollOptions'];
            if (question is List &&
                question.isNotEmpty &&
                question.first is Map) {
              final questionMap = Map<String, dynamic>.from(question.first);
              questionMap['pollOptions'] =
                  questionMap['pollOptions'] ?? questionOption;
              questionMap['pollQuestionOption'] =
                  questionMap['pollQuestionOption'] ?? questionOption;
              polls.add(PollsModel.fromJson(questionMap));
            } else if (question is Map) {
              final questionMap = Map<String, dynamic>.from(question);
              questionMap['pollOptions'] =
                  questionMap['pollOptions'] ?? questionOption;
              questionMap['pollQuestionOption'] =
                  questionMap['pollQuestionOption'] ?? questionOption;
              polls.add(PollsModel.fromJson(questionMap));
            }
          }
        }

        resultCallback(polls);
      }
    });
  }

  static Future<void> getNotifications(
      {required Function(List<NotificationModel>, APIMetaData)
          resultCallback}) async {
    var url = NetworkConstantsUtil.getNotifications;

    await ApiWrapper().getApi(url: url).then((result) {
      final parsed = _parsePagedNode(
        result?.data,
        ['notification', 'notifications', 'results'],
        1,
      );
      resultCallback(
          List<NotificationModel>.from(
              parsed.items.map((x) => NotificationModel.fromJson(x))),
          parsed.metaData);
    });
  }

  static Future<void> updateNotificationSettings(
      {required String likesNotificationStatus,
      required String commentNotificationStatus,
      required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.notificationSettings;
    await ApiWrapper().postApi(url: url, param: {
      "like_push_notification_status": likesNotificationStatus,
      "comment_push_notification_status": commentNotificationStatus
    }).then((result) {
      if (result?.success == true) {}
    });
  }

  static Future<void> getSettings(
      {required Function(SettingModel) resultCallback}) async {
    var url = NetworkConstantsUtil.getSettings;

    await ApiWrapper().getApiWithoutToken(url: url).then((result) {
      if (result?.success == true && result?.data is Map<String, dynamic>) {
        final setting = (result!.data as Map<String, dynamic>)['setting'];
        if (setting is Map<String, dynamic>) {
          resultCallback(SettingModel.fromJson(setting));
        }
      }
    });
  }

  static Future<void> sendSupportRequest(
      {required String name,
      required String email,
      required String phone,
      required String message}) async {
    var url = NetworkConstantsUtil.submitRequest;
    dynamic param = {
      "name": name,
      "email": email,
      "phone": phone,
      "request_message": message
    };
    await ApiWrapper().postApi(url: url, param: param).then((result) {
      if (result?.success == true) {}
    });
  }

  static Future<void> getSupportMessages(
      {required Function(List<SupportRequest>, APIMetaData)
          resultCallback}) async {
    var url = NetworkConstantsUtil.supportRequests;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        List items = result!.data['supportRequest']['items'] as List;
        resultCallback(items.map((e) => SupportRequest.fromJson(e)).toList(),
            APIMetaData.fromJson(result.data['supportRequest']['_meta']));
      }
    });
  }

  static Future<void> getSupportMessageView(int id) async {
    var url =
        NetworkConstantsUtil.supportRequestView.replaceAll('id', id.toString());

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {}
    });
  }

  static Future<void> searchHashtag(
      {required String hashtag,
      required int page,
      required Function(List<Hashtag>, APIMetaData) resultCallback}) async {
    var url = '${NetworkConstantsUtil.searchHashtag}$hashtag&page=$page';

    ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = result!.data['results']['items'];
        resultCallback(
            List<Hashtag>.from(items.map((x) => Hashtag.fromJson(x))),
            APIMetaData.fromJson(result.data['results']['_meta']));
      }
    });
  }

  static Future<void> getFAQ(
      {required Function(List<FAQModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.getFAQs;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = result!.data['faq']['items'];

        resultCallback(
            List<FAQModel>.from(items.map((x) => FAQModel.fromJson(x))));
      }
    });
  }

  static Future uploadFile(String filePath,
      {required UploadMediaType type,
      required GalleryMediaType mediaType,
      Map<String, String>? extraFields,
      required Function(String, String) resultCallback}) async {
    EasyLoading.show(status: loadingString.tr);

    try {
      final result = await ApiWrapper().uploadFile(
          url: NetworkConstantsUtil.uploadFileImage,
          file: filePath,
          mediaType: mediaType,
          type: type,
          extraFields: extraFields);

      EasyLoading.dismiss();

      if (result == null) {
        AppUtil.showToast(
            message: 'Upload request failed. Please check your connection.',
            isSuccess: false);
        return;
      }

      if (result.success != true) {
        AppUtil.showToast(
            message: (result.message?.isNotEmpty == true)
                ? result.message!
                : 'Unable to upload media right now.',
            isSuccess: false);
        return;
      }

      final dynamic data = result.data;
      final dynamic filesNode =
          data is Map<String, dynamic> ? data['files'] : null;

      Map<String, dynamic>? fileItem;
      if (filesNode is List && filesNode.isNotEmpty && filesNode.first is Map) {
        fileItem = Map<String, dynamic>.from(filesNode.first as Map);
      } else if (filesNode is Map) {
        fileItem = Map<String, dynamic>.from(filesNode);
      } else if (data is Map &&
          (data['file'] != null || data['fileUrl'] != null)) {
        fileItem = Map<String, dynamic>.from(data);
      }

      if (fileItem == null) {
        AppUtil.showToast(
            message: 'Upload succeeded but file data was missing.',
            isSuccess: false);
        return;
      }

      final dynamic moderationFlag =
          fileItem['isProhabited'] ?? fileItem['isProhibited'] ?? false;
      final bool isProhibited = moderationFlag == true ||
          moderationFlag == 1 ||
          moderationFlag == '1' ||
          moderationFlag.toString().toLowerCase() == 'true';

      if (isProhibited) {
        AppUtil.showToast(
            message: thisContentNotAllowedString.tr, isSuccess: false);
        return;
      }

      final String? uploadedFile = fileItem['file']?.toString();
      final String? uploadedUrl = fileItem['fileUrl']?.toString();
      if (uploadedFile == null || uploadedFile.isEmpty) {
        AppUtil.showToast(
            message: 'Upload succeeded but filename was missing.',
            isSuccess: false);
        return;
      }

      resultCallback(uploadedFile, uploadedUrl ?? '');
    } catch (e) {
      EasyLoading.dismiss();
      debugPrint('[MiscApi] uploadFile failed: $e');
      AppUtil.showToast(
          message: 'Media upload failed unexpectedly. Please try again.',
          isSuccess: false);
    }
  }

  static Future<void> getFollowRequests(
      {required int page,
      required Function(List<FollowRequestModel>, APIMetaData)
          resultCallback}) async {
    var url = '${NetworkConstantsUtil.followRequests}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        var items = result!.data['followingRequest']['items'];
        resultCallback(
            List<FollowRequestModel>.from(
                items.map((x) => FollowRequestModel.fromJson(x))),
            APIMetaData.fromJson(result.data['followingRequest']['_meta']));
      }
    });
  }

  static Future<void> acceptFollowRequest({required int userId}) async {
    var url = NetworkConstantsUtil.acceptFollowRequestString;

    await ApiWrapper().postApi(
        url: url, param: {"user_id": userId.toString()}).then((result) {});
  }

  static Future<void> declineFollowRequest({required int userId}) async {
    var url = NetworkConstantsUtil.declineFollowRequestString;

    await ApiWrapper().postApi(
        url: url, param: {"user_id": userId.toString()}).then((result) {});
  }

  static Future<void> getNotificationInfo(
      {required Function(int) resultCallback}) async {
    var url = NetworkConstantsUtil.notificationInformation;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final count = result!.data is Map
            ? (result.data['unread_notification'] ??
                result.data['unreadNotification'] ??
                result.data['count'])
            : 0;
        resultCallback(int.tryParse(count?.toString() ?? '') ?? 0);
      }
    });
  }

  static Future<bool> markNotificationAsRead({required int id}) async {
    var url = NetworkConstantsUtil.markNotificationAsRead;

    final result = await ApiWrapper().postApi(url: url, param: {
      "id": id,
      "notification_id": id,
      "notificationId": id,
      "is_read": 1,
      "read_status": 1,
      "is_read_all": 0

      /// for single send 0, send 1 to all as read
    });
    return result?.success == true;
  }

  static Future<int?> pinContent(
      {required PinContentType type,
      required int refId,
      required Function(int) successHandler}) async {
    var url = NetworkConstantsUtil.addPinContent;

    final result = await ApiWrapper().postApi(url: url, param: {
      "reference_id": refId,
      "type": pinContentTypeId(type),
    });

    if (result?.success != true) return null;

    final data = result?.data;
    final rawId = data is Map
        ? data['id'] ??
            data['pin_id'] ??
            data['pinId'] ??
            (data['pin'] is Map ? data['pin']['id'] : null)
        : null;
    final id = int.tryParse(rawId?.toString() ?? '');
    if (id != null) {
      successHandler(id);
    }
    return id;
  }

  static Future<bool> removePinContent({
    required PinContentType type,
    required int refId,
  }) async {
    var url = '${NetworkConstantsUtil.removePinContent}$refId';

    final response = await ApiWrapper().deleteApi(url: url);
    return response?.success == true;
  }
}
