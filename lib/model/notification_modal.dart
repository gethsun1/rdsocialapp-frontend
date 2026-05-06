import 'package:foap/helper/date_extension.dart';
import 'package:foap/model/post_model.dart';
import 'package:foap/model/user_model.dart';
// import 'package:timeago/timeago.dart' as timeago;

import '../helper/enum.dart';
import '../helper/localization_strings.dart';
import 'club_model.dart';
import 'competition_model.dart';
import 'package:get/get.dart';

class NotificationModel {
  int id;

  String title;
  String message;

  DateTime date;
  UserModel? actionBy;
  ClubModel? club;
  CompetitionModel? competition;
  PostModel? post;
  SMNotificationType type;
  String notificationDate = earlierString.tr;
  bool readStatus;

  NotificationModel(
      {required this.id,
      required this.title,
      required this.message,
      required this.date,
      required this.type,
      this.readStatus = false,
      this.actionBy,
      this.competition,
      this.post,
      this.club});

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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeValue = _readInt(json["type"]);
    final reference = json["refrenceDetails"] ??
        json["referenceDetails"] ??
        json["reference"] ??
        json["post"];

    return NotificationModel(
      id: _readInt(json["id"]),
      title: (json["title"] ?? '').toString(),
      message: (json["message"] ?? '').toString(),
      date: _readCreatedAt(json['created_at']),
      type: getType(typeValue),
      actionBy: json["createdByUser"] == null
          ? null
          : UserModel.fromJson(json["createdByUser"]),
      competition: typeValue == 4 && reference != null
          ? CompetitionModel.fromJson(reference)
          : null,
      post: typeValue == 2 || typeValue == 3 || typeValue == 7
          ? reference == null
              ? null
              : PostModel.fromJson(reference)
          : null,
      readStatus: _readBool(json["read_status"] ??
          json["readStatus"] ??
          json["is_read"] ??
          json["isRead"] ??
          json["is_read_status"]),

      // club: json["type"] == 11 ? ClubModel.fromJson(json["reference"]) : null,
    );
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  String get notificationTime {
    return date.getTimeAgo;
  }

  static SMNotificationType getType(int type) {
    if (type == 1) {
      return SMNotificationType.follow;
    }
    if (type == 2) {
      return SMNotificationType.comment;
    }
    if (type == 3) {
      return SMNotificationType.like;
    }
    if (type == 4) {
      return SMNotificationType.competitionAdded;
    }
    if (type == 6) {
      return SMNotificationType.supportRequest;
    }
    if (type == 8) {
      return SMNotificationType.gift;
    }
    if (type == 9) {
      return SMNotificationType.verification;
    }
    if (type == 11) {
      return SMNotificationType.clubInvitation;
    }
    if (type == 13) {
      return SMNotificationType.relationInvite;
    }
    if (type == 15) {
      return SMNotificationType.followRequest;
    }
    if (type == 33) {
      return SMNotificationType.subscribed;
    }
    return SMNotificationType.none;
  }
}
