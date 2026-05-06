class APIMetaData {
  int totalCount;
  int pageCount;
  int currentPage;
  int perPage;

  APIMetaData({
    required this.totalCount,
    required this.pageCount,
    required this.currentPage,
    required this.perPage,
  });

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  factory APIMetaData.fromJson(Map<String, dynamic> json) => APIMetaData(
        totalCount: _readInt(json["totalCount"]),
        pageCount: _readInt(json["pageCount"], fallback: 1),
        currentPage: _readInt(json["currentPage"], fallback: 1),
        perPage: _readInt(json["perPage"], fallback: 20),
      );
}
