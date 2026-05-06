import 'package:foap/helper/date_extension.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/model/setting_model.dart';
import 'package:foap/model/subscription_plan.dart';
import 'package:foap/util/username_validator.dart';
import 'package:intl/intl.dart';
import 'chat_room_model.dart';

class UserModel {
  int id = 0;

  String? name;
  String userName = '';
  UserRole role = UserRole.user;
  String? email = '';
  String? picture;
  String? coverImage;
  DateTime? createdAt;

  String? bio = '';
  String? phone = '';
  String? country = '';
  String? countryCode = '';
  String? city = '';
  String? gender = ''; //sex : 1=male, 2=female, 3=others

  int coins = 0;
  bool? isReported = false;
  String? paypalId;
  String balance = '';
  int? isBioMetricLoginEnabled = 0;

  int commentPushNotificationStatus = 0;
  int likePushNotificationStatus = 0;

  FollowingStatus followingStatus = FollowingStatus.notFollowing;
  bool isFollower = false;
  bool isVerified = false;

  bool isOnline = false;
  int? chatLastTimeOnline = 0;
  int accountCreatedWith = 0;

  int totalPost = 0;
  int totalMentions = 0;

  int totalReels = 0;
  int totalClubs = 0;

  int totalFollowing = 0;
  int totalFollower = 0;
  int totalWinnerPost = 0;

  String? latitude;
  String? longitude;

  UserLiveCallDetail? liveCallDetail;
  GiftSummary? giftSummary;

  // next release
  int isDatingEnabled = 0;
  int chatDeleteTime = 0;

  String? dob;
  String? height;
  String? color;
  String? religion;
  int? maritalStatus;
  int? smoke;
  String? drink;
  String? qualification;
  String? occupation;

  int? experienceYear;
  int? experienceMonth;
  List<InterestModel>? interests;
  List<LanguageModel>? languages;

  int profileCategoryTypeId = 0;
  String profileCategoryTypeName = 'Other';
  List<UserSetting>? userSetting;

  GenderType? genderType;
  bool isPrivate = false;
  bool isShareOnlineStatus = false;
  List<FeatureModel> features = [];

  bool isEligibleForSubscription = false;
  List<SubscriptionPlan> subscriptionPlans = [];
  SubscribedStatus subscribedStatus = SubscribedStatus.notSubscribed;

  UserModel();

  bool get requiresSignupProfileSetup {
    final normalizedUsername = UsernameValidator.normalize(userName);
    final hasProfileImage = (picture ?? '').trim().isNotEmpty;
    final hasCoverImage = (coverImage ?? '').trim().isNotEmpty;
    final hasDateOfBirth = (dob ?? '').trim().isNotEmpty;

    return normalizedUsername.isEmpty ||
        !UsernameValidator.isValid(normalizedUsername) ||
        !hasProfileImage ||
        !hasCoverImage ||
        !hasDateOfBirth;
  }

  static String? _readString(dynamic json, List<String> keys) {
    if (json is! Map) return null;
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return null;
  }

  static int _readInt(dynamic json, List<String> keys, {int fallback = 0}) {
    if (json is! Map) return fallback;
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool _readBool(dynamic json, List<String> keys,
      {bool fallback = false}) {
    if (json is! Map) return fallback;
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value == 1;

      final normalized = value.toString().trim().toLowerCase();
      if (['1', 'true', 'yes'].contains(normalized)) return true;
      if (['0', 'false', 'no'].contains(normalized)) return false;
    }
    return fallback;
  }

