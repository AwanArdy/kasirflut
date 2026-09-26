import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ApiException({
    required this.message,
    this.code,
    this.statusCode
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.connectionError:
            return ApiException(
              message: 'Koneksi internet terputus atau server tidak merespons',
              code: 'NETWORK_ERROR'
            );
          
          case DioExceptionType.badResponse:
            final responseData = error.response?.data;
            if (responseData is Map<String, dynamic> && responseData['error'] != null) {
              final errObj = responseData['error'];
              return ApiException(
                message: errObj['message'] ?? 'Terjadi kesalahan pada server',
                code: errObj['code'] ?? 'UNKNOWN_ERROR',
                statusCode: error.response?.statusCode,
              );
            }
            return ApiException(
              message: 'Terjadi kesalahan HTTP ${error.response?.statusCode}',
              code: 'HTTP_ERROR',
              statusCode: error.response?.statusCode
            );

          default:
            return ApiException(
              message: 'Terjadi kesalahan tidak terduga',
              code: 'UNKNOWN_ERROR'
            );
        }
  }

  @override
  String toString() => message;
}
