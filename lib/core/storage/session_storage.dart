import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionData {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String userName;
  final String organizationId;
  final String organizationName;
  final String outletId;
  final String outletName;

  AuthSessionData({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.userName,
    required this.organizationId,
    required this.organizationName,
    required this.outletId,
    required this.outletName,
  });
}

class SessionStorage {
  static const _kBaseUrl = 'api_base_url';
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kUserName = 'user_name';
  static const _kOrgId = 'organization_id';
  static const _kOrgName = 'organization_name';
  static const _kOutletId = 'outlet_id';
  static const _kOutletName = 'outlet_name';

  static const String defaultBaseUrl = 'http://localhost:3000/api/v1';

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kBaseUrl) ?? defaultBaseUrl;
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, url.trim().replaceAll(RegExp(r'/+$'), ''));
  }

  Future<void> saveSession(AuthSessionData session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, session.accessToken);
    await prefs.setString(_kRefreshToken, session.refreshToken);
    await prefs.setString(_kUserId, session.userId);
    await prefs.setString(_kUserName, session.userName);
    await prefs.setString(_kOrgId, session.organizationId);
    await prefs.setString(_kOrgName, session.organizationName);
    await prefs.setString(_kOutletId, session.outletId);
    await prefs.setString(_kOutletName, session.outletName);
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
  }

  Future<AuthSessionData?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_kAccessToken);
    final refreshToken = prefs.getString(_kRefreshToken);
    final outletId = prefs.getString(_kOutletId);
    if (accessToken == null || refreshToken == null || outletId == null) {
      return null;
    }
    return AuthSessionData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: prefs.getString(_kUserId) ?? '',
      userName: prefs.getString(_kUserName) ?? 'Kasir',
      organizationId: prefs.getString(_kOrgId) ?? '',
      organizationName: prefs.getString(_kOrgName) ?? 'Teratur',
      outletId: outletId,
      outletName: prefs.getString(_kOutletName) ?? 'Outlet Utama',
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUserName);
    await prefs.remove(_kOrgId);
    await prefs.remove(_kOrgName);
    await prefs.remove(_kOutletId);
    await prefs.remove(_kOutletName);
  }
}
