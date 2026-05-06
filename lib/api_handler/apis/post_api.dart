import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../helper/enum.dart';
import '../../helper/enum_linking.dart';
import '../../helper/localization_strings.dart';
import '../../model/api_meta_data.dart';
import '../../model/comment_model.dart';
import '../../model/location.dart';
import '../../model/post_model.dart';
import '../../model/user_model.dart';
import '../../util/app_util.dart';
import '../api_wrapper.dart';

class _PostsParseResult {
  final List<PostModel> posts;
  final APIMetaData metaData;

  _PostsParseResult({required this.posts, required this.metaData});
}

class _PagedNode {
  final List items;
  final APIMetaData metaData;

  _PagedNode({required this.items, required this.metaData});
}

class PostApi {
  static int? _readNullableId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int? _extractCreatedPostId(dynamic data) {
    if (data is! Map) return null;

    final map = Map<String, dynamic>.from(data);
    final directId = _readNullableId(
      map['post_id'] ?? map['postId'] ?? map['id'] ?? map['postID'],
    );
    if (directId != null) return directId;

    final post = map['post'];
    if (post is Map) {
      return _readNullableId(post['id'] ?? post['post_id'] ?? post['postId']);
    }

    return null;
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

  static List<PostModel> _parsePostItems(dynamic value) {
    if (value is! List) return [];

    final posts = <PostModel>[];
    for (final item in value) {
      try {
        posts.add(PostModel.fromJson(_extractPostJson(item)));
      } catch (error) {
        debugPrint('[PostApi] Skipping post that failed to parse: $error');
      }
    }
    return posts;
  }

  static dynamic _extractPostJson(dynamic item) {
    if (item is! Map) return item;
    final map = Map<String, dynamic>.from(item);
    return map['post'] ??
        map['postDetail'] ??
        map['post_detail'] ??
        map['referenceDetails'] ??
        map['referenceDetail'] ??
        map['reference_details'] ??
        map['reference'] ??
        item;
  }

  static _PostsParseResult _parsePostsResponse(
    ApiResponse? response,
    int page,
  ) {
    final data = response?.data;
    if (data is! Map) {
      return _PostsParseResult(
          posts: <PostModel>[], metaData: _fallbackMetaData(page));
    }

    final parsed = _parsePagedNode(
      data,
      [
        'post',
        'posts',
        'favorite',
        'favorites',
        'favourite',
        'favourites',
        'results',
      ],
      page,
    );

    if (parsed.items.isEmpty) {
      return _PostsParseResult(
          posts: <PostModel>[], metaData: _fallbackMetaData(page));
    }

    return _PostsParseResult(
      posts: _parsePostItems(parsed.items),
      metaData: parsed.metaData,
    );
  }

  static _PagedNode _parsePagedNode(
    dynamic data,
    List<String> keys,
    int page,
  ) {
    final fallbackMetaData = _fallbackMetaData(page);
    if (data is! Map) {
      return _PagedNode(items: [], metaData: fallbackMetaData);
    }

    final map = Map<String, dynamic>.from(data);
    for (final key in keys) {
      final node = map[key];
      if (node is Map) {
        final nodeMap = Map<String, dynamic>.from(node);
        final items = nodeMap['items'];
        return _PagedNode(
          items: items is List ? items : [],
          metaData: _parseMetaData(nodeMap['_meta'] ?? nodeMap['meta'], page),
        );
      }
      if (node is List) {
        return _PagedNode(items: node, metaData: fallbackMetaData);
      }
    }

    final directItems = map['items'];
    if (directItems is List) {
      return _PagedNode(
        items: directItems,
        metaData: _parseMetaData(map['_meta'] ?? map['meta'], page),
      );
    }

    return _PagedNode(items: [], metaData: fallbackMetaData);
  }

  static Future<void> addPost(
      {required PostType postType,
      required String title,
      required List<Map<String, String>> gallery,
      required bool allowComments,
      required PostContentType postContentType,
      LocationModel? location,
      String? hashTag,
      String? mentions,
      int? competitionId,
      int? clubId,
      int? sharingPostId,
      int? audioId,
      int? contentRefId,
      double? audioStartTime,
      double? audioEndTime,
      bool? addToPost,
      required Function(int?) resultCallback}) async {
    var url = competitionId == null
        ? NetworkConstantsUtil.addPost
        : NetworkConstantsUtil.addCompetitionPost;

    var parameters = {
      "origin_post_id": sharingPostId,
      "type": postTypeValueFrom(postType).toString(),
      "title": title,
      "hashtag": hashTag,
      "mentionUser": mentions,
      "gallary": gallery,
      "gallery": gallery,
      'competition_id': competitionId,
      'content_type_reference_id': contentRefId,
      'club_id': clubId,
      'post_content_type': postContentTypeIdFrom(postContentType).toString(),
      'audio_id': audioId,
      'audio_start_time': audioStartTime,
      'audio_end_time': audioEndTime,
      'is_add_to_post': addToPost == true ? 1 : 0,
      'is_comment_enable': allowComments == true ? 1 : 0,
      'latitude': location == null ? '' : location.latitude.toString(),
      'longitude': location == null ? '' : location.longitude.toString(),
      'address': location == null ? '' : location.name.toString()
    };

    await ApiWrapper().postApi(url: url, param: parameters).then((result) {
      if (result?.success == true) {
        resultCallback(_extractCreatedPostId(result!.data) ?? 0);
      } else {
        if (result?.message != null && result!.message!.isNotEmpty) {
          AppUtil.showToast(message: result.message!, isSuccess: false);
        }
        resultCallback(null);
      }
    });
  }

  static Future<void> updatePost(
      {required int postId,
      required String title,
      required bool allowComments,
      required VoidCallback successHandler}) async {
    var url = '${NetworkConstantsUtil.editPost}$postId';

    var parameters = {
      "title": title,
      'is_comment_enable': allowComments == true ? 1 : 0
    };

    await ApiWrapper().putApi(url: url, param: parameters).then((result) {
      if (result?.success == true) {
        successHandler();
      }
    });
  }

  static Future<void> getPosts(
      {int? userId,
      int? isPopular,
      int? isFollowing,
      int? clubId,
      int? isSold,
      int? isReel,
      int? audioId,
      int? isMine,
      int? isSaved,
      int? isArchived,
      int? isVideo,
      int? isRecent,
      String? title,
      String? hashtag,
      int page = 0,
      required Function(List<PostModel>, APIMetaData) resultCallback}) async {
    var url = NetworkConstantsUtil.searchPost;

    if (userId != null) {
      url = '$url&user_id=$userId';
    }
    if (isPopular != null) {
      url = '$url&is_popular_post=$isPopular';
    }
    if (title != null) {
      url = '$url&title=$title';
    }
    if (isRecent != null) {
      url = '$url&is_recent=$isRecent';
    }
    if (isFollowing != null) {
      url = '$url&is_following_user_post=$isFollowing';
    }
    if (isMine != null) {
      url = '$url&is_my_post=$isMine';
    }
    if (isSold != null) {
      url = '$url&is_winning_post=$isSold';
    }
    if (hashtag != null) {
      url = '$url&hashtag=$hashtag';
    }
    if (clubId != null) {
      url = '$url&club_id=$clubId';
    }
    if (isReel != null) {
      url = '$url&is_reel=$isReel';
    }
    if (audioId != null) {
      url = '$url&audio_id=$audioId';
    }
    if (isSaved != null) {
      url = '$url&is_favorite=1&isFavorite=1';
    }
    if (isArchived != null) {
      url = '$url&is_archive=$isArchived&is_archived=$isArchived';
    }
    if (isVideo != null) {
      url = '$url&is_video_post=1';
    }
    url = '$url&page=$page';
    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper().getApi(url: url).then((response) {
      EasyLoading.dismiss();

      final parsed = _parsePostsResponse(response, page);
      final posts = isArchived == null
          ? parsed.posts.where((post) => !post.isArchived).toList()
          : parsed.posts
              .where((post) => post.isArchived == (isArchived == 1))
              .toList();
      resultCallback(posts, parsed.metaData);
    });
  }

  static Future<void> getMentionedPosts(
      {int? userId,
      int page = 1,
      required Function(List<PostModel>, APIMetaData) resultCallback}) async {
    var url = '${NetworkConstantsUtil.mentionedPosts}$userId&page=$page';

    EasyLoading.show(status: loadingString.tr);

    await ApiWrapper().getApi(url: url).then((response) {
      EasyLoading.dismiss();

      final parsed = _parsePostsResponse(response, page);
      resultCallback(parsed.posts, parsed.metaData);
    });
  }

  static Future<void> getPostDetail(int id,
      {required Function(PostModel?) resultCallback}) async {
    var url = NetworkConstantsUtil.postDetail;
    url = url.replaceAll('{id}', id.toString());
    await ApiWrapper().getApi(url: url).then((response) {
      if (response?.success == true) {
        var post = response!.data['post'];
        resultCallback(PostModel.fromJson(post));
      } else {
        resultCallback(null);
      }
    });
  }

  static Future<void> getPostDetailByUniqueId(String id,
      {required Function(PostModel?) resultCallback}) async {
    var url = NetworkConstantsUtil.postDetailByUniqueId;
    url =
        '$url$id&expand=user,user.userLiveDetail,clubDetail,audio,giftSummary,clubDetail.createdByUser';
    await ApiWrapper().getApi(url: url).then((response) {
      if (response?.success == true) {
        var post = response!.data['post'];
        if (post != null) {
          resultCallback(PostModel.fromJson(post));
        } else {
          resultCallback(null);
        }
      } else {}
    });
  }

  static Future<void> getComments(
      {required int postId,
      int? parentId,
      required int page,
      required Function(List<CommentModel>, APIMetaData)
          resultCallback}) async {
    var url = NetworkConstantsUtil.getComments;
    if (parentId != null) {
      url =
          '$url?expand=user,isLike&post_id=$postId&parent_id=$parentId&page=$page';
    } else {
      url =
          '$url?expand=user,isLike,totalChildComment,childCommentDetail.isLike,childCommentDetail.user&post_id=$postId&page=$page';
    }

    await ApiWrapper().getApi(url: url).then((response) {
      final parsed = _parsePagedNode(
        response?.data,
        ['comment', 'comments', 'postComment', 'results'],
        page,
      );
      resultCallback(
        List<CommentModel>.from(
            parsed.items.map((x) => CommentModel.fromJson(x))),
        parsed.metaData,
      );
    });
  }

  static Future<void> postComment(
      {required int postId,
      int? parentCommentId,
      required CommentType? type,
      required Function(int) resultCallback,
      String? comment,
      String? filename}) async {
    var url = NetworkConstantsUtil.addComment;

    await ApiWrapper().postApi(url: url, param: {
      "post_id": postId.toString(),
      "parent_id": parentCommentId ?? 0,
      'comment': comment ?? '',
      "type": type == CommentType.gif
          ? '4'
          : type == CommentType.video
              ? '3'
              : type == CommentType.image
                  ? '2'
                  : '1',
      "filename": filename ?? ''
    }).then((response) {
      if (response?.success == true) {
        final data = response!.data;
        final id = data is Map
            ? data['id'] ??
                data['comment_id'] ??
                (data['comment'] is Map ? data['comment']['id'] : null)
            : null;

        resultCallback(_readId(id));
      }
    });
  }

  static int _readId(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Future<void> deleteComment(
      {required int commentId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.deleteComment + commentId.toString();

    await ApiWrapper().deleteApi(url: url).then((value) {
      resultCallback();
    });
  }

  static Future<void> reportComment(
      {required int commentId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.reportComment;

    await ApiWrapper().postApi(
        url: url,
        param: {"post_comment_id": commentId.toString()}).then((value) {
      resultCallback();
    });
  }

  static Future<void> favComment(
      {required int commentId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.likeComment;

    await ApiWrapper().postApi(url: url, param: {
      "comment_id": commentId.toString(),
      "source_type": "1"
    }).then((value) {
      resultCallback();
    });
  }

  static Future<void> unfavComment(
      {required int commentId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.unLikeComment;

    await ApiWrapper().postApi(url: url, param: {
      "comment_id": commentId.toString(),
      "source_type": "1"
    }).then((value) {
      resultCallback();
    });
  }

  static Future<void> reportPost(
      {required int postId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.reportPost;

    await ApiWrapper()
        .postApi(url: url, param: {"post_id": postId.toString()}).then((value) {
      resultCallback();
    });
  }

  static Future<void> deletePost(
      {required int postId, required VoidCallback resultCallback}) async {
    var url = NetworkConstantsUtil.deletePost;
    url = url.replaceAll('{{id}}', postId.toString());

    await ApiWrapper().deleteApi(url: url).then((value) {
      resultCallback();
    });
  }

  static Future<ApiResponse?> archiveUnarchivePost(
      {required bool archive, required int postId}) async {
    final url = archive
        ? NetworkConstantsUtil.archivePost
        : NetworkConstantsUtil.unarchivePost;

    return ApiWrapper()
        .postApi(url: url, param: {"post_id": postId.toString()});
  }

  static Future<void> getPostInsight(int id,
      {required Function(PostInsight) resultCallback}) async {
    var url = '${NetworkConstantsUtil.postInsight}$id';
    await ApiWrapper().getApi(url: url).then((response) {
      if (response?.success == true) {
        resultCallback(PostInsight.fromJson(response!.data['insight']));
      }
    });
  }

  static Future<void> likeUnlikePost(
      {required bool like, required int postId}) async {
    var url = (like
        ? NetworkConstantsUtil.likePost
        : NetworkConstantsUtil.unlikePost);

    await ApiWrapper().postApi(
        url: url, param: {"post_id": postId.toString()}).then((value) {});
  }

  static Future<void> postLikedByUsers(
      {required int postId,
      required int page,
      required Function(List<UserModel>, APIMetaData) resultCallback}) async {
    var url = NetworkConstantsUtil.postLikedByUsers
        .replaceAll('{{post_id}}', postId.toString());

    url = '$url&page=$page';

    await ApiWrapper().getApi(url: url).then((response) {
      if (response?.success == true) {
        var items = response!.data['results']['items'];
        resultCallback(
            List<UserModel>.from(
                items.map((x) => UserModel.fromJson(x['user']))),
            APIMetaData.fromJson(response.data['results']['_meta']));
      }
    });
  }

  static Future<bool> saveUnSavePost(
      {required bool save, required int postId}) async {
    var url = (save
        ? NetworkConstantsUtil.savePost
        : NetworkConstantsUtil.removeSavedPost);

    final result = await ApiWrapper().postApi(
        url: url, param: {"reference_id": postId.toString(), 'type': '3'});
    return result?.success == true;
  }

  static Future<void> linkCollaborator(
      {required int postId, required int collaboratorId}) async {
    var url = NetworkConstantsUtil.addCollaborate;

    await ApiWrapper().postApi(url: url, param: {
      'reference_id': postId.toString(),
      'type': '1',
      'collaborator_id': collaboratorId.toString()
    });
  }

  static Future<void> updateCollaborationStatus(
      {required int id, required CollaborationStatusType status}) async {
    var url = NetworkConstantsUtil.addCollaborationStatus;

    await ApiWrapper().postApi(url: url, param: {
      'id': id.toString(),
      'status': collaborationStatusTypeId(status).toString(),
    });
  }
}
