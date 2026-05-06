import 'package:foap/helper/date_extension.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:intl/intl.dart';

class CallHistoryModel {
  int id;
  int status;
  int callerId;
  int startTime;
  int endTime;
  int callTime;
  int callType;
  UserModel callerDetail;
  UserModel receiverDetail;

  CallHistoryModel({
    required this.id,
    required this.status,
    required this.startTime,
    required this.callerId,
    required this.endTime,
    required this.callTime,
    required this.callType,
    required this.callerDetail,
    required this.receiverDetail,
  });

  factory CallHistoryModel.fromJson(dynamic json) {
    final map = json is Map ? Map<String, dynamic>.from(json) : {};
    int readInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    UserModel readUser(List<String> keys, int fallbackId) {
      for (final key in keys) {
        final value = map[key];
        if (value is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(value));
        }
      }
      final user = UserModel();
      user.id = fallbackId;
      return user;
    }

    final callerId = readInt(map['caller_id'] ?? map['callerId']);
    final receiverId = readInt(map['receiver_id'] ?? map['receiverId']);

    return CallHistoryModel(
      id: readInt(map['id'] ?? map['callId'] ?? map['call_id']),
      status: readInt(map['status']),
      startTime: readInt(map['start_time'] ??
          map['startTime'] ??
          map['created_at'] ??
          map['createdAt']),
      endTime: readInt(map['end_time'] ?? map['endTime']),
      callTime: readInt(map['total_time'] ??
          map['totalTime'] ??
          map['call_time'] ??
          map['callTime']),
      callerId: callerId,
      callType: readInt(map['call_type'] ?? map['callType']),
      callerDetail:
          readUser(['callerDetail', 'caller_detail', 'caller'], callerId),
      receiverDetail: readUser(
          ['receiverDetail', 'receiver_detail', 'receiver'], receiverId),
    );
  }

  UserModel get opponent {
    final UserProfileManager userProfileManager = Get.find();

    if (callerDetail.id == userProfileManager.user.value!.id) {
      return receiverDetail;
    }
    return callerDetail;
  }

  bool get isMissedCall {
    return isOutgoing == false && (status == 1 || status == 2 || status == 3);
  }

  bool get isOutgoing {
    final UserProfileManager userProfileManager = Get.find();

    return callerDetail.id == userProfileManager.user.value!.id;
  }

  String get timeOfCall {
    DateTime callStartTime =
        DateTime.fromMillisecondsSinceEpoch(startTime * 1000);

    if (DateTime.now().isSameDate(callStartTime)) {
      String formattedTime = DateFormat('hh:mm a').format(callStartTime);
      return formattedTime;
    }

    int callStartDay = int.parse(DateFormat('d').format(callStartTime));
    int today = int.parse(DateFormat('d').format(DateTime.now()));

    if (callStartDay - today == 1 || callStartDay - today == -1) {
      return yesterdayString.tr;
    } else if (DateTime.now().difference(callStartTime).inDays < 7) {
      return DateFormat('EEEE').format(callStartTime);
    }

    return DateFormat('dd-MM-yyyy').format(callStartTime);
  }

  String get duration {
    int min = callTime ~/ 60;
    int sec = callTime % 60;

    String parsedTime =
        "${getParsedTime(min.toString())}:${getParsedTime(sec.toString())}";

    return parsedTime;
  }

  String getParsedTime(String time) {
    if (time.length <= 1) return "0$time";
    return time;
  }
}
