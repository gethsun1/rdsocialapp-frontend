import 'package:foap/api_handler/network_constant.dart';
import 'package:foap/model/user_model.dart';
import 'package:foap/util/time_convertor.dart';

class StoryModel {
  int id;

  String name;
  String userName;

  String? userImage;
  List<StoryMediaModel> media;
  bool isViewed = false;

  StoryModel({
    required this.id,
    required this.name,
    required this.userName,
    this.userImage,
    required this.media,
  });

  factory StoryModel.fromJson(dynamic json) {
    if (json is! Map) {
      return StoryModel(id: 0, name: '', userName: '', media: []);
    }

    final userJson = json['user'] ??
        json['createdByUser'] ??
        json['created_by_user'] ??
        json['userDetail'];
    final userMap = userJson is Map ? userJson : null;

    final mediaJson = json['userStory'] ??
        json['user_story'] ??
        json['stories'] ??
        json['story'] ??
        json['items'];
    final mediaItems = mediaJson is List
        ? mediaJson
        : (json['media_url'] != null ||
                json['mediaUrl'] != null ||
                json['image'] != null ||
                json['imageUrl'] != null ||
                json['video'] != null ||
                json['videoUrl'] != null)
            ? [json]
            : <dynamic>[];

    StoryModel model = StoryModel(
      id: StoryMediaModel.readInt(json['id'] ?? userMap?['id']),
      name: (json['name'] ?? userMap?['name'] ?? '').toString(),
      userName: (json['username'] ?? userMap?['username'] ?? '').toString(),
      userImage: (json['picture'] ??
              json['imageUrl'] ??
              userMap?['picture'] ??
              userMap?['imageUrl'])
          ?.toString(),
      media: mediaItems
          .map((e) => StoryMediaModel.fromJson(e, parentJson: json))
          .where((e) => e.mediaUrl.isNotEmpty)
          .toList()
        ..sort((a, b) => a.createdAtDate.compareTo(b.createdAtDate)),
    );

    return model;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "username": userName,
        "picture": userImage,
        "userStory": media.map((e) => e.toJson()).toList()
      };
}

class StoryMediaModel {
  int id;
  int userId;

  String? description;

  String? bgColor;
  String? video;
  String? image;
  String? imageName;
  int createdAtDate;
  int? videoDuration;
  String createdAt;
  int type;
  UserModel? user;
  int totalView;

  StoryMediaModel(
      {required this.id,
      required this.userId,
      required this.description,
      required this.bgColor,
      required this.video,
      required this.image,
      required this.imageName,
      required this.createdAtDate,
      required this.createdAt,
      required this.type,
      required this.user,
      required this.totalView,
      this.videoDuration});