  static DateTime? _readDateTime(dynamic json, List<String> keys) {
    if (json is! Map) return null;
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;

      if (value is num) {
        final timestamp = value.toInt();
        final milliseconds =
            timestamp > 1000000000000 ? timestamp : timestamp * 1000;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
      }

      final text = value.toString().trim();
      final numeric = num.tryParse(text);
      if (numeric != null) {
        return _readDateTime({key: numeric}, [key]);
      }

      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return parsed.toLocal();
      }
    }
    return null;
  }

  factory UserModel.fromJson(dynamic json) {
    UserModel model = UserModel();
    if (json is! Map) {
      return model;
    }

    model.id = _readInt(json, ['id', 'user_id', 'userId']);
    model.name = json['name'];
    model.role = _readInt(json, ['role'], fallback: 3) == 3
        ? UserRole.user
        : UserRole.admin;
    model.userName = json['username'] == null
        ? ''
        : json['username'].toString().toLowerCase();
    // model.category = json['category'] ?? 'Other';

    model.email = json['email'];
    model.picture = _readString(json, [
      'picture',
      'avatar_url',
      'avatarUrl',
      'profile_image_url',
      'profileImageUrl',
      'campaginImage'
    ]);
    model.coverImage = _readString(
        json, ['coverImageUrl', 'cover_image_url', 'cover_image', 'coverUrl']);

    model.createdAt = _readDateTime(json,
        ['created_at', 'createdAt', 'date_joined', 'dateJoined', 'joined_at']);
    model.bio =
        _readString(json, ['bio', 'about', 'about_me', 'aboutMe']) ?? '';
    model.followingStatus = json['isFollowing'] == 0
        ? FollowingStatus.notFollowing
        : json['isFollowing'] == 1
            ? FollowingStatus.following
            : FollowingStatus.requested;
    model.isFollower = json['isFollower'] == 1;

    model.latitude = json['latitude'];
    model.longitude = json['longitude'];

    model.phone = json['phone'];
    model.country = json['country'];
    model.countryCode = json['country_code'];
    model.city = json['city'];
    model.gender = json['sex'] == null ? '1' : json['sex'].toString();
    model.genderType = model.gender == '1'
        ? GenderType.male
        : model.gender == '2'
            ? GenderType.female
            : GenderType.other;

    model.totalPost = json['totalActivePost'] ?? json['totalPost'] ?? 0;
    model.totalReels = json['totalReel'] ?? 0;
    model.totalClubs = json['totalClub'] ?? 0;
    model.totalMentions = json['totalMention'] ?? 0;

    model.totalFollower = json['totalFollower'] ?? 0;
    model.totalFollowing = json['totalFollowing'] ?? 0;
    model.coins = json['available_coin'] ?? 0;
    model.totalWinnerPost = json['totalWinnerPost'] ?? 0;

    model.isReported = json['is_reported'] == 1;
    model.isOnline = json['is_chat_user_online'] == 1;
    model.isPrivate = json['profile_visibility'] == 2;
    model.isShareOnlineStatus = json['is_show_online_chat_status'] == 1;

    model.chatLastTimeOnline = json['chat_last_time_online'];
    model.accountCreatedWith = json['account_created_with'] ?? 1;
    model.isVerified =
        _readBool(json, ['is_verified', 'isVerified', 'verified']);
    model.chatDeleteTime =
        json['chat_delete_period'] ?? AppConfigConstants.secondsInADay;

    model.paypalId = json['paypal_id'];
    model.balance = (json['available_balance'] ?? '').toString();
    model.isBioMetricLoginEnabled = json['is_biometric_login'];
    model.commentPushNotificationStatus =
        json['comment_push_notification_status'] ?? 0;
    model.likePushNotificationStatus =
        json['like_push_notification_status'] ?? 0;
    model.liveCallDetail = json['userLiveDetail'] != null
        ? UserLiveCallDetail.fromJson(json['userLiveDetail'])
        : null;
    model.giftSummary = json['giftSummary'] != null
        ? GiftSummary.fromJson(json['giftSummary'])
        : null;

    model.dob =
        json['date_of_birth'] ?? json['dateOfBirth'] ?? json['dob'] ?? '';
    model.height = json['height'] ?? '121.0';
    model.color = json['color'] ?? '';
    model.religion = json['religion'] ?? '';
    model.maritalStatus = json['marital_status'];

    model.smoke = json['smoke_id'];
    model.drink = json['drinking_habit'];

    model.qualification = json['qualification'] ?? '';
    model.occupation = json['occupation'] ?? '';

    model.experienceMonth = json['work_experience_month'];
    model.experienceYear = json['work_experience_year'];

    model.interests = json['interest'] != null
        ? List<InterestModel>.from(
            json['interest'].map((x) => InterestModel.fromJson(x)))
        : null;
    model.languages = json['language'] != null
        ? List<LanguageModel>.from(
            json['language'].map((x) => LanguageModel.fromJson(x)))
        : null;

    model.profileCategoryTypeId = _readInt(json, [
      'profile_category_type',
      'profile_category_type_id',
      'profileCategoryTypeId'
    ]);
    model.profileCategoryTypeName = _readString(json, [
          'profileCategoryName',
          'profile_category_type_name',
          'profile_category_name',
          'categoryName'
        ]) ??
        'Other';

    model.userSetting = json['userSetting'] != null
        ? List<UserSetting>.from(
            json['userSetting'].map((x) => UserSetting.fromJson(x)))
        : null;
    model.features = json["featureList"] == null
        ? []
        : (json["featureList"] as List)
            .map((e) => FeatureModel.fromJson(e))
            .toList();
    return model;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": userName,
        "email": email,
        "picture": picture,
        "bio": bio,
        "phone": phone,
        "country": country,
        "country_code": countryCode,
        "city": city,
        "sex": gender,
        "totalPost": totalPost,
        "available_coin": coins,
        "is_reported": isReported,
        "paypal_id": paypalId,
        "available_balance": balance
      };

  static UserModel placeholderUser() {
    UserModel model = UserModel();
    model.id = 1;
    model.userName = loadingString.tr;
    // model.name = loadingString.tr;
    model.email = loadingString.tr;
    model.picture = loadingString.tr;
    model.bio = loadingString.tr;
    model.followingStatus = FollowingStatus.notFollowing;
    model.isFollower = false;

    model.phone = loadingString.tr;
    model.country = loadingString.tr;
    model.countryCode = loadingString.tr;
    model.city = loadingString.tr;
    model.gender = 'Male';

    model.totalPost = 0;
    model.coins = 0;
    model.isReported = false;
    model.paypalId = loadingString.tr;
    model.balance = loadingString.tr;
    model.isBioMetricLoginEnabled = 0;
    model.commentPushNotificationStatus = 0;
    model.likePushNotificationStatus = 0;

    return model;
  }

  String get getInitials {
    List<String> nameParts = userName.trim().split(' ');
    if (nameParts.length > 1) {
      return nameParts[0].substring(0, 1).toUpperCase() +
          nameParts[1].substring(0, 1).toUpperCase();
    } else {
      if (nameParts[0].isEmpty) {
        return '*';
      }
      return nameParts[0].substring(0, 1).toUpperCase();
    }
  }

  String get lastSeenAtTime {
    if (chatLastTimeOnline == null) {
      return offlineString.tr;
    }

    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(chatLastTimeOnline! * 1000).toUtc();
    // return '${lastSeenString.tr} ${timeago.format(dateTime)}';
    return '${lastSeenString.tr} ${dateTime.getTimeAgo}';
  }

  bool get isMe {
    final UserProfileManager userProfileManager = Get.find();

    return id == userProfileManager.user.value!.id;
  }

  bool get isVIPUser {
    return subscriptionPlans.isNotEmpty;
  }

  bool get canUseDating {
    return gender != null && dob != null && picture != null;
  }

  String get joinedMonthYear {
    if (createdAt == null) return '';
    return DateFormat('MMMM yyyy').format(createdAt!);
  }

  ChatRoomMember get toChatRoomMember {
    return ChatRoomMember(
        id: id, isAdmin: 0, roomId: 0, userDetail: this, userId: id);
  }

  RelationsRevealSetting get relationsRevealSetting {
    if (userSetting == null || (userSetting ?? []).isEmpty) {
      return RelationsRevealSetting.none;
    } else if (userSetting?.first.relationSetting == 1) {
      return RelationsRevealSetting.all;
    } else if (userSetting?.first.relationSetting == 2) {
      return RelationsRevealSetting.followers;
    }
    return RelationsRevealSetting.none;
  }

  bool get canViewRelations {
    if (relationsRevealSetting == RelationsRevealSetting.none) {
      return false;
    } else if (relationsRevealSetting == RelationsRevealSetting.followers &&
        followingStatus == FollowingStatus.following) {
      return true;
    } else {
      return true;
    }
  }
}

