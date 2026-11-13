import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../storage/session_storage.dart';
import 'api_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  final SessionStorage sessionStorage;
  bool _isRefreshing = false;

  ApiClient({Dio? dio, SessionStorage? sessionStorage})
      : sessionStorage = sessionStorage ?? SessionStorage() {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: SessionStorage.defaultBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final baseUrl = await this.sessionStorage.getBaseUrl();
          options.baseUrl = baseUrl;

          final session = await this.sessionStorage.getSession();
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
            if (session.outletId.isNotEmpty) {
              options.headers['X-Outlet-Id'] = session.outletId;
            }
          }

          if ((options.method == 'POST' || options.method == 'PUT') &&
              !options.headers.containsKey('Idempotency-Key')) {
            options.headers['Idempotency-Key'] = const Uuid().v4();
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401 &&
              !_isRefreshing &&
              !error.requestOptions.path.contains('/auth/login') &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final session = await this.sessionStorage.getSession();
              if (session != null) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer ${session.accessToken}';
                try {
                  final retryResponse = await _dio.fetch(error.requestOptions);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryErr) {
                  return handler.next(retryErr);
                }
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    _isRefreshing = true;
    try {
      final session = await sessionStorage.getSession();
      if (session == null || session.refreshToken.isEmpty) return false;

      final baseUrl = await sessionStorage.getBaseUrl();
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': session.refreshToken},
      );
      final data = res.data?['data'];
      if (data is Map<String, dynamic> && data['accessToken'] != null) {
        await sessionStorage.updateTokens(
          accessToken: data['accessToken'] as String,
          refreshToken:
              (data['refreshToken'] as String?) ?? session.refreshToken,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
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
