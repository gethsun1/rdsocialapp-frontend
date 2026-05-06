import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:foap/helper/imports/common_import.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../helper/enum_linking.dart';
import '../main.dart';
import '../screens/login_sign_up/login_screen.dart';
import '../util/shared_prefs.dart';
import 'network_constant.dart';
export 'network_constant.dart';

class ApiResponse {
  bool? success;
  dynamic data;
  String? message;

  ApiResponse();

  factory ApiResponse.fromJson(dynamic json) {
    final ApiResponse model = ApiResponse();

    if (json is! Map) {
      model.success = false;
      model.data = null;
      model.message = 'Invalid server response format.';
      return model;
    }

    final map = Map<String, dynamic>.from(json);
    final dynamic statusValue = map['status'];
    final int? status = statusValue is int
        ? statusValue
        : int.tryParse(statusValue?.toString() ?? '');

    model.success = status != null && status >= 200 && status < 300;
    model.data = map['data'];
    model.message = map['message']?.toString();

    if (status == 401) {
      // go to login
      if (isAnyPageInStack) {
        Get.offAll(() => const LoginScreen());
      }
    }

    if (model.success != true &&
        model.data != null &&
        model.message?.isEmpty == true) {
      final payload = model.data;
      if (payload is Map) {
        final payloadMap = Map<String, dynamic>.from(payload);
        final dynamic errorsNode = payloadMap['errors'];
        if (errorsNode is Map) {
          final errorsMap = Map<String, dynamic>.from(errorsNode);
          final dynamic messages = errorsMap['message'];
          if (messages is List && messages.isNotEmpty) {
            model.message = messages.first?.toString();
          } else if (messages is String && messages.isNotEmpty) {
            model.message = messages;
          } else if (errorsMap.isNotEmpty) {
            final firstValue = errorsMap.values.first;
            if (firstValue is List && firstValue.isNotEmpty) {
              model.message = firstValue.first?.toString();
            } else if (firstValue is String && firstValue.isNotEmpty) {
              model.message = firstValue;
            }
          }
        }
      }
    }

    // Some backend errors arrive as {"data": {"detail": "..."}}
    // while top-level message remains generic ("Error").
    if (model.success != true && model.data is Map) {
      final detail = (model.data as Map)['detail'];
      if (detail is String && detail.isNotEmpty) {
        model.message = detail;
      }
    }

    return model;
  }
}

class ApiWrapper {
  final JsonDecoder _decoder = const JsonDecoder();
  static const Duration _requestTimeout = Duration(seconds: 15);

  ApiResponse _nonJsonResponse({
    required String method,
    required String url,
    required http.Response response,
  }) {
    final normalizedBody = response.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final preview = normalizedBody.length > 240
        ? normalizedBody.substring(0, 240)
        : normalizedBody;
    debugPrint(
        '[Network Warning] $method returned non-JSON (${response.statusCode}): $url $preview');

    final apiResponse = ApiResponse();
    apiResponse.success = false;
    apiResponse.data = null;
    apiResponse.message =
        'Server returned HTML instead of JSON (${response.statusCode}). Please check the API endpoint and backend logs.';
    return apiResponse;
  }

  ApiResponse _parseJsonResponse({
    required String method,
    required String url,
    required http.Response response,
  }) {
    try {
      final dynamic data = _decoder.convert(response.body);
      debugPrint(data.toString());
      return ApiResponse.fromJson(data);
    } on FormatException {
      return _nonJsonResponse(method: method, url: url, response: response);
    }
  }

