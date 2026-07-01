enum ImageHostType { github, upyun }

enum ImageNamingMode { timestamp, original, timestampOriginal }

enum ImageDateFolderMode { none, year, yearMonth }

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
  ImageDateFolderMode imageDateFolderMode;
  ImageNamingMode imageNamingMode;

  // Image compression
  bool imageCompressEnabled;
  int imageCompressTargetKB; // 0 = unlimited, 256, 512, 1024, 2048

  // Friend links
  String friendLinkPath;

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
    this.githubPathPattern = '',
    this.permalinkPattern = '',
    this.imageHostType = ImageHostType.github,
    this.imageGithubRepo = '',
    this.imageGithubPath = 'images',
    this.imageGithubDomain = '',
    this.upyunBucket = '',
    this.upyunOperator = '',
    this.upyunPassword = '',
    this.upyunDomain = '',
    this.upyunPath = '',
    this.imageDateFolderMode = ImageDateFolderMode.none,
    this.imageNamingMode = ImageNamingMode.timestamp,
    this.imageCompressEnabled = false,
    this.imageCompressTargetKB = 1024,
    this.friendLinkPath = 'source/_data/links.yml',
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.system,
    this.lastSyncTime,
  });

  /// 导出配置为 JSON（可选择是否包含敏感凭据）
  Map<String, dynamic> toExportJson({bool includeSensitive = true}) {
    return {
      if (includeSensitive) 'githubToken': githubToken,
      'githubOwner': githubOwner,
      'githubRepo': githubRepo,
      'githubBranch': githubBranch,
      'githubPathPattern': githubPathPattern,
      'permalinkPattern': permalinkPattern,
      'imageHostType': imageHostType.index,
      'imageGithubRepo': imageGithubRepo,
      'imageGithubPath': imageGithubPath,
      'imageGithubDomain': imageGithubDomain,
      'upyunBucket': upyunBucket,
      'upyunOperator': upyunOperator,
      if (includeSensitive) 'upyunPassword': upyunPassword,
      'upyunDomain': upyunDomain,
      'upyunPath': upyunPath,
      'imageDateFolderMode': imageDateFolderMode.index,
      'imageNamingMode': imageNamingMode.index,
      'imageCompressEnabled': imageCompressEnabled,
      'imageCompressTargetKB': imageCompressTargetKB,
      'friendLinkPath': friendLinkPath,
    };
  }

  /// 从导入的 JSON 应用配置
  void applyExportJson(Map<String, dynamic> json) {
    if (json.containsKey('githubToken')) githubToken = json['githubToken'] ?? '';
    if (json.containsKey('githubOwner')) githubOwner = json['githubOwner'] ?? '';
    if (json.containsKey('githubRepo')) githubRepo = json['githubRepo'] ?? '';
    if (json.containsKey('githubBranch')) githubBranch = json['githubBranch'] ?? 'main';
    if (json.containsKey('githubPathPattern')) githubPathPattern = json['githubPathPattern'] ?? '';
    if (json.containsKey('permalinkPattern')) permalinkPattern = json['permalinkPattern'] ?? '';
    if (json.containsKey('imageHostType')) {
      final idx = json['imageHostType'] as int? ?? 0;
      if (idx >= 0 && idx < ImageHostType.values.length) {
        imageHostType = ImageHostType.values[idx];
      }
    }
    if (json.containsKey('imageGithubRepo')) imageGithubRepo = json['imageGithubRepo'] ?? '';
    if (json.containsKey('imageGithubPath')) imageGithubPath = json['imageGithubPath'] ?? 'images';
    if (json.containsKey('imageGithubDomain')) imageGithubDomain = json['imageGithubDomain'] ?? '';
    if (json.containsKey('upyunBucket')) upyunBucket = json['upyunBucket'] ?? '';
    if (json.containsKey('upyunOperator')) upyunOperator = json['upyunOperator'] ?? '';
    if (json.containsKey('upyunPassword')) upyunPassword = json['upyunPassword'] ?? '';
    if (json.containsKey('upyunDomain')) upyunDomain = json['upyunDomain'] ?? '';
    if (json.containsKey('upyunPath')) upyunPath = json['upyunPath'] ?? '';
    if (json.containsKey('imageDateFolderMode')) {
      final idx = json['imageDateFolderMode'] as int? ?? 0;
      if (idx >= 0 && idx < ImageDateFolderMode.values.length) {
        imageDateFolderMode = ImageDateFolderMode.values[idx];
      }
    }
    if (json.containsKey('imageNamingMode')) {
      final idx = json['imageNamingMode'] as int? ?? 0;
      if (idx >= 0 && idx < ImageNamingMode.values.length) {
        imageNamingMode = ImageNamingMode.values[idx];
      }
    }
    if (json.containsKey('imageCompressEnabled')) {
      imageCompressEnabled = json['imageCompressEnabled'] ?? false;
    }
    if (json.containsKey('imageCompressTargetKB')) {
      imageCompressTargetKB = json['imageCompressTargetKB'] ?? 1024;
    }
    if (json.containsKey('friendLinkPath')) {
      friendLinkPath = json['friendLinkPath'] ?? 'source/_data/links.yml';
    }
  }
}