  factory StoryMediaModel.fromJson(dynamic json, {dynamic parentJson}) {
    if (json is! Map) {
      return StoryMediaModel(
          id: 0,
          userId: 0,
          description: '',
          bgColor: '',
          video: '',
          image: '',
          imageName: '',
          createdAtDate: 0,
          createdAt: '',
          type: 2,
          user: null,
          totalView: 0);
    }

    final userJson = json['user'] ??
        parentJson?['user'] ??
        json['createdByUser'] ??
        parentJson?['createdByUser'] ??
        json['created_by_user'] ??
        parentJson?['created_by_user'] ??
        json['userDetail'];
    final user = userJson == null ? null : UserModel.fromJson(userJson);
    final createdAt = readDateTime(json['created_at'] ??
            json['createdAt'] ??
            parentJson?['created_at'] ??
            parentJson?['createdAt'] ??
            json['created_at_str']) ??
        DateTime.now().toUtc();
    final mediaUrl = normalizeMediaUrl(json['media_url'] ?? json['mediaUrl']);
    final mediaTypeValue =
        json['media_type'] ?? json['mediaType'] ?? json['type'];
    final parsedType = readMediaType(
      mediaTypeValue,
      mediaUrl: mediaUrl,
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? json['image'],
      videoUrl: json['videoUrl'] ?? json['video_url'] ?? json['video'],
    );
    final parsedVideo = normalizeMediaUrl(
      json['videoUrl'] ?? json['video_url'] ?? json['video'],
    );
    final parsedImage = normalizeMediaUrl(
      json['imageUrl'] ?? json['image_url'] ?? json['image'],
    );

    StoryMediaModel model = StoryMediaModel(
        id: readInt(json['id']),
        userId: readInt(
            json['user_id'] ?? json['userId'] ?? parentJson?['user_id'],
            fallback: user?.id ?? 0),
        description: json['description']?.toString(),
        bgColor: json['background_color']?.toString(),
        video: parsedType == 3
            ? (parsedVideo.isNotEmpty ? parsedVideo : mediaUrl)
            : '',
        videoDuration: readInt(json['video_time'] ?? json['videoTime']),
        imageName: json['image']?.toString(),
        image: parsedType == 3
            ? parsedImage
            : (parsedImage.isNotEmpty ? parsedImage : mediaUrl),
        createdAtDate: createdAt.millisecondsSinceEpoch,
        createdAt: TimeAgo.timeAgoSinceDate(createdAt),
        type: parsedType,
        totalView: readInt(json['totalView'] ?? json['total_view']),
        user: user);

    return model;
  }

  static int readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static String readString(dynamic value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  static String normalizeMediaUrl(dynamic value) {
    final url = readString(value);
    if (url.isEmpty ||
        url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('assets/')) {
      return url;
    }

    final baseUrl = NetworkConstantsUtil.baseUrl;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = url.startsWith('/') ? url : '/$url';
    return '$normalizedBase$normalizedPath';
  }

  static int readMediaType(
    dynamic value, {
    required String mediaUrl,
    dynamic imageUrl,
    dynamic videoUrl,
  }) {
    final parsed = readInt(value, fallback: 0);
    if (parsed == 2 || parsed == 3) return parsed;

    final normalized = (value ?? '').toString().trim().toLowerCase();
    if (normalized == 'video' || normalized == 'videos') return 3;
    if (normalized == 'image' ||
        normalized == 'photo' ||
        normalized == 'picture') {
      return 2;
    }

    if (readString(videoUrl).isNotEmpty) return 3;
    if (readString(imageUrl).isNotEmpty) return 2;

    final uri = mediaUrl.toLowerCase();
    if (uri.endsWith('.mp4') ||
        uri.endsWith('.mov') ||
        uri.endsWith('.m4v') ||
        uri.endsWith('.webm')) {
      return 3;
    }
    return 2;
  }

  static DateTime? readDateTime(dynamic value) {
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
      return readDateTime(numeric);
    }
    return DateTime.tryParse(text)?.toUtc();
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "user_id": userId,
        "description": description,
        "background_color": bgColor,
        "videoUrl": video,
        "video_time": videoDuration,
        "image": imageName,
        "imageUrl": image,
        "created_at": createdAtDate,
        "type": type,
        "totalView": totalView,
        // "user": user!.toJson(),
      };

  bool isVideoPost() {
    return type == 3;
  }

  String get mediaUrl => isVideoPost() ? (video ?? '') : (image ?? '');
}

class StoryViewerModel {
  String viewedAt = '';
  UserModel? user;

  StoryViewerModel();

  factory StoryViewerModel.fromJson(dynamic json) {
    StoryViewerModel model = StoryViewerModel();
    if (json is! Map) return model;

    final userJson = json['user'] ?? json['createdByUser'] ?? json['viewer'];
    if (userJson != null) {
      model.user = UserModel.fromJson(userJson);
    }
    final viewedAt = StoryMediaModel.readDateTime(
        json['created_at'] ?? json['createdAt'] ?? json['viewed_at']);
    model.viewedAt = viewedAt == null ? '' : TimeAgo.timeAgoSinceDate(viewedAt);

    return model;
  }
}
