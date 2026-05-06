import 'dart:ui';

class AppStrings {
  final String appTitle;
  final String homeTitle;
  final String subtitle;
  final String newArticle;
  final String editorTitle;
  final String articleSaved;
  final String editorHint;
  final String settingsTitle;
  final String notConfigured;
  final String publishSuccess;
  final String publishFailed;
  final String networkError;

  // Settings sections
  final String sectionGithub;
  final String sectionImageHost;
  final String sectionApp;

  // GitHub config
  final String githubToken;
  final String githubOwner;
  final String githubRepo;
  final String githubBranch;

  // Image host
  final String imageHostType;
  final String imageHostGithub;
  final String imageHostSmms;
  final String imageHostImgur;
  final String imageGithubRepo;
  final String imageGithubPath;
  final String imageGithubDomain;
  final String smmsToken;
  final String imgurClientId;

  // App settings
  final String language;
  final String theme;
  final String version;
  final String themeSystem;
  final String themeLight;
  final String themeDark;
  final String langSystem;
  final String langZh;
  final String langEn;

  const AppStrings._({
    required this.appTitle,
    required this.homeTitle,
    required this.subtitle,
    required this.newArticle,
    required this.editorTitle,
    required this.articleSaved,
    required this.editorHint,
    required this.settingsTitle,
    required this.notConfigured,
    required this.publishSuccess,
    required this.publishFailed,
    required this.networkError,
    required this.sectionGithub,
    required this.sectionImageHost,
    required this.sectionApp,
    required this.githubToken,
    required this.githubOwner,
    required this.githubRepo,
    required this.githubBranch,
    required this.imageHostType,
    required this.imageHostGithub,
    required this.imageHostSmms,
    required this.imageHostImgur,
    required this.imageGithubRepo,
    required this.imageGithubPath,
    required this.imageGithubDomain,
    required this.smmsToken,
    required this.imgurClientId,
    required this.language,
    required this.theme,
    required this.version,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.langSystem,
    required this.langZh,
    required this.langEn,
  });

  static const en = AppStrings._(
    appTitle: 'Inkflow',
    homeTitle: 'Inkflow',
    subtitle: 'Markdown Blog Publishing Tool',
    newArticle: 'New Article',
    editorTitle: 'Edit Article',
    articleSaved: 'Article Saved',
    editorHint: 'Enter Markdown content...',
    settingsTitle: 'Settings',
    notConfigured: 'Not Configured',
    publishSuccess: 'Article published successfully',
    publishFailed: 'Publish failed',
    networkError: 'Network error',
    sectionGithub: 'GitHub Configuration',
    sectionImageHost: 'Image Hosting',
    sectionApp: 'App Settings',
    githubToken: 'Token',
    githubOwner: 'Owner',
    githubRepo: 'Repository',
    githubBranch: 'Branch',
    imageHostType: 'Hosting Provider',
    imageHostGithub: 'GitHub',
    imageHostSmms: 'SM.MS',
    imageHostImgur: 'Imgur',
    imageGithubRepo: 'Image Repository',
    imageGithubPath: 'Path',
    imageGithubDomain: 'Custom Domain',
    smmsToken: 'Token',
    imgurClientId: 'Client ID',
    language: 'Language',
    theme: 'Theme',
    version: 'Version',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    langSystem: 'System',
    langZh: 'Chinese',
    langEn: 'English',
  );

  static const zh = AppStrings._(
    appTitle: 'Inkflow',
    homeTitle: 'Inkflow',
    subtitle: 'Markdown 博客发布工具',
    newArticle: '新建文章',
    editorTitle: '编辑文章',
    articleSaved: '文章已保存',
    editorHint: '输入 Markdown 内容...',
    settingsTitle: '设置',
    notConfigured: '未配置',
    publishSuccess: '文章发布成功',
    publishFailed: '发布失败',
    networkError: '网络错误',
    sectionGithub: 'GitHub 配置',
    sectionImageHost: '图床配置',
    sectionApp: '应用设置',
    githubToken: 'Token',
    githubOwner: 'Owner',
    githubRepo: '仓库',
    githubBranch: '分支',
    imageHostType: '图床提供商',
    imageHostGithub: 'GitHub',
    imageHostSmms: 'SM.MS',
    imageHostImgur: 'Imgur',
    imageGithubRepo: '图片仓库',
    imageGithubPath: '路径',
    imageGithubDomain: '自定义域名',
    smmsToken: 'Token',
    imgurClientId: 'Client ID',
    language: '语言',
    theme: '主题',
    version: '版本',
    themeSystem: '跟随系统',
    themeLight: '浅色',
    themeDark: '深色',
    langSystem: '跟随系统',
    langZh: '中文',
    langEn: '英文',
  );

  static AppStrings get current => forLocale(
        PlatformDispatcher.instance.locale,
      );

  static AppStrings forLocale(Locale locale) {
    if (locale.languageCode == 'zh') return zh;
    return en;
  }
}
