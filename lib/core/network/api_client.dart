import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  static const String baseUrl = 'http://localhost:3000/api';

  ApiClient({Dio? dio}) {
    _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'}
        ),
      );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {

          if ((options.method == 'POST' || options.method == 'PUT') &&
              !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = const Uuid().v4();
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          return handler.reject(error);
        },
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    String? idempotencyKey,
  }) async {
    try {
      final options = Options();
      if (idempotencyKey != null) {
        options.headers = {'Idempotency-Key': idempotencyKey};
      }
      final response = await _dio.post(path, data: data, options: options);
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
