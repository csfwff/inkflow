enum ImageHostType { github, upyun }

enum AppThemeMode { system, light, dark }

enum AppLocale { system, zh, en }

class Settings {
  // GitHub
  String githubToken;
  String githubOwner;
  String githubRepo;
  String githubBranch;

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

  // App
  AppThemeMode themeMode;
  AppLocale locale;

  Settings({
    this.githubToken = '',
    this.githubOwner = '',
    this.githubRepo = '',
    this.githubBranch = 'main',
    this.imageHostType = ImageHostType.github,
    this.imageGithubRepo = '',
    this.imageGithubPath = 'images',
    this.imageGithubDomain = '',
    this.upyunBucket = '',
    this.upyunOperator = '',
    this.upyunPassword = '',
    this.upyunDomain = '',
    this.upyunPath = 'images/',
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.system,
  });
}
