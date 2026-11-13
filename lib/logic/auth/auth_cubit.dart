import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/storage/session_storage.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AuthSessionData session;
  AuthAuthenticated(this.session);
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final ApiClient apiClient;
  final SessionStorage sessionStorage;

  AuthCubit({
    required this.apiClient,
    SessionStorage? sessionStorage,
  })  : sessionStorage = sessionStorage ?? apiClient.sessionStorage,
        super(AuthInitial());

  Future<void> checkSession() async {
    final session = await sessionStorage.getSession();
    if (session != null) {
      emit(AuthAuthenticated(session));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required String serverUrl,
  }) async {
    emit(AuthLoading());
    try {
      await sessionStorage.setBaseUrl(serverUrl);
      final res = await apiClient.post(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'rememberMe': true,
        },
      );

      final data = res['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>;
      final org = data['organization'] as Map<String, dynamic>;
      final outlet = data['outlet'] as Map<String, dynamic>;

      final session = AuthSessionData(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        userId: user['id'] as String? ?? '',
        userName: user['fullName'] as String? ?? 'Kasir',
        organizationId: org['id'] as String? ?? '',
        organizationName: org['name'] as String? ?? 'Teratur',
        outletId: outlet['id'] as String? ?? '',
        outletName: outlet['name'] as String? ?? 'Outlet Utama',
      );

      await sessionStorage.saveSession(session);
      emit(AuthAuthenticated(session));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError('Gagal login. Periksa koneksi atau alamat server.'));
    }
  }

  Future<void> logout() async {
    try {
      final session = await sessionStorage.getSession();
      if (session != null) {
        await apiClient.post(
          '/auth/logout',
          data: {'refreshToken': session.refreshToken},
        );
      }
    } catch (_) {
      // Tetap logout lokal meski offline
    }
    await sessionStorage.clearSession();
    emit(AuthUnauthenticated());
  }
}
