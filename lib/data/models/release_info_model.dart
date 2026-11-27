class ReleaseInfo {
  final String version;
  final String notes;
  final String downloadUrl;
  final String fileName;

  const ReleaseInfo({
    required this.version,
    required this.notes,
    required this.downloadUrl,
    required this.fileName,
  });

  factory ReleaseInfo.fromGithubJson(Map<String, dynamic> json) {
    final rawTag = json['tag_name'] as String? ?? '';
    final cleanVersion = rawTag.replaceFirst(RegExp(r'^[vV]'), '').trim();

    final assets = (json['assets'] as List<dynamic>? ?? []).whereType();

    final apkAsset = assets.firstWhere(
      (asset) => (asset['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
      orElse: () => <String, dynamic>{},
    );

    return ReleaseInfo(
      version: cleanVersion, 
      notes: (json['body'] as String? ?? ''), 
      downloadUrl: apkAsset['browser_download_url'] as String? ?? '', 
      fileName: apkAsset['name'] as String? ?? 'teraturpos-update.apk',
    );
  }

  bool get hasValidApk => version.isNotEmpty && downloadUrl.isNotEmpty;
}
