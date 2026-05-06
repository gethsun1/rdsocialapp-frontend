import 'package:foap/helper/date_extension.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:foap/model/post_gallery.dart';
import '../helper/enum_linking.dart';
import '../screens/add_on/model/reel_music_model.dart';
import 'club_model.dart';
import 'collaboration_model.dart';
import 'competition_model.dart';

class PostModel {
  int id = 0;
  String title = '';

  late UserModel user;
  int? competitionId = 0;

  int totalView = 0;
  int totalLike = 0;
  int totalComment = 0;
  int totalShare = 0;
  int isWinning = 0;
  bool isLike = false;
  bool isSaved = false;
  bool commentsEnabled = true;
  int type = 1;

  bool isReported = false;
  bool isSharePost = false;
  bool isReposted = false;
  bool isArchived = false;

  List<PostGallery> gallery = [];
  List<String> tags = [];
  List<MentionedUsers> mentionedUsers = [];

  ReelMusicModel? audio;
  ClubModel? postedInClub;
  CompetitionModel? competition;
  ClubModel? createdClub;

  String postTime = '';
  DateTime? createDate;
  PostModel? sharedPost;
  String shareLink = '';
  PostContentType contentType = PostContentType.text;
  List<CollaborationModel> collaborations = [];

  int? pinId;

  bool isPinned = false;

  PostModel();

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
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

  static DateTime? _readCreatedAt(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      final timestamp = value.toInt();
      final milliseconds =
          timestamp > 1000000000000 ? timestamp : timestamp * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds).toUtc();
    }

    final text = value.toString().trim();
    final numeric = num.tryParse(text);
    if (numeric != null) {
      return _readCreatedAt(numeric);
    }

    return DateTime.tryParse(text)?.toUtc();
  }

  factory PostModel.fromJson(dynamic json) {
    PostModel model = PostModel();
    if (json is! Map) {
      return model;
    }

    model.id = _readInt(json['id']);
    model.title = json['title'] ?? json['content'] ?? 'No title';
    model.type = _readInt(json['type'], fallback: 1);

    final userJson = json['user'] ??
        json['createdByUser'] ??
        json['userDetail'] ??
        json['created_by_user'];
    model.user = userJson == null ? UserModel() : UserModel.fromJson(userJson);
    model.competitionId = json['competition_id'];
    model.totalView = _readInt(json['total_view'] ?? json['totalView']);
    model.totalLike = _readInt(json['total_like'] ?? json['totalLike']);
    model.totalComment =
        _readInt(json['total_comment'] ?? json['totalComment']);
    model.totalShare = _readInt(json['total_share'] ?? json['totalShare']);
    model.isWinning = _readInt(json['is_winning'] ?? json['isWinning']);

    model.isLike = _readBool(json['is_like'] ?? json['isLike']);
    model.isReported = _readBool(json['is_reported'] ?? json['isReported']);
    model.isSharePost = _readBool(json['is_share_post'] ?? json['isSharePost']);
    model.isArchived = _readBool(json['is_archive'] ??
        json['isArchive'] ??
        json['is_archived'] ??
        json['isArchived'] ??
        json['archived']);
    model.isReposted = _readBool(json['is_reposted'] ??
        json['isReposted'] ??
        json['is_reshared'] ??
        json['isReshared'] ??
        json['has_reposted'] ??
        json['hasReposted'] ??
        json['has_reshared'] ??
        json['hasReshared']);
    model.isSaved = _readBool(json['isFavorite'] ?? json['is_favorite']);
    model.commentsEnabled = _readBool(
        json['is_comment_enable'] ?? json['isCommentEnable'],
        fallback: true);
    model.shareLink = json['share_link'] ?? json['shareLink'] ?? '';
    final postContentType =
        json['post_content_type'] ?? json['postContentType'];
    model.contentType = postContentType == null
        ? PostContentType.text
        : postContentTypeValueFrom(_readInt(postContentType));

    if (model.contentType == PostContentType.competitionAdded ||
        model.contentType == PostContentType.competitionResultDeclared) {
      model.competition =
          CompetitionModel.fromJson(json['contentReferenceDetail']);
    }
    if (model.contentType == PostContentType.club) {
      json['contentReferenceDetail']['createdByUser'] = json['user'];
      model.createdClub = ClubModel.fromJson(json['contentReferenceDetail']);
    }
    model.tags = [];
    if (json['hashtags'] != null && json['hashtags'].length > 0) {
      model.tags = List<String>.from(json['hashtags'].map((x) => '#$x'));
    }

    final galleryJson = json['postGallary'] ??
        json['postGallery'] ??
        json['gallery'] ??
        json['gallary'];
    if (galleryJson is List && galleryJson.isNotEmpty) {
      model.gallery = List<PostGallery>.from(
          galleryJson.map((x) => PostGallery.fromJson(x)));
    }

    if (json['mentionUsers'] != null && json['mentionUsers'].length > 0) {
      model.mentionedUsers = List<MentionedUsers>.from(
          json['mentionUsers'].map((x) => MentionedUsers.fromJson(x)));
    }
    if (json['collaborate'] != null && json['collaborate'].length > 0) {
      model.collaborations = List<CollaborationModel>.from(
          json['collaborate'].map((x) => CollaborationModel.fromJson(x)));
    }
    model.createDate = _readCreatedAt(json['created_at']) ??
        _readCreatedAt(json['created_at_str']) ??
        DateTime.now().toUtc();

    model.postTime = model.createDate != null
        ? model.createDate!.getTimeAgo
        : justNowString.tr;
    model.audio =
        json['audio'] == null ? null : ReelMusicModel.fromJson(json['audio']);
    model.postedInClub = json['clubDetail'] == null
        ? null
        : ClubModel.fromJson(json['clubDetail']);
    final originPostJson = json['originPost'] ??
        json['origin_post'] ??
        json['originalPost'] ??
        json['original_post'] ??
        json['sharedPost'] ??
        json['shared_post'] ??
        (model.type == postTypeValueFrom(PostType.reshare)
            ? json['contentReferenceDetail']
            : null);
    model.sharedPost =
        originPostJson == null ? null : PostModel.fromJson(originPostJson);
    final pinJson = json['isPin'] ?? json['is_pin'] ?? json['pin'];
    if (pinJson is Map) {
      model.pinId = _readInt(pinJson['id'], fallback: 0);
      if (model.pinId == 0) {
        model.pinId = null;
      }
      model.isPinned = true;
    } else {
      model.pinId = null;
      model.isPinned =
          _readBool(json['isPinned'] ?? json['is_pinned'] ?? json['pinned']);
    }
    return model;
  }

  bool get containVideoPost {
    return gallery.where((element) => element.isVideoPost).isNotEmpty;
  }

  bool get isMyPost {
    final UserProfileManager userProfileManager = Get.find();

    return user.id == userProfileManager.user.value!.id;
  }

  bool get isEditable {
    if (!isMyPost || createDate == null) {
      return false;
    }

    final minutesSincePosting =
        DateTime.now().toUtc().difference(createDate!).inMinutes;
    return minutesSincePosting < 60;
  }

  bool get isReel {
    return type == 4;
  }

  bool get amICollaborator {
    return collaborations
        .where(
            (e) => e.user!.isMe && e.status == CollaborationStatusType.accepted)
        .isNotEmpty;
  }

  bool get isPendingCollaborationRequest {
    return collaborations
        .where(
            (e) => e.user!.isMe && e.status == CollaborationStatusType.pending)
        .isNotEmpty;
  }

  List<CollaborationModel> get activeCollaborations {
    return collaborations
        .where((e) => e.status == CollaborationStatusType.accepted)
        .toList();
  }

  CollaborationModel get myCollaboration {
    return collaborations.where((e) => e.user!.isMe).first;
  }

  void removeMyCollaboration() {
    CollaborationModel collaboration =
        collaborations.where((e) => e.user!.isMe).first;
    collaboration.status = CollaborationStatusType.cancelled;
  }

  void acceptMyCollaboration() {
    CollaborationModel collaboration =
        collaborations.where((e) => e.user!.isMe).first;
    collaboration.status = CollaborationStatusType.accepted;
  }

  void removeCollaboration(CollaborationModel collaboration) {
    CollaborationModel matchedCollaboration =
        collaborations.where((e) => e.id == collaboration.id).first;
    matchedCollaboration.status = CollaborationStatusType.cancelled;
  }

  String get postTitle {
    if (contentType == PostContentType.text ||
        contentType == PostContentType.media ||
        contentType == PostContentType.location ||
        contentType == PostContentType.poll) {
      return title;
    } else if (contentType == PostContentType.competitionAdded) {
      return '${user.name!} ${addedNewCompetitionString.tr} ${competition!.title}';
    } else if (contentType == PostContentType.club) {
      return '${user.name!} ${createdAClubString.tr} ${createdClub!.name!}';
    }
    return '';
  }
}

