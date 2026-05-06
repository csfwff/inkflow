enum ImageHostType { github, smms, imgur }

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
  String smmsToken;
  String imgurClientId;

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
    this.smmsToken = '',
    this.imgurClientId = '',
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.system,
  });
}
