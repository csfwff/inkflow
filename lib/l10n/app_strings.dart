import 'dart:ui';

class AppStrings {
  final String appTitle;
  final String homeTitle;
  final String subtitle;
  final String newArticle;
  final String editorTitle;
  final String articleSaved;
  final String editorHint;
  final String titleHint;
  final String date;
  final String publish;
  final String publishing;
  final String githubNotConfigured;
  final String settingsTitle;
  final String notConfigured;
  final String publishSuccess;
  final String publishFailed;
  final String networkError;

  // Settings sections
  final String sectionGithub;
  final String sectionImageHost;
  final String sectionApp;

  // Settings tabs
  final String tabGeneral;
  final String tabGithub;
  final String tabImageHost;

  // GitHub config
  final String githubToken;
  final String githubOwner;
  final String githubRepo;
  final String githubBranch;

  // Image host
  final String imageHostType;
  final String imageHostGithub;
  final String imageHostUpyun;
  final String imageGithubRepo;
  final String imageGithubPath;
  final String imageGithubDomain;
  final String upyunBucket;
  final String upyunBucketHint;
  final String upyunOperator;
  final String upyunOperatorHint;
  final String upyunPassword;
  final String upyunPasswordHint;
  final String upyunDomain;
  final String upyunDomainHint;
  final String upyunPath;
  final String upyunPathHint;

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

  // Article list
  final String saveDraft;
  final String synced;
  final String draftStatus;
  final String syncFromGitHub;
  final String syncSuccess;
  final String syncFailed;
  final String noArticles;
  final String deleteArticle;
  final String deleteConfirm;
  final String cancel;
  final String pushToDraft;
  final String repoDraft;
  final String remoteDeleted;

  // Metadata
  final String metadata;
  final String done;
  final String tags;
  final String tagsHint;
  final String categories;
  final String categoriesHint;
  final String permalink;
  final String permalinkHint;
  final String topImg;
  final String topImgHint;
  final String cover;
  final String coverHint;
  final String layout;
  final String layoutPost;
  final String layoutDraft;
  final String layoutPage;
  final String comments;
  final String published;
  final String excerpt;
  final String excerptHint;
  final String description;
  final String descriptionHint;
  final String author;
  final String authorHint;

  const AppStrings._({
    required this.appTitle,
    required this.homeTitle,
    required this.subtitle,
    required this.newArticle,
    required this.editorTitle,
    required this.articleSaved,
    required this.editorHint,
    required this.titleHint,
    required this.date,
    required this.publish,
    required this.publishing,
    required this.githubNotConfigured,
    required this.settingsTitle,
    required this.notConfigured,
    required this.publishSuccess,
    required this.publishFailed,
    required this.networkError,
    required this.sectionGithub,
    required this.sectionImageHost,
    required this.sectionApp,
    required this.tabGeneral,
    required this.tabGithub,
    required this.tabImageHost,
    required this.githubToken,
    required this.githubOwner,
    required this.githubRepo,
    required this.githubBranch,
    required this.imageHostType,
    required this.imageHostGithub,
    required this.imageHostUpyun,
    required this.imageGithubRepo,
    required this.imageGithubPath,
    required this.imageGithubDomain,
    required this.upyunBucket,
    required this.upyunBucketHint,
    required this.upyunOperator,
    required this.upyunOperatorHint,
    required this.upyunPassword,
    required this.upyunPasswordHint,
    required this.upyunDomain,
    required this.upyunDomainHint,
    required this.upyunPath,
    required this.upyunPathHint,
    required this.language,
    required this.theme,
    required this.version,
    required this.themeSystem,
    required this.themeLight,
    required this.themeDark,
    required this.langSystem,
    required this.langZh,
    required this.langEn,
    required this.saveDraft,
    required this.synced,
    required this.draftStatus,
    required this.syncFromGitHub,
    required this.syncSuccess,
    required this.syncFailed,
    required this.noArticles,
    required this.deleteArticle,
    required this.deleteConfirm,
    required this.cancel,
    required this.pushToDraft,
    required this.repoDraft,
    required this.remoteDeleted,
    required this.metadata,
    required this.done,
    required this.tags,
    required this.tagsHint,
    required this.categories,
    required this.categoriesHint,
    required this.permalink,
    required this.permalinkHint,
    required this.topImg,
    required this.topImgHint,
    required this.cover,
    required this.coverHint,
    required this.layout,
    required this.layoutPost,
    required this.layoutDraft,
    required this.layoutPage,
    required this.comments,
    required this.published,
    required this.excerpt,
    required this.excerptHint,
    required this.description,
    required this.descriptionHint,
    required this.author,
    required this.authorHint,
  });