  Future<ApiResponse?> getApiWithoutToken({required String url}) async {
    String urlString = '${NetworkConstantsUtil.baseUrl}$url';

    final connectivityResult = await (Connectivity().checkConnectivity());

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        final http.Response response =
            await http.get(Uri.parse(urlString)).timeout(_requestTimeout);
        dynamic data = _decoder.convert(response.body);
        EasyLoading.dismiss();
        SharedPrefs().setApiResponse(url: urlString, response: response.body);

        return ApiResponse.fromJson(data);
      } on TimeoutException {
        debugPrint(
            '[Network Warning] GET (without token) timed out after ${_requestTimeout.inSeconds}s: $urlString');
      }
    } else {
      EasyLoading.dismiss();
      String? cachedResponse =
          await SharedPrefs().getCachedApiResponse(url: urlString);

      if (cachedResponse != null) {
        dynamic data = _decoder.convert(cachedResponse);
        return ApiResponse.fromJson(data);
      }
    }
    return null;
  }

  Future<ApiResponse?> getApi({required String url}) async {
    String? authKey = await SharedPrefs().getAuthorizationKey();
    String urlString = '${NetworkConstantsUtil.baseUrl}$url';

    final connectivityResult = await (Connectivity().checkConnectivity());

    debugPrint(authKey);
    debugPrint(urlString);

    if (!connectivityResult.contains(ConnectivityResult.none)) {
      try {
        final http.Response response = await http.get(Uri.parse(urlString),
            headers: {
              "Authorization": "Bearer ${authKey!}"
            }).timeout(_requestTimeout);
        dynamic data = _decoder.convert(response.body);
        EasyLoading.dismiss();
        SharedPrefs().setApiResponse(url: urlString, response: response.body);

        return ApiResponse.fromJson(data);
      } on TimeoutException {
        debugPrint(
            '[Network Warning] GET timed out after ${_requestTimeout.inSeconds}s: $urlString');
      }
    } else {
      EasyLoading.dismiss();
      String? cachedResponse =
          await SharedPrefs().getCachedApiResponse(url: urlString);

      if (cachedResponse != null) {
        dynamic data = _decoder.convert(cachedResponse);
        return ApiResponse.fromJson(data);
      }
    }
    return null;
  }

  Future<ApiResponse?> postApi(
      {required String url, required dynamic param}) async {
    String? authKey = await SharedPrefs().getAuthorizationKey();

    String urlString = '${NetworkConstantsUtil.baseUrl}$url';
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      final response = ApiResponse();
      response.success = false;
      response.message = noInternetString.tr;
      return response;
    }
    debugPrint('authKey $authKey');
    debugPrint('urlString $urlString');
    debugPrint('param $param');

    try {
      final http.Response response = await http.post(
        Uri.parse(urlString),
        body: jsonEncode(param),
        headers: {
          "Authorization": "Bearer ${authKey!}",
          'Content-Type': 'application/json'
        },
      ).timeout(_requestTimeout);

      return _parseJsonResponse(
          method: 'POST', url: urlString, response: response);
    } on TimeoutException {
      debugPrint(
          '[Network Warning] POST timed out after ${_requestTimeout.inSeconds}s: $urlString');
      final response = ApiResponse();
      response.success = false;
      response.message = 'Request timed out. Please try again.'.tr;
      return response;
    } catch (error) {
      debugPrint('[Network Warning] POST failed: $urlString $error');
      final response = ApiResponse();
      response.success = false;
      response.message = error.toString();
      return response;
    }
  }

  Future<ApiResponse?> putApi(
      {required String url, required dynamic param}) async {
    String? authKey = await SharedPrefs().getAuthorizationKey();
    EasyLoading.show(status: loadingString.tr);

    return http.put(Uri.parse('${NetworkConstantsUtil.baseUrl}$url'),
        body: jsonEncode(param),
        headers: {
          "Authorization": "Bearer ${authKey!}",
          'Content-Type': 'application/json'
        }).then((http.Response response) async {
      dynamic data = _decoder.convert(response.body);
      // debugPrint(data);
      EasyLoading.dismiss();

      return ApiResponse.fromJson(data);
    });
  }

  Future<ApiResponse?> deleteApi({required String url}) async {
    String? authKey = await SharedPrefs().getAuthorizationKey();
    EasyLoading.show(status: loadingString.tr);

    // debugPrint('${NetworkConstantsUtil.baseUrl}$url');
    return http.delete(Uri.parse('${NetworkConstantsUtil.baseUrl}$url'),
        headers: {
          "Authorization": "Bearer $authKey",
          'Content-Type': 'application/json'
        }).then((http.Response response) async {
      dynamic data = _decoder.convert(response.body);
      // debugPrint(data);
      EasyLoading.dismiss();

      return ApiResponse.fromJson(data);
    });
  }

  Future<ApiResponse?> postApiWithoutToken(
      {required String url, required dynamic param}) async {
    final urlString = '${NetworkConstantsUtil.baseUrl}$url';
    debugPrint('urlString $urlString');
    debugPrint('param $param');

    try {
      String? encodedBody;
      Map<String, String>? headers;

      if (param == null) {
        encodedBody = null;
      } else if (param is String) {
        encodedBody = param;
      } else {
        // Use JSON consistently to avoid form-body type cast issues.
        encodedBody = jsonEncode(param);
        headers = {'Content-Type': 'application/json'};
      }

      final response = await http.post(Uri.parse(urlString),
          body: encodedBody, headers: headers);
      dynamic data = _decoder.convert(response.body);
      debugPrint(data.toString());
      return ApiResponse.fromJson(data);
    } on TypeError catch (e) {
      final error = ApiResponse();
      error.success = false;
      error.message = 'Request payload type error: $e';
      return error;
    } on FormatException catch (e) {
      final error = ApiResponse();
      error.success = false;
      error.message = 'Server returned invalid JSON: ${e.message}';
      return error;
    } catch (e) {
      final error = ApiResponse();
      error.success = false;
      error.message = 'Request failed: $e';
      return error;
    }
  }

  Future<ApiResponse?> multipartImageUpload(
      {required String url, required Uint8List imageFileData}) async {
    EasyLoading.show(status: loadingString.tr);

    debugPrint('url ${'${NetworkConstantsUtil.baseUrl}$url'}');
    String? authKey = await SharedPrefs().getAuthorizationKey();
    var postUri = Uri.parse('${NetworkConstantsUtil.baseUrl}$url');
    var request = http.MultipartRequest("POST", postUri);
    request.headers.addAll({"Authorization": "Bearer ${authKey!}"});

    request.files.add(http.MultipartFile.fromBytes('imageFile', imageFileData,
        filename: '${DateTime.now().toIso8601String()}.jpg',
        contentType: MediaType('image', 'jpg')));

    return request.send().then((response) async {
      final respStr = await response.stream.bytesToString();
      EasyLoading.dismiss();

      dynamic data = _decoder.convert(respStr);

      debugPrint('data = $data');
      return ApiResponse.fromJson(data);
    });
  }

  Future<ApiResponse?> uploadFile(
      {required String file,
      required UploadMediaType type,
      required GalleryMediaType mediaType,
      required String url,
      Map<String, String>? extraFields}) async {
    EasyLoading.show(status: loadingString.tr);
    try {
      String? authKey = await SharedPrefs().getAuthorizationKey();
      if (authKey == null || authKey.isEmpty) {
        EasyLoading.dismiss();
        final response = ApiResponse();
        response.success = false;
        response.message = 'Session expired. Please login again.';
        return response;
      }

      debugPrint('${NetworkConstantsUtil.baseUrl}$url');
      debugPrint("Bearer $authKey");
      debugPrint(uploadMediaTypeId(type).toString());

      var request = http.MultipartRequest(
          'POST', Uri.parse('${NetworkConstantsUtil.baseUrl}$url'));
      request.headers.addAll({"Authorization": "Bearer $authKey"});
      request.fields.addAll({'type': uploadMediaTypeId(type).toString()});
      if (extraFields != null) {
        request.fields.addAll(extraFields);
      }

      if (mediaType == GalleryMediaType.video) {
        request.files.add(await http.MultipartFile.fromPath('mediaFile', file,
            contentType: MediaType('video', 'mp4')));
      } else if (mediaType == GalleryMediaType.audio) {
        final extension = file.split('.').last.toLowerCase();
        final subtype = extension == 'm4a'
            ? 'mp4'
            : extension == 'aac'
                ? 'aac'
                : extension == 'wav'
                    ? 'wav'
                    : 'mpeg';
        request.files.add(await http.MultipartFile.fromPath('mediaFile', file,
            contentType: MediaType('audio', subtype)));
      } else {
        request.files.add(await http.MultipartFile.fromPath('mediaFile', file));
      }

      var res = await request.send();
      var responseData = await res.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      debugPrint('upload http status: ${res.statusCode}');
      debugPrint('upload response: $responseString');

      try {
        dynamic data = _decoder.convert(responseString);
        EasyLoading.dismiss();
        return ApiResponse.fromJson(data);
      } catch (_) {
        EasyLoading.dismiss();
        final response = ApiResponse();
        response.success = false;
        response.message =
            'Upload failed (${res.statusCode}). Server response was not valid JSON.';
        response.data = {'raw': responseString};
        return response;
      }
    } catch (e) {
      EasyLoading.dismiss();
      final response = ApiResponse();
      response.success = false;
      response.message = 'Upload request error: $e';
      return response;
    }
  }
}