class LiveCallHostUser {
  UserModel userDetail;
  bool isMainHost;
  int totalCoins;
  int totalGifts;

  LiveCallHostUser(
      {required this.userDetail,
      required this.isMainHost,
      required this.totalCoins,
      required this.totalGifts});

  factory LiveCallHostUser.fromJson(dynamic json) {
    UserModel user = UserModel();
    user.id = json['userId'];
    user.userName = json['username'] ?? json['userName'];
    user.picture = json['userImageUrl'] ?? 'test';
    LiveCallHostUser model = LiveCallHostUser(
        userDetail: user,
        isMainHost: json['isSuperHost'] == 1,
        totalCoins: json['totalCoin'] ?? 0,
        totalGifts: json['totalGift'] ?? 0);

    return model;
  }
}

class UserLiveCallDetail {
  int id = 0;
  int startTime = 0;
  int? endTime;
  int? totalTime;
  int status = 0;
  String token = '';
  String channelName = '';
  List<UserModel>? host;
  int? totalUsers;

  UserLiveCallDetail();

  factory UserLiveCallDetail.fromJson(dynamic json) {
    UserLiveCallDetail model = UserLiveCallDetail();

    model.id = json['id'];
    model.status = json['status'];
    model.startTime = json['start_time'];
    model.endTime = json['end_time'];
    model.totalTime = json['total_time'];
    model.token = json['token'] ?? '';
    model.channelName = json['channel_name'] ?? '';
    model.totalUsers = json['totalJoinedUsers'] ?? 1;

    if (json['userdetails'] != null) {
      model.host = <UserModel>[];
      json['userdetails'].forEach((v) {
        model.host!.add(UserModel.fromJson(v));
      });
    }
    return model;
  }
}

