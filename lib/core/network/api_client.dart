import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          final apiException = _handleDioError(error);
          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: apiException,
              message: apiException.message,
              type: error.type,
              response: error.response,
            ),
          );
        },
      ),
    );
  }

  Dio get dio => _dio;

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return TimeoutException();
    }

    if (error.error is SocketException ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException();
    }

    final res = error.response;
    if (res != null) {
      final statusCode = res.statusCode;
      String message = 'Something went wrong';

      if (res.data is Map<String, dynamic>) {
        message = res.data['message'] ?? res.data['error'] ?? message;
      } else if (res.data is String && (res.data as String).isNotEmpty) {
        message = res.data;
      }

      switch (statusCode) {
        case 401:
          return UnauthorizedException(message);
        case 403:
          return ApiException('Access forbidden: $message', 403);
        case 404:
          return NotFoundException(message);
        case 422:
          return ApiException(message, 422);
        case 500:
        case 502:
        case 503:
          return ServerException(message);
        default:
          return ApiException(message, statusCode);
      }
    }

    return ApiException(error.message ?? 'Unexpected error occurred');
  }

  // GET
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'GET failed');
    }
  }

  // POST
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'POST failed');
    }
  }

  // PUT
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'PUT failed');
    }
  }

  // DELETE
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw e.error is ApiException ? e.error as ApiException : ApiException(e.message ?? 'DELETE failed');
    }
  }
}

