import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../exceptions/api_exception.dart';
import 'storage_service.dart';

/// API Service
///
/// Centralized HTTP client for all API calls.
/// Handles authentication, error parsing, and request/response processing.
class ApiService {
  static ApiService? _instance;
  final http.Client _client;
  final StorageService _storage;

  ApiService._({
    http.Client? client,
    StorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? StorageService.instance;

  /// Get singleton instance
  static ApiService get instance {
    _instance ??= ApiService._();
    return _instance!;
  }

  /// Create instance with custom dependencies (for testing)
  factory ApiService.withDependencies({
    http.Client? client,
    StorageService? storage,
  }) {
    return ApiService._(client: client, storage: storage);
  }

  // ============== Request Headers ==============

  /// Get default headers for requests
  Map<String, String> get _defaultHeaders => {
        HttpHeaders.contentTypeHeader: ApiConfig.contentType,
        HttpHeaders.acceptHeader: ApiConfig.accept,
      };

  /// Get headers with authentication
  Map<String, String> get _authHeaders {
    final headers = Map<String, String>.from(_defaultHeaders);
    final authHeader = _storage.authorizationHeader;
    if (authHeader != null) {
      headers[HttpHeaders.authorizationHeader] = authHeader;
    }
    return headers;
  }

  // ============== HTTP Methods ==============

  /// GET request
  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    final url = queryParams != null
        ? ApiConfig.getUrlWithParams(endpoint, queryParams)
        : ApiConfig.getUrl(endpoint);

    return _handleRequest(
      () => _client.get(
        Uri.parse(url),
        headers: requiresAuth ? _authHeaders : _defaultHeaders,
      ),
    );
  }

  /// POST request
  Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _client.post(
        Uri.parse(ApiConfig.getUrl(endpoint)),
        headers: requiresAuth ? _authHeaders : _defaultHeaders,
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  /// PUT request
  Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _client.put(
        Uri.parse(ApiConfig.getUrl(endpoint)),
        headers: requiresAuth ? _authHeaders : _defaultHeaders,
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  /// PATCH request
  Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _client.patch(
        Uri.parse(ApiConfig.getUrl(endpoint)),
        headers: requiresAuth ? _authHeaders : _defaultHeaders,
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  /// DELETE request
  Future<ApiResponse> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    return _handleRequest(
      () => _client.delete(
        Uri.parse(ApiConfig.getUrl(endpoint)),
        headers: requiresAuth ? _authHeaders : _defaultHeaders,
        body: body != null ? json.encode(body) : null,
      ),
    );
  }

  /// POST request with multipart form data (for file uploads)
  Future<ApiResponse> postMultipart(
    String endpoint, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool requiresAuth = true,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getUrl(endpoint)),
      );

      // Add headers
      request.headers.addAll(requiresAuth ? _authHeaders : _defaultHeaders);
      request.headers.remove(HttpHeaders.contentTypeHeader); // Let http set it

      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await request.send().timeout(
            Duration(seconds: ApiConfig.timeoutSeconds * 2),
          );

      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException.network();
    } on TimeoutException {
      throw ApiException.timeout();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.unknown(e.toString());
    }
  }

  // ============== Request Handler ==============

  /// Handle request with timeout and error handling
  Future<ApiResponse> _handleRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(
        Duration(seconds: ApiConfig.timeoutSeconds),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException.network();
    } on TimeoutException {
      throw ApiException.timeout();
    } on http.ClientException catch (e) {
      throw ApiException.network(e.message);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.unknown(e.toString());
    }
  }

  /// Process HTTP response
  ApiResponse _processResponse(http.Response response) {
    dynamic body;

    // Parse response body
    if (response.body.isNotEmpty) {
      try {
        body = json.decode(response.body);
      } catch (_) {
        body = response.body;
      }
    }

    // Check for successful response
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        statusCode: response.statusCode,
        data: body,
        isSuccess: true,
      );
    }

    // Handle error responses
    throw ApiException.fromResponse(
      statusCode: response.statusCode,
      body: body,
    );
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// API Response wrapper
///
/// Represents a successful API response with parsed data.
class ApiResponse {
  final int statusCode;
  final dynamic data;
  final bool isSuccess;

  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.isSuccess,
  });

  /// Get data as Map
  Map<String, dynamic>? get dataAsMap =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : null;

  /// Get data as List
  List<dynamic>? get dataAsList => data is List ? data as List<dynamic> : null;

  /// Get nested data from response (e.g., response['data'])
  dynamic operator [](String key) {
    if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)[key];
    }
    return null;
  }

  /// Get message from response
  String? get message {
    if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)['message'] as String?;
    }
    return null;
  }

  @override
  String toString() {
    return 'ApiResponse(statusCode: $statusCode, isSuccess: $isSuccess, data: $data)';
  }
}
