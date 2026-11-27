import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/github_constants.dart';
import '../models/release_info_model.dart';


class UpdateRepository {
  final Dio _githubDio;

  UpdateRepository({Dio? dio})
    : _githubDio = dio ??
      Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/vnd.github+json'},
        ),
      );

  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<ReleaseInfo?> checkForUpdate({bool ignoreDismissed = false}) async {
    final currentVersion = await getCurrentVersion();

    final response = await _githubDio.get(
      GithubConstants.latestReleaseUrl
    );

    final data = response.data;
    if (data == null) return null;

    final release = ReleaseInfo.fromGithubJson(data);
    if (!release.hasValidApk) return null;

    if (!_isNewerVersion(release.version, currentVersion)) {
      return null;
    }

    if (!ignoreDismissed) {
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(GithubConstants.dismissedVersionKey);
      if (dismissedVersion == release.version) {
        return null;
      }
    }

    return release;
  }

  Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GithubConstants.dismissedVersionKey, version);
  }

  Future<void> downloadAndInstallApk(
    ReleaseInfo release, {
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/${release.fileName}';
    final file = File(savePath);

    if (await file.exists()) {
      await file.delete();
    }

    await _githubDio.download(
      release.downloadUrl, 
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    final result = await OpenFilex.open(savePath);
    if (result.type != ResultType.done) {
      throw Exception(
        'Gagal membuka installer APK (${result.message}). '
        'Pastikan izin "Install unknown apps" sudah aktif.',
      );
    }
  }

  bool _isNewerVersion(String latest, String current) {
    final latestParts = latest
      .split('+')
      .first
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();
    final currentParts = current
      .split('+')
      .first
      .split('.')
      .map((e) => int.tryParse(e) ?? 0)
      .toList();

    final maxLen = latestParts.length > currentParts.length
      ? latestParts.length
      : currentParts.length;

    for (var i = 0; i < maxLen; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
