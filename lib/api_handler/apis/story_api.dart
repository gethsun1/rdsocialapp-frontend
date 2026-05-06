import 'package:foap/api_handler/api_wrapper.dart';
import 'package:flutter/foundation.dart';
import '../../model/api_meta_data.dart';
import '../../model/story_model.dart';

class _StoryPagedNode {
  final List items;
  final APIMetaData metaData;

  _StoryPagedNode({required this.items, required this.metaData});
}

class StoryApi {
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

  static _StoryPagedNode _parsePagedNode(
    dynamic data,
    List<String> keys,
    int page,
  ) {
    final fallbackMetaData = _fallbackMetaData(page);
    if (data is! Map) {
      return _StoryPagedNode(items: [], metaData: fallbackMetaData);
    }

    final map = Map<String, dynamic>.from(data);
    for (final key in keys) {
      final node = map[key];
      if (node is Map) {
        final nodeMap = Map<String, dynamic>.from(node);
        final items = nodeMap['items'];
        return _StoryPagedNode(
          items: items is List ? items : [],
          metaData: _parseMetaData(nodeMap['_meta'] ?? nodeMap['meta'], page),
        );
      }
      if (node is List) {
        return _StoryPagedNode(items: node, metaData: fallbackMetaData);
      }
    }

    final directItems = map['items'];
    if (directItems is List) {
      return _StoryPagedNode(
        items: directItems,
        metaData: _parseMetaData(map['_meta'] ?? map['meta'], page),
      );
    }

    return _StoryPagedNode(items: [], metaData: fallbackMetaData);
  }

  static Future<void> postStory(
      {required List<Map<String, String>> gallery,
      required VoidCallback successHandler}) async {
    var url = NetworkConstantsUtil.addStory;

    var param = {
      "stories": gallery,
    };

    await ApiWrapper().postApi(url: url, param: param).then((status) {
      if (status?.success == true) {
        successHandler();
      }
    });
  }

