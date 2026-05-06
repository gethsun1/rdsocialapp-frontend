import '../../model/api_meta_data.dart';
import '../../model/call_history_model.dart';
import '../../model/chat_message_model.dart';
import '../../model/chat_room_model.dart';
import '../../model/user_model.dart';
import '../api_wrapper.dart';

class _ChatPagedNode {
  final List items;
  final APIMetaData metaData;

  _ChatPagedNode({required this.items, required this.metaData});
}

class ChatApi {
  static int _readId(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

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

  static _ChatPagedNode _parsePagedNode(
    dynamic data,
    List<String> keys,
    int page,
  ) {
    final fallbackMetaData = _fallbackMetaData(page);
    if (data is! Map) {
      return _ChatPagedNode(items: [], metaData: fallbackMetaData);
    }

    final map = Map<String, dynamic>.from(data);
    for (final key in keys) {
      final node = map[key];
      if (node is Map) {
        final nodeMap = Map<String, dynamic>.from(node);
        final items = nodeMap['items'];
        return _ChatPagedNode(
          items: items is List ? items : [],
          metaData: _parseMetaData(nodeMap['_meta'] ?? nodeMap['meta'], page),
        );
      }
      if (node is List) {
        return _ChatPagedNode(items: node, metaData: fallbackMetaData);
      }
    }

    final directItems = map['items'];
    if (directItems is List) {
      return _ChatPagedNode(
        items: directItems,
        metaData: _parseMetaData(map['_meta'] ?? map['meta'], page),
      );
    }

    return _ChatPagedNode(items: [], metaData: fallbackMetaData);
  }

  static Future<void> createChatRoom(int opponentId,
      {required Function(int) resultCallback}) async {
    var url = NetworkConstantsUtil.createChatRoom;
    dynamic param = {"receiver_id": opponentId.toString(), "type": '1'};

    await ApiWrapper().postApi(url: url, param: param).then((result) {
      if (result?.success == true) {
        final data = result?.data;
        final roomId = data is Map
            ? data['room_id'] ??
                data['roomId'] ??
                data['id'] ??
                (data['room'] is Map ? data['room']['id'] : null)
            : null;
        resultCallback(_readId(roomId));
      }
    });
  }

  static Future<void> createGroupChatRoom(
      {String? image,
      String? description,
      required bool isPublicGroup,
      required String title,
      required Function(int) resultCallback}) async {
    var url = NetworkConstantsUtil.createChatRoom;
    dynamic param = {
      "type": isPublicGroup ? '3' : '2',
      'receiver_id': '',
      'title': title,
      'image': image ?? '',
      'description': description ?? '',
      'chat_access_group': '2',
    };

    await ApiWrapper().postApi(url: url, param: param).then((result) {
      final data = result?.data;
      final roomId = data is Map
          ? data['room_id'] ??
              data['roomId'] ??
              data['id'] ??
              (data['room'] is Map ? data['room']['id'] : null)
          : null;
      resultCallback(_readId(roomId));
    });
  }

  static Future updateGroupChatRoom(int groupId, String title, String? image,
      String? description, String? groupAccess) async {
    var url = NetworkConstantsUtil.updateGroupChatRoom + groupId.toString();

    Map<String, String> param = {};

    param['title'] = title;

    if (description != null) {
      param['description'] = description;
    }
    if (image != null) {
      param['image'] = image;
    }
    if (groupAccess != null) {
      param['chat_access_group'] = groupAccess;
    }

    await ApiWrapper().postApi(url: url, param: param).then((result) {});
  }

  static Future<void> deleteChatRoom(int roomId) async {
    var url = NetworkConstantsUtil.deleteChatRoom + roomId.toString();

    await ApiWrapper().getApi(url: url).then((result) {});
  }

  static Future<void> deleteChatRoomMessages(int roomId) async {
    var url = NetworkConstantsUtil.deleteChatRoomMessages + roomId.toString();

    await ApiWrapper().postApi(
        url: url, param: {'room_id': roomId.toString()}).then((result) {});
  }

  static Future<void> getChatRooms(
      {required Function(List<ChatRoomModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.getChatRooms;
    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['room', 'rooms', 'chatRoom', 'results'],
          1,
        );
        resultCallback(List<ChatRoomModel>.from(
            parsed.items.map((x) => ChatRoomModel.fromJson(x))));
      }
    });
  }

  static Future<void> getPublicChatRooms(
      {required int page,
      required Function(List<ChatRoomModel>, APIMetaData)
          resultCallback}) async {
    var url = '${NetworkConstantsUtil.getPublicChatRooms}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['room', 'rooms', 'chatRoom', 'results'],
          page,
        );
        resultCallback(
            List<ChatRoomModel>.from(
                parsed.items.map((x) => ChatRoomModel.fromJson(x))),
            parsed.metaData);
      }
    });
  }

  static Future<void> getChatRoomDetail(int roomId,
      {required Function(ChatRoomModel) resultCallback}) async {
    var url = NetworkConstantsUtil.getChatRoomDetail;
    url = url.replaceAll('{room_id}', roomId.toString());

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final data = result?.data;
        var room = data is Map ? data['room'] ?? data['chatRoom'] : null;
        room ??= data;
        if (room != null) {
          resultCallback(ChatRoomModel.fromJson(room));
        }
      }
    });
  }

  static Future<void> getChatHistory(
      {required int roomId,
      required int lastMessageId,
      required Function(List<ChatMessageModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.chatHistory;
    url = url
        .replaceAll('{{room_id}}', roomId.toString())
        .replaceAll('{{last_message_id}}', lastMessageId.toString());

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['chatMessage', 'chatMessages', 'message', 'messages', 'results'],
          1,
        );
        resultCallback(List<ChatMessageModel>.from(
            parsed.items.map((x) => ChatMessageModel.fromJson(x))));
      }
    });
  }

  static Future<void> getCallHistory(
      {required int page,
      required Function(List<CallHistoryModel>, APIMetaData)
          resultCallback}) async {
    var url = '${NetworkConstantsUtil.callHistory}&page=$page';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['callHistory', 'calls', 'call', 'results'],
          page,
        );
        final items = parsed.items.where((e) {
          if (e is! Map) return false;
          return e['receiverDetail'] != null ||
              e['receiver_detail'] != null ||
              e['receiver'] != null;
        });

        resultCallback(
            List<CallHistoryModel>.from(
                items.map((x) => CallHistoryModel.fromJson(x))),
            parsed.metaData);
      }
    });
  }

  static Future<void> getCallDetail(
      {required int callId,
      required Function(CallHistoryModel) resultCallback}) async {
    var url = NetworkConstantsUtil.callDetail
        .replaceAll('{{call_id}}', callId.toString());

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final data = result?.data;
        var callHistory = data is Map
            ? data['call'] ?? data['callDetail'] ?? data['result']
            : data;
        if (callHistory != null) {
          resultCallback(CallHistoryModel.fromJson(callHistory));
        }
      }
    });
  }

  static Future<void> getRandomOnlineUsers(int? profileCategoryType,
      {required Function(List<UserModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.randomOnlineUser;
    if (profileCategoryType != null) {
      url = '$url${profileCategoryType.toString()}';
    }

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        List items = result!.data['user'];

        if (items.isEmpty) {
          getRandomOnlineUsers(profileCategoryType,
              resultCallback: resultCallback);
        } else {
          resultCallback(
              List<UserModel>.from(items.map((x) => UserModel.fromJson(x))));
        }
      }
    });
  }
}
