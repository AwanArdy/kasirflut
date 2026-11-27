class GithubConstants {
  GithubConstants._();

  static const String owner = 'AwanArdy';
  static const String repo = 'kasirflut';

  static String get latestReleaseUrl =>
    'https://api.github.com/repos/$owner/$repo/releases/latest';

  static const String dismissedVersionKey = 'dismissed_update_version';
}
