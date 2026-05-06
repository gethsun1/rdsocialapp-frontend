import 'dart:convert';
import 'package:foap/helper/imports/common_import.dart';
import 'chat_message_model.dart';

class ChatRoomMember {
  int id;

  int roomId;
  int userId;
  int isAdmin;
  UserModel userDetail;

  ChatRoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.isAdmin,
    required this.userDetail,
  });

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  factory ChatRoomMember.fromJson(Map<String, dynamic> jsonData) {
    final userJson = jsonData['user'] ??
        jsonData['userDetail'] ??
        jsonData['user_detail'] ??
        jsonData['memberDetail'];
    final parsedUserJson =
        userJson is String ? json.decode(userJson) : userJson;
    final fallbackUser = {
      'id': jsonData['user_id'] ?? jsonData['userId'],
      'username': '',
      'name': '',
      'picture': ''
    };

    return ChatRoomMember(
        id: _readInt(jsonData["id"]),
        roomId: _readInt(jsonData["room_id"] ?? jsonData["room"]),
        userId: _readInt(jsonData["user_id"] ?? jsonData["userId"]),
        isAdmin: _readInt(jsonData["is_admin"] ?? jsonData["isAdmin"]),
        userDetail: UserModel.fromJson(parsedUserJson ?? fallbackUser));
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "room_id": roomId,
        "user_id": userId,
        "is_admin": isAdmin,
        "user": json.encode(userDetail.toJson()),
      };
}

class ChatRoomModel {
  int id = 0;
  int status = 0;
  int createdAt = 0;
  int? updatedAt;

  int createdBy = 0;
  String? name;

  // List<UserModel> users = [];
  ChatMessageModel? lastMessage;
  String? lastMessageId;

  // bool isTyping = false;
  List<String> whoIsTyping = [];
  bool isOnline = false;
  int unreadMessages = 0;
  bool isGroupChat;
  int type = 0;

  String? image;
  String? description;
  int groupAccess;
  List<ChatRoomMember> roomMembers;
  UserModel chatGroupOwner;

  ChatRoomModel({
    required this.id,
    this.lastMessageId,
    this.name,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    // required this.users,
    required this.isOnline,
    required this.isGroupChat,
    required this.type,
    required this.lastMessage,
    required this.groupAccess,
    this.image,
    this.description,
    required this.roomMembers,
    required this.chatGroupOwner,
  });

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  static List<ChatRoomMember> _readMembers(dynamic value) {
    if (value == null) return [];
    final items = value is String ? json.decode(value) : value;
    if (items is! List) return [];

    return items
        .where((e) => e != null)
        .map((e) => ChatRoomMember.fromJson(
            Map<String, dynamic>.from(e is String ? json.decode(e) : e)))
        .toList();
  }

  factory ChatRoomModel.fromJson(dynamic jsonData) {
    if (jsonData is! Map) {
      jsonData = <String, dynamic>{};
    }

    final map = Map<String, dynamic>.from(jsonData);
    final type = ChatRoomMember._readInt(map['type'], fallback: 1);
    final createdBy = ChatRoomMember._readInt(
        map['created_by'] ?? map['createdBy'] ?? map['created_by_id']);
    final ownerJson = map['createdByUser'] ??
        map['created_by_user'] ??
        map['createdBy'] ??
        {'id': createdBy};
    final parsedOwnerJson =
        ownerJson is String ? json.decode(ownerJson) : ownerJson;
    final lastMessage = map['lastMessage'] ?? map['last_message'];

    return ChatRoomModel(
        id: ChatRoomMember._readInt(map['id']),
        lastMessageId:
            (map['last_message_id'] ?? map['lastMessageId'])?.toString(),
        name: (map['title'] ?? map['name'] ?? 'No Group name added').toString(),
        status: ChatRoomMember._readInt(map['status']),
        createdAt: ChatMessageModel.readEpochSeconds(
            map['created_at'] ?? map['createdAt']),
        updatedAt: map['updated_at'] == null && map['updatedAt'] == null
            ? null
            : ChatMessageModel.readEpochSeconds(
                map['updated_at'] ?? map['updatedAt']),
        createdBy: createdBy,
        isOnline: _readBool(map['is_chat_user_online'] ?? map['isOnline']),
        isGroupChat: type != 1,
        type: type,
        image:
            (map['imageUrl'] ?? map['image_url'] ?? map['image'])?.toString(),
        description: map['description']?.toString(),
        groupAccess: ChatRoomMember._readInt(
            map['chat_access_group'] ?? map['chatAccessGroup'],
            fallback: 2),
        chatGroupOwner: UserModel.fromJson(parsedOwnerJson),
        roomMembers: _readMembers(map['chatRoomUser'] ??
            map['chat_room_user'] ??
            map['members'] ??
            map['roomMembers']),
        lastMessage: lastMessage == null
            ? null
            : ChatMessageModel.fromJson(lastMessage));
  }

  Map<String, dynamic> toJson() {
    // print(users.first.toJson());
    return {
      'id': id,
      'title': name,
      'status': status,
      'created_at': createdAt,
      'created_by': createdBy,
      'is_chat_user_online': isOnline,
      'type': type,
      'imageUrl': image,
      'description': description,
      'chat_access_group': groupAccess,
      'chatRoomUser':
          json.encode(roomMembers.map((e) => json.encode(e.toJson())).toList()),
      'createdByUser': json.encode(chatGroupOwner.toJson()),
      // 'unreadMessages': unreadMessages,
    };
  }

  ChatRoomMember get opponent {
    final UserProfileManager userProfileManager = Get.find();

    return roomMembers
        .where((element) =>
            element.userDetail.id != userProfileManager.user.value!.id)
        .first;
  }

  bool get amIGroupAdmin {
    return roomMembers
        .where((element) => element.isAdmin == 1 && element.userDetail.isMe)
        .toList()
        .isNotEmpty;
  }

  bool get amIMember {
    return roomMembers
        .where((element) => element.userDetail.isMe)
        .toList()
        .isNotEmpty;
  }

  bool get canIChat {
    if (isGroupChat == false) {
      return true;
    }
    if (groupAccess == 2) {
      return true;
    }
    return amIGroupAdmin;
  }

  ChatRoomMember memberById(int memberId) {
    return roomMembers
        .where((element) => element.userDetail.id == memberId)
        .first;
  }
}