class MentionedUsers {
  int id = 0;
  String userName = '';

  MentionedUsers();

  factory MentionedUsers.fromJson(dynamic json) {
    MentionedUsers model = MentionedUsers();
    model.id = json['user_id'];
    model.userName = json['username'].toString().toLowerCase();
    return model;
  }
}

class PostInsight {
  int totalView;
  int totalImpression;
  int totalShare;

  int viewFromFollowers;
  int viewFromNonFollowers;
  int viewFromMale;
  int viewFromFemale;
  int viewFromOther;
  int viewFromGenderNotDisclosed;
  int viewFromCountryNotDisclosed;
  int viewFromProfileCategoryNotDisclosed;
  int viewFromAgeNotDisclosed;
  int profileViewFromPost;
  int followFromPost;

  PostInsight({
    required this.totalView,
    required this.totalImpression,
    required this.totalShare,
    required this.viewFromFollowers,
    required this.viewFromNonFollowers,
    required this.viewFromMale,
    required this.viewFromFemale,
    required this.viewFromOther,
    required this.viewFromGenderNotDisclosed,
    required this.viewFromCountryNotDisclosed,
    required this.viewFromProfileCategoryNotDisclosed,
    required this.viewFromAgeNotDisclosed,
    required this.profileViewFromPost,
    required this.followFromPost,
  });

  factory PostInsight.fromJson(dynamic json) => PostInsight(
      totalView: json['total_view'],
      totalImpression: json['total_impression'],
      totalShare: json['total_share'] ?? 0,
      viewFromFollowers: json['follower'],
      viewFromNonFollowers: json['nonfollower'],
      viewFromMale: json['male'],
      viewFromFemale: json['female'],
      viewFromOther: json['other'],
      viewFromGenderNotDisclosed: json['gender_not_disclose'],
      viewFromCountryNotDisclosed: json['country_not_disclose'],
      viewFromProfileCategoryNotDisclosed:
          json['profile_category_type_not_disclose'],
      viewFromAgeNotDisclosed: json['age_not_disclose'],
      profileViewFromPost: json['profile_view'],
      followFromPost: json['follow_by_post']);
}