  static Future<void> getMyStories(
      {required Function(List<StoryMediaModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.myStories;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['story', 'stories', 'results'],
          1,
        );
        final stories = _dedupeMedia(List<StoryMediaModel>.from(
            parsed.items.map((x) => StoryMediaModel.fromJson(x))))
          ..sort((a, b) => a.createdAtDate.compareTo(b.createdAtDate));
        _logMediaDiagnostics('my-stories', stories);
        resultCallback(stories);
      }
    });
  }

  static Future<void> getStories(
      {required Function(List<StoryModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.stories;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['story', 'stories', 'results'],
          1,
        );
        final rawStories = List<StoryModel>.from(
            parsed.items.map((x) => StoryModel.fromJson(x)));
        final orderedStories = _groupAndSortStories(rawStories);
        _logStoryDiagnostics('followers-stories', orderedStories);
        resultCallback(orderedStories);
      }
    });
  }

  static Future<void> getMyCurrentActiveStories(
      {required Function(List<StoryMediaModel>) resultCallback}) async {
    var url = NetworkConstantsUtil.myCurrentActiveStories;

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['story', 'stories', 'results'],
          1,
        );

        final stories = _dedupeMedia(List<StoryMediaModel>.from(
            parsed.items.map((x) => StoryMediaModel.fromJson(x))))
          ..sort((a, b) => a.createdAtDate.compareTo(b.createdAtDate));
        _logMediaDiagnostics('my-current-active-stories', stories);

        resultCallback(stories);

        return;
      }
    });
  }

  static Future<void> deleteStory(
      {required int id, required VoidCallback callback}) async {
    var url = NetworkConstantsUtil.deleteStory + id.toString();

    await ApiWrapper().deleteApi(url: url).then((value) {
      callback();
    });
  }

  static Future<void> viewStory({required int storyId}) async {
    var url = NetworkConstantsUtil.viewStory;

    await ApiWrapper()
        .postApi(url: url, param: {'story_id': storyId}).then((result) {});
  }

  static Future<void> getStoryViewers(
      {required int storyId,
      required int page,
      required Function(List<StoryViewerModel>, APIMetaData)
          resultCallback}) async {
    var url = NetworkConstantsUtil.storyViewedByUsers;
    url = url.replaceAll('{{story_id}}', storyId.toString());
    url = '$url&page=$page';
    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final parsed = _parsePagedNode(
          result?.data,
          ['story-view', 'storyView', 'story_view', 'viewers', 'results'],
          page,
        );
        resultCallback(
            List<StoryViewerModel>.from(
                parsed.items.map((x) => StoryViewerModel.fromJson(x))),
            parsed.metaData);
      }
    });
  }

  static Future<void> getStoryDetail(
      {required int storyId,
      required Function(StoryModel) resultCallback}) async {
    var url = '${NetworkConstantsUtil.storyDetail}$storyId';

    await ApiWrapper().getApi(url: url).then((result) {
      if (result?.success == true) {
        final data = result?.data;
        var story = data is Map ? data['story'] ?? data['stories'] : null;
        story ??= data;
        resultCallback(StoryModel.fromJson(story));
      }
    });
  }

  static List<StoryModel> _groupAndSortStories(List<StoryModel> stories) {
    final grouped = <int, StoryModel>{};

    for (final story in stories) {
      for (final media in story.media) {
        final userId = media.userId == 0 ? story.id : media.userId;
        final existing = grouped[userId];
        if (existing == null) {
          grouped[userId] = StoryModel(
            id: userId,
            name: story.name.isNotEmpty ? story.name : media.user?.name ?? '',
            userName: story.userName.isNotEmpty
                ? story.userName
                : media.user?.userName ?? '',
            userImage: story.userImage ?? media.user?.picture,
            media: [media],
          );
        } else {
          if (!_containsSameMedia(existing.media, media)) {
            existing.media.add(media);
          }
          if ((existing.userName).trim().isEmpty) {
            existing.userName = story.userName.isNotEmpty
                ? story.userName
                : media.user?.userName ?? '';
          }
          existing.userImage ??= story.userImage ?? media.user?.picture;
        }
      }
    }

    final ordered =
        grouped.values.where((story) => story.media.isNotEmpty).toList();
    for (final story in ordered) {
      story.media = _dedupeMedia(story.media);
      story.media.sort((a, b) => a.createdAtDate.compareTo(b.createdAtDate));
    }
    ordered.sort((a, b) =>
        b.media.last.createdAtDate.compareTo(a.media.last.createdAtDate));
    return ordered;
  }

  static List<StoryMediaModel> _dedupeMedia(List<StoryMediaModel> media) {
    final seen = <String>{};
    final deduped = <StoryMediaModel>[];
    for (final item in media) {
      final key = _mediaDedupeKey(item);
      if (seen.add(key)) {
        deduped.add(item);
      }
    }
    return deduped;
  }

  static bool _containsSameMedia(
    List<StoryMediaModel> items,
    StoryMediaModel media,
  ) {
    final key = _mediaDedupeKey(media);
    return items.any((item) => _mediaDedupeKey(item) == key);
  }

  static String _mediaDedupeKey(StoryMediaModel media) {
    if (media.mediaUrl.isNotEmpty) {
      return [
        media.userId,
        media.type,
        media.mediaUrl,
      ].join('|');
    }
    if (media.id > 0) return 'id:${media.id}';
    return [
      media.userId,
      media.type,
      media.createdAtDate,
    ].join('|');
  }

  static void _logStoryDiagnostics(String source, List<StoryModel> stories) {
    for (final story in stories) {
      _logMediaDiagnostics(source, story.media, userId: story.id);
    }
  }

  static void _logMediaDiagnostics(
    String source,
    List<StoryMediaModel> media, {
    int? userId,
  }) {
    for (final item in media) {
      debugPrint(
          '[StoryApi][$source] user_id=${userId ?? item.userId}, story_id=${item.id}, media_type=${item.type}, media_url=${item.mediaUrl}, created_at=${item.createdAtDate}');
    }
  }
}