  static const en = AppStrings._(
    appTitle: 'Inkflow',
    homeTitle: 'Inkflow',
    subtitle: 'Markdown Blog Publishing Tool',
    newArticle: 'New Article',
    editorTitle: 'Edit Article',
    articleSaved: 'Article Saved',
    editorHint: 'Enter Markdown content...',
    titleHint: 'Enter title...',
    date: 'Date',
    publish: 'Publish',
    publishing: 'Publishing...',
    githubNotConfigured: 'GitHub is not configured',
    settingsTitle: 'Settings',
    notConfigured: 'Not Configured',
    publishSuccess: 'Article published successfully',
    publishFailed: 'Publish failed',
    networkError: 'Network error',
    sectionGithub: 'GitHub Configuration',
    sectionImageHost: 'Image Hosting',
    sectionApp: 'App Settings',
    tabGeneral: 'General',
    tabGithub: 'GitHub',
    tabImageHost: 'Image Hosting',
    githubToken: 'Token',
    githubOwner: 'Owner',
    githubRepo: 'Repository',
    githubBranch: 'Branch',
    imageHostType: 'Hosting Provider',
    imageHostGithub: 'GitHub',
    imageHostUpyun: 'Upyun',
    imageGithubRepo: 'Image Repository',
    imageGithubPath: 'Path',
    imageGithubDomain: 'Custom Domain',
    upyunBucket: 'Bucket',
    upyunBucketHint: 'Service name',
    upyunOperator: 'Operator',
    upyunOperatorHint: 'Operator name',
    upyunPassword: 'Password',
    upyunPasswordHint: 'Operator password',
    upyunDomain: 'Domain',
    upyunDomainHint: 'https://example.upaiyun.com',
    upyunPath: 'Path',
    upyunPathHint: 'images/',
    language: 'Language',
    theme: 'Theme',
    version: 'Version',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    langSystem: 'System',
    langZh: 'Chinese',
    langEn: 'English',
    saveDraft: 'Save Draft',
    synced: 'Synced',
    draftStatus: 'Draft',
    syncFromGitHub: 'Sync from GitHub',
    syncSuccess: 'Sync complete',
    syncFailed: 'Sync failed',
    noArticles: 'No articles yet',
    deleteArticle: 'Delete',
    deleteConfirm: 'Are you sure you want to delete this article?',
    cancel: 'Cancel',
    pushToDraft: 'Save as Draft',
    repoDraft: 'Repo Draft',
    remoteDeleted: 'Remote Deleted',
    metadata: 'Metadata',
    done: 'Done',
    tags: 'Tags',
    tagsHint: 'Comma separated, e.g: Flutter, Dart',
    categories: 'Categories',
    categoriesHint: 'One per line',
    permalink: 'Permalink',
    permalinkHint: '/articles/2024/01/01/hello.html',
    topImg: 'Top Image',
    topImgHint: 'Header image URL',
    cover: 'Cover',
    coverHint: 'Cover image URL',
    layout: 'Layout',
    layoutPost: 'Post',
    layoutDraft: 'Draft',
    layoutPage: 'Page',
    comments: 'Comments',
    published: 'Published',
    excerpt: 'Excerpt',
    excerptHint: 'Article summary...',
    description: 'Description',
    descriptionHint: 'Article description...',
    author: 'Author',
    authorHint: 'Author name',
  );

  static const zh = AppStrings._(
    appTitle: 'Inkflow',
    homeTitle: 'Inkflow',
    subtitle: 'Markdown 博客发布工具',
    newArticle: '新建文章',
    editorTitle: '编辑文章',
    articleSaved: '文章已保存',
    editorHint: '输入 Markdown 内容...',
    titleHint: '输入标题...',
    date: '日期',
    publish: '发布',
    publishing: '发布中...',
    githubNotConfigured: 'GitHub 未配置',
    settingsTitle: '设置',
    notConfigured: '未配置',
    publishSuccess: '文章发布成功',
    publishFailed: '发布失败',
    networkError: '网络错误',
    sectionGithub: 'GitHub 配置',
    sectionImageHost: '图床配置',
    sectionApp: '应用设置',
    tabGeneral: '通用',
    tabGithub: 'GitHub',
    tabImageHost: '图床',
    githubToken: 'Token',
    githubOwner: 'Owner',
    githubRepo: '仓库',
    githubBranch: '分支',
    imageHostType: '图床提供商',
    imageHostGithub: 'GitHub',
    imageHostUpyun: '又拍云',
    imageGithubRepo: '图片仓库',
    imageGithubPath: '路径',
    imageGithubDomain: '自定义域名',
    upyunBucket: '空间名称',
    upyunBucketHint: '服务名称',
    upyunOperator: '操作员',
    upyunOperatorHint: '操作员名称',
    upyunPassword: '操作员密码',
    upyunPasswordHint: '操作员密码',
    upyunDomain: '域名',
    upyunDomainHint: 'https://example.upaiyun.com',
    upyunPath: '路径',
    upyunPathHint: 'images/',
    language: '语言',
    theme: '主题',
    version: '版本',
    themeSystem: '跟随系统',
    themeLight: '浅色',
    themeDark: '深色',
    langSystem: '跟随系统',
    langZh: '中文',
    langEn: '英文',
    saveDraft: '保存草稿',
    synced: '已同步',
    draftStatus: '草稿',
    syncFromGitHub: '从 GitHub 同步',
    syncSuccess: '同步完成',
    syncFailed: '同步失败',
    noArticles: '暂无文章',
    deleteArticle: '删除',
    deleteConfirm: '确认删除这篇文章？',
    cancel: '取消',
    pushToDraft: '存为草稿',
    repoDraft: '仓库草稿',
    remoteDeleted: '远程已删除',
    metadata: '元数据',
    done: '完成',
    tags: '标签',
    tagsHint: '逗号分隔，如: Flutter, Dart',
    categories: '分类',
    categoriesHint: '每行一个',
    permalink: '永久链接',
    permalinkHint: '/articles/2024/01/01/hello.html',
    topImg: '头图',
    topImgHint: '头图 URL',
    cover: '封面',
    coverHint: '封面图片 URL',
    layout: '布局',
    layoutPost: '文章',
    layoutDraft: '草稿',
    layoutPage: '页面',
    comments: '评论',
    published: '发布',
    excerpt: '摘要',
    excerptHint: '文章摘要...',
    description: '描述',
    descriptionHint: '文章描述...',
    author: '作者',
    authorHint: '作者名称',
  );

  static AppStrings get current => forLocale(
        PlatformDispatcher.instance.locale,
      );

  static AppStrings forLocale(Locale locale) {
    if (locale.languageCode == 'zh') return zh;
    return en;
  }
}
