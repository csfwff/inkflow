enum ImageHostType { github, upyun }

enum ImageNamingMode { timestamp, original, timestampOriginal }

enum AppThemeMode { system, light, dark }

enum AppLocale { system, zh, en }

class Settings {
  // GitHub
  String githubToken;
  String githubOwner;
  String githubRepo;
  String githubBranch;
  String githubPathPattern;

  // Permalink
  String permalinkPattern;

  // Image host
  ImageHostType imageHostType;
  String imageGithubRepo;
  String imageGithubPath;
  String imageGithubDomain;
  String upyunBucket;
  String upyunOperator;
  String upyunPassword;
  String upyunDomain;
  String upyunPath;

  // Image upload path / naming (shared across hosts)
  bool imageUseDateFolder;
  ImageNamingMode imageNamingMode;

  // App
  AppThemeMode themeMode;
  AppLocale locale;

  // Sync
  DateTime? lastSyncTime;

  Settings({
    this.githubToken = '',
    this.githubOwner = '',
    this.githubRepo = '',
    this.githubBranch = 'main',
    this.githubPathPattern = '{year}/{month}',
    this.permalinkPattern = 'articles/{year}/{month}/{day}/{timestamp}.html',
    this.imageHostType = ImageHostType.github,
    this.imageGithubRepo = '',
    this.imageGithubPath = 'images',
    this.imageGithubDomain = '',
    this.upyunBucket = '',
    this.upyunOperator = '',
    this.upyunPassword = '',
    this.upyunDomain = '',
    this.upyunPath = '',
    this.imageUseDateFolder = false,
    this.imageNamingMode = ImageNamingMode.timestamp,
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.system,
    this.lastSyncTime,
  });
}
