import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // ── TOKEN ─────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ── HEADERS ───────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── RESPONSE HANDLER ─────────────────────────────────────────────
  static dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      throw ApiException(
        decoded['message'] ?? decoded['error'] ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }
    throw ApiException('Request failed', statusCode: response.statusCode);
  }

  // ── GET ───────────────────────────────────────────────────────────
  static Future<dynamic> get(String url) async {
    final headers = await _headers();
    final response = await http
        .get(Uri.parse(url), headers: headers)
        .timeout(AppConstants.requestTimeout);
    return _handleResponse(response);
  }

  // ── POST ──────────────────────────────────────────────────────────
  static Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final headers = await _headers(auth: auth);
    final response = await http
        .post(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(AppConstants.requestTimeout);
    return _handleResponse(response);
  }

  // ── PUT ───────────────────────────────────────────────────────────
  static Future<dynamic> put(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    final response = await http
        .put(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(AppConstants.requestTimeout);
    return _handleResponse(response);
  }

  // ── PATCH ─────────────────────────────────────────────────────────
  static Future<dynamic> patch(
    String url,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    final response = await http
        .patch(Uri.parse(url), headers: headers, body: jsonEncode(body))
        .timeout(AppConstants.requestTimeout);
    return _handleResponse(response);
  }

  // ── DELETE ────────────────────────────────────────────────────────
  static Future<dynamic> delete(String url) async {
    final headers = await _headers();
    final response = await http
        .delete(Uri.parse(url), headers: headers)
        .timeout(AppConstants.requestTimeout);
    return _handleResponse(response);
  }

  // ── MULTIPART UPLOAD (for files + images) ─────────────────────────
  static Future<dynamic> uploadFile(
    String url,
    Uint8List fileBytes,
    String fileName,
    Map<String, String> fields,
  ) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
    );

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // ── MULTIPART UPLOAD WITH IMAGE ───────────────────────────────────
  static Future<dynamic> uploadWithImage(
    String url,
    Map<String, String> fields, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    if (imageBytes != null && imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: imageName),
      );
    }

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }
}