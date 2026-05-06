class PostGallery {
  int id;
  int postId;
  String fileName;
  String filePath;
  String? videoThumbnail;
  int mediaType; //  image=1, video=2, audio=3
  // int type;
  int currentIndexOfMediaToShow = 0;
  double height;
  double width;

  PostGallery(
      {required this.id,
      required this.fileName,
      required this.filePath,
      required this.postId,
      required this.mediaType,
      required this.height,
      required this.width,
      this.videoThumbnail});

  factory PostGallery.fromJson(dynamic json) {
    int readInt(dynamic value, {int fallback = 0}) {
      if (value == null) return fallback;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString()) ?? fallback;
    }

    double readDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    String readString(List<String> keys) {
      if (json is! Map) return '';
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final text = value.toString();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return '';
    }

    int inferMediaType(int mediaType, String path, String thumbnail) {
      if (mediaType != 0) return mediaType;
      final lowerPath = path.toLowerCase();
      if (thumbnail.isNotEmpty ||
          lowerPath.endsWith('.mp4') ||
          lowerPath.endsWith('.mov') ||
          lowerPath.endsWith('.webm')) {
        return 2;
      }
      if (lowerPath.endsWith('.mp3') ||
          lowerPath.endsWith('.m4a') ||
          lowerPath.endsWith('.wav')) {
        return 3;
      }
      return 1;
    }

    final fileName = readString(['filename', 'file_name', 'name']);
    final filePath = readString(
        ['filenameUrl', 'filePath', 'file_path', 'fileUrl', 'file_url', 'url']);
    final videoThumbnail = readString([
      'videoThumbUrl',
      'video_thumb_url',
      'video_thumbnail',
      'thumbnailUrl',
      'thumbnail_url',
      'thumbnail'
    ]);
    final mediaType = inferMediaType(
        readInt(json is Map ? json['media_type'] ?? json['mediaType'] : null),
        filePath,
        videoThumbnail);

    PostGallery galleryPost = PostGallery(
        id: readInt(json is Map ? json['id'] : null),
        fileName: fileName,
        filePath: filePath,
        postId: readInt(json is Map ? json['post_id'] ?? json['postId'] : null),
        mediaType: mediaType,
        height: readDouble(json is Map ? json['height'] : null),
        width: readDouble(json is Map ? json['width'] : null),

        // type: json['type'],
        videoThumbnail: videoThumbnail.isEmpty ? null : videoThumbnail);

    return galleryPost;
  }

  String get thumbnail {
    return isVideoPost == true ? videoThumbnail ?? filePath : filePath;
  }

  bool get isVideoPost {
    return mediaType == 2 || videoThumbnail != null;
  }

  bool get isAudioPost {
    return mediaType == 3;
  }
}
