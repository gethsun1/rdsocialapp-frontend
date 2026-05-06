class PollsModel {
  int? id;
  String? title;
  int? totalVoteCount;
  int? isVote;

  List<PollOption>? pollOptions;

  PollsModel(
      {this.id,
      this.title,
      this.totalVoteCount,
      this.isVote,
      this.pollOptions});

  PollsModel.fromJson(Map<String, dynamic> json) {
    id = _readInt(json['id']);
    title = json['title']?.toString();
    totalVoteCount =
        _readInt(json['total_vote_count'] ?? json['totalVoteCount']);
    isVote = _readInt(json['is_vote'] ?? json['isVote']);

    final options = json['pollOptions'] ??
        json['poll_options'] ??
        json['pollQuestionOption'] ??
        json['questionOption'];
    if (options is List) {
      pollOptions = <PollOption>[];
      for (final v in options) {
        if (v is Map) {
          pollOptions!.add(PollOption.fromJson(Map<String, dynamic>.from(v)));
        }
      }
    }
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['total_vote_count'] = totalVoteCount;
    data['is_vote'] = isVote;

    if (pollOptions != null) {
      data['pollQuestionOption'] = pollOptions!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class PollOption {
  int? id;
  String? title;
  int? totalOptionVoteCount;

  PollOption({this.id, this.title, this.totalOptionVoteCount});

  PollOption.fromJson(Map<String, dynamic> json) {
    id = PollsModel._readInt(json['id']);
    title = json['title']?.toString();
    totalOptionVoteCount = PollsModel._readInt(
        json['total_option_vote_count'] ?? json['totalOptionVoteCount']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['total_option_vote_count'] = totalOptionVoteCount;
    return data;
  }
}
