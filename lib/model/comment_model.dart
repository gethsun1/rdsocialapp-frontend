import 'package:foap/helper/date_extension.dart';
import 'package:get/get.dart';

import '../helper/enum.dart';
import '../helper/localization_strings.dart';
import 'user_model.dart';

class CommentModel {
  int id = 0;
  int? parentId;

  String comment = "";

  int userId = 0;
  String userName = '';
  String? userPicture;
  String commentTime = '';
  UserModel? user;
  CommentType type = CommentType.text; // text=1, image=2, video = 3, gif =4
  String filePath = '';
  int level = 1;
  bool isFavourite = false;
  List<CommentModel> replies = [];
  int currentPageForReplies = 1;
  int pendingReplies = 0;

  int totalReplies = 0;
  bool isPinned = false;
  int? pinId;

  CommentModel();

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static DateTime _readCreatedAt(dynamic value) {
    if (value is num) {
      final timestamp = value.toInt();
      final milliseconds =
          timestamp > 1000000000000 ? timestamp : timestamp * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds).toUtc();
    }
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toUtc() ?? DateTime.now().toUtc();
  }

  factory CommentModel.fromJson(dynamic json) {
    CommentModel model = CommentModel();
    if (json is! Map) {
      return model;
    }

    model.id = _readInt(json['id']);
    model.parentId = json['parent_id'] == null
        ? null
        : _readInt(json['parent_id'] ?? json['parentId']);

    model.comment = (json['comment'] ?? json['text'] ?? '').toString();
    model.userId = _readInt(json['user_id'] ?? json['userId']);
    model.level = _readInt(json['level'], fallback: 1);
    model.isFavourite = json['isLike'] == 1 || json['is_like'] == 1;

    model.totalReplies =
        _readInt(json['totalChildComment'] ?? json['total_child_comment']);
    model.pendingReplies = model.totalReplies;

    dynamic user = json['user'] ?? json['createdByUser'] ?? json['userDetail'];
    model.user = user == null ? UserModel() : UserModel.fromJson(user);
    if (user != null) {
      model.userName = (user['username'] ?? '').toString();
      model.userPicture =
          (user['picture'] ?? user['profileImageUrl'])?.toString();
    }
    if (model.userName.isEmpty) {
      model.userName = model.user?.userName ?? '';
    }
    if (model.userId == 0) {
      model.userId = model.user?.id ?? 0;
    }

    final type = _readInt(json['type']);
    model.type = type == 4
        ? CommentType.gif
        : type == 3
            ? CommentType.video
            : type == 2
                ? CommentType.image
                : CommentType.text;
    model.filePath =
        (json['filenameUrl'] ?? json['fileUrl'] ?? json['file_url'] ?? '')
            .toString();

    DateTime createDate = _readCreatedAt(json['created_at']);
    model.commentTime = createDate.getTimeAgo;

    model.isPinned = json['isPin'] != null;
    model.pinId = json['isPin'] == null ? null : json['isPin']['id'];
    return model;
  }

  factory CommentModel.fromNewMessage(CommentType type, UserModel user,
      {required int id, String? comment, String? filePath}) {
    CommentModel model = CommentModel();
    model.id = id;
    model.type = type;
    model.comment = comment ?? '';
    model.filePath = filePath ?? '';

    model.userId = user.id;
    model.userName = user.userName;
    model.userPicture = user.picture;
    model.user = user;
    model.commentTime = justNowString.tr;

    return model;
  }

  bool get canReply {
    return level == 1;
  }
}