class GiftSummary {
  int totalGift = 0;
  int totalCoin = 0;

  GiftSummary();

  factory GiftSummary.fromJson(dynamic json) {
    GiftSummary model = GiftSummary();
    model.totalGift = json['totalGift'];
    model.totalCoin = json['totalCoin'];
    return model;
  }
}

class InterestModel {
  int id = 0;
  String name = "";

  InterestModel();

  factory InterestModel.fromJson(dynamic json) {
    InterestModel model = InterestModel();
    model.id = json['id'] ?? json['interest_id'];
    model.name = json['name'];
    return model;
  }
}

class LanguageModel {
  int? id;
  String? name;

  LanguageModel({
    required this.id,
    required this.name,
  });

  factory LanguageModel.fromJson(Map<String, dynamic> json) => LanguageModel(
        id: json["id"] ?? json["language_id"],
        name: json["name"],
      );
}

class UserSetting {
  int? id;
  int? userId;
  int? relationSetting;

  UserSetting({this.id, this.userId, this.relationSetting});

  UserSetting.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    relationSetting = json['relation_setting'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['relation_setting'] = relationSetting;
    return data;
  }
}

class LiveViewer {
  int id;
  int userId;
  int liveId;
  LiveUserRole role;
  bool isBanned;
  int? banType;
  int? totalExpelTime;
  int? expelExpiryTime;
  UserModel user;

  LiveViewer({
    required this.id,
    required this.userId,
    required this.liveId,
    required this.isBanned,
    required this.banType,
    required this.role,
    required this.totalExpelTime,
    required this.expelExpiryTime,
    required this.user,
  });

  factory LiveViewer.fromJson(Map<String, dynamic> json) => LiveViewer(
      id: json['id'],
      userId: json['user_id'],
      liveId: json['live_call_id'],
      isBanned: json['is_ban'] == 1,
      banType: json['ban_type'],
      totalExpelTime: json['total_expel_time'],
      expelExpiryTime: json['expel_expiry_time'],
      role: json['role'] == 1
          ? LiveUserRole.host
          : json['role'] == 3
              ? LiveUserRole.moderator
              : LiveUserRole.viewer,
      user: UserModel.fromJson(json['user']));
}
