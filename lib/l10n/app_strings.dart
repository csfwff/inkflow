import 'dart:ui';
import '../models/settings.dart';

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
  final String themeMode;
  final String themeColor;
  final String langSystem;
  final String langZh;
  final String langEn;

  // Article list
  final String saveDraft;
  final String synced;
  final String draftStatus;
  final String pendingPublish;
  final String syncFromGitHub;
  final String syncSuccess;
  final String syncFailed;
  final String syncDeletionCheckSkipped;
  final String noArticles;
  final String deleteArticle;
  final String deleteConfirm;
  final String deleteConfirmRemote;
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
  final String generatePermalink;
  final String topImg;
  final String topImgHint;
  final String cover;
  final String coverHint;
  final String excerpt;
  final String excerptHint;
  final String description;
  final String descriptionHint;
  final String author;
  final String authorHint;
  final String customFields;
  final String addCustomField;
  final String customFieldKeyHint;
  final String customFieldValueHint;
  final String selectFromExisting;
  final String addNewHint;
  final String selectTags;
  final String selectCategories;
  final String noItemsAvailable;

  // Unsaved changes
  final String unsavedChanges;
  final String unsavedChangesDesc;
  final String discard;

  // Image picker
  final String selectImage;
  final String uploadImage;
  final String fromArticle;
  final String inputUrl;
  final String noImagesInArticle;
  final String imageHostNotConfigured;
  final String imageUploadFailed;

  // Sync
  final String incrementalSync;
  final String incrementalSyncDesc;
  final String fullSync;
  final String fullSyncDesc;

  // Danger zone
  final String dangerZone;
  final String clearArticleData;
  final String clearArticleDataDesc;
  final String clearArticleDataWarning;
  final String clearArticleDataConfirm;

  // Import / Export
  final String exportConfig;
  final String importConfig;
  final String exportSuccess;
  final String importSuccess;
  final String importFailed;
  final String includeSensitive;
  final String enterPassword;
  final String passwordHint;
  final String importConfigHint;
  final String importConfigConfirm;

  // Log viewer
  final String logViewer;
  final String logAll;
  final String logInfo;
  final String logWarn;
  final String logError;
  final String logUserAction;
  final String logCopyAll;
  final String logClear;
  final String logClearConfirm;
  final String logCopied;
  final String logEmpty;

  // Image compression
  final String imageCompress;
  final String imageCompressDesc;
  final String imageCompressTarget;
  final String imageCompressUnlimited;
  final String imageCompressResult;

  // Friend links
  final String friendLinks;
  final String addFriendLink;
  final String editFriendLink;
  final String deleteFriendLink;
  final String friendLinkName;
  final String friendLinkLink;
  final String friendLinkAvatar;
  final String friendLinkDescr;
  final String friendLinkEnabled;
  final String friendLinkDisabled;
  final String syncFriendLinks;
  final String addDevFriendLink;
  final String pasteYaml;
  final String friendLinkPath;

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
    required this.themeMode,
    required this.themeColor,
    required this.langSystem,
    required this.langZh,
    required this.langEn,
    required this.saveDraft,
    required this.synced,
    required this.draftStatus,
    required this.pendingPublish,
    required this.syncFromGitHub,
    required this.syncSuccess,
    required this.syncFailed,
    required this.syncDeletionCheckSkipped,
    required this.noArticles,
    required this.deleteArticle,
    required this.deleteConfirm,
    required this.deleteConfirmRemote,
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
    required this.generatePermalink,
    required this.topImg,
    required this.topImgHint,
    required this.cover,
    required this.coverHint,
    required this.excerpt,
    required this.excerptHint,
    required this.description,
    required this.descriptionHint,
    required this.author,
    required this.authorHint,
    required this.customFields,
    required this.addCustomField,
    required this.customFieldKeyHint,
    required this.customFieldValueHint,
    required this.selectFromExisting,
    required this.addNewHint,
    required this.selectTags,
    required this.selectCategories,
    required this.noItemsAvailable,
    required this.selectImage,
    required this.uploadImage,
    required this.fromArticle,
    required this.inputUrl,
    required this.noImagesInArticle,
    required this.imageHostNotConfigured,
    required this.imageUploadFailed,
    required this.incrementalSync,
    required this.incrementalSyncDesc,
    required this.fullSync,
    required this.fullSyncDesc,
    required this.dangerZone,
    required this.clearArticleData,
    required this.clearArticleDataDesc,
    required this.clearArticleDataWarning,
    required this.clearArticleDataConfirm,
    required this.exportConfig,
    required this.importConfig,
    required this.exportSuccess,
    required this.importSuccess,
    required this.importFailed,
    required this.includeSensitive,
    required this.enterPassword,
    required this.passwordHint,
    required this.importConfigHint,
    required this.importConfigConfirm,
    required this.unsavedChanges,
    required this.unsavedChangesDesc,
    required this.discard,
    // Log viewer
    required this.logViewer,
    required this.logAll,
    required this.logInfo,
    required this.logWarn,
    required this.logError,
    required this.logUserAction,
    required this.logCopyAll,
    required this.logClear,
    required this.logClearConfirm,
    required this.logCopied,
    required this.logEmpty,
    // Image compression
    required this.imageCompress,
    required this.imageCompressDesc,
    required this.imageCompressTarget,
    required this.imageCompressUnlimited,
    required this.imageCompressResult,
    // Friend links
    required this.friendLinks,
    required this.addFriendLink,
    required this.editFriendLink,
    required this.deleteFriendLink,
    required this.friendLinkName,
    required this.friendLinkLink,
    required this.friendLinkAvatar,
    required this.friendLinkDescr,
    required this.friendLinkEnabled,
    required this.friendLinkDisabled,
    required this.syncFriendLinks,
    required this.addDevFriendLink,
    required this.pasteYaml,
    required this.friendLinkPath,
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
    upyunDomainHint: 'Bound domain with http or https',
    upyunPath: 'Path',
    upyunPathHint: '',
    language: 'Language',
    theme: 'Theme',
    version: 'Version',
    themeSystem: 'System',
    themeLight: 'Light',
    themeDark: 'Dark',
    themeMode: 'Mode',
    themeColor: 'Theme Color',
    langSystem: 'System',
    langZh: 'Chinese',
    langEn: 'English',
    saveDraft: 'Save Draft',
    synced: 'Synced',
    draftStatus: 'Draft',
    pendingPublish: 'Pending Publish',
    syncFromGitHub: 'Sync from GitHub',
    syncSuccess: 'Sync complete',
    syncFailed: 'Sync failed',
    syncDeletionCheckSkipped:
        'Remote deletion check was skipped because an article directory was not found',
    noArticles: 'No articles yet',
    deleteArticle: 'Delete',
    deleteConfirm: 'Are you sure you want to delete this article?',
    deleteConfirmRemote:
        'This article is synced to the remote repository. Deleting will also remove the remote file. Continue?',
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
    generatePermalink: 'Generate',
    topImg: 'Top Image',
    topImgHint: 'Header image URL',
    cover: 'Cover',
    coverHint: 'Cover image URL',
    excerpt: 'Excerpt',
    excerptHint: 'Article summary...',
    description: 'Description',
    descriptionHint: 'Article description...',
    author: 'Author',
    authorHint: 'Author name',
    customFields: 'Custom Fields',
    addCustomField: 'Add Field',
    customFieldKeyHint: 'Key',
    customFieldValueHint: 'Value',
    selectFromExisting: 'Select',
    addNewHint: 'Type and press Enter to add',
    selectTags: 'Select Tags',
    selectCategories: 'Select Categories',
    noItemsAvailable: 'No items available',
    selectImage: 'Select Image',
    uploadImage: 'Upload',
    fromArticle: 'From Article',
    inputUrl: 'Input URL',
    noImagesInArticle: 'No images in article',
    imageHostNotConfigured: 'Image host not configured',
    imageUploadFailed: 'Upload failed',
    incrementalSync: 'Incremental Sync',
    incrementalSyncDesc: 'Only sync changed files since last sync',
    fullSync: 'Full Sync',
    fullSyncDesc: 'Sync all files from remote',
    dangerZone: 'Danger Zone',
    clearArticleData: 'Clear Article Data',
    clearArticleDataDesc: 'Delete all local articles, tags, and categories',
    clearArticleDataWarning:
        'This will permanently delete all local article data and cannot be undone. Remote articles will not be affected.',
    clearArticleDataConfirm: 'Clear All',
    exportConfig: 'Export Config',
    importConfig: 'Import Config',
    exportSuccess: 'Config exported to clipboard',
    importSuccess: 'Config imported successfully',
    importFailed: 'Import failed, please check the data and password',
    includeSensitive: 'Include sensitive credentials (Token, Password)',
    enterPassword: 'Enter Password',
    passwordHint: 'Password for encryption/decryption',
    importConfigHint: 'Paste the exported config string',
    importConfigConfirm: 'Decrypt & Import',
    unsavedChanges: 'Unsaved Changes',
    unsavedChangesDesc:
        'You have unsaved changes. Are you sure you want to leave?',
    discard: 'Discard',
    // Log viewer
    logViewer: 'View Logs',
    logAll: 'All',
    logInfo: 'Info',
    logWarn: 'Warn',
    logError: 'Error',
    logUserAction: 'User Actions',
    logCopyAll: 'Copy All',
    logClear: 'Clear Logs',
    logClearConfirm: 'Clear all logs?',
    logCopied: 'Logs copied',
    logEmpty: 'No logs',
    // Image compression
    imageCompress: 'Image Compression',
    imageCompressDesc: 'Compress images before uploading to save storage',
    imageCompressTarget: 'Target Size',
    imageCompressUnlimited: 'Unlimited',
    imageCompressResult: 'Compressed',
    // Friend links
    friendLinks: 'Friend Links',
    addFriendLink: 'Add Friend Link',
    editFriendLink: 'Edit Friend Link',
    deleteFriendLink: 'Delete Friend Link',
    friendLinkName: 'Name',
    friendLinkLink: 'Link',
    friendLinkAvatar: 'Avatar',
    friendLinkDescr: 'Description',
    friendLinkEnabled: 'Enabled',
    friendLinkDisabled: 'Disabled',
    syncFriendLinks: 'Sync Friend Links',
    addDevFriendLink: 'Add Author Link',
    pasteYaml: 'Paste from YAML',
    friendLinkPath: 'Friend Link File Path',
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
    upyunDomainHint: '空间绑定的域名，带上 http 或 https',
    upyunPath: '路径',
    upyunPathHint: '',
    language: '语言',
    theme: '主题',
    version: '版本',
    themeSystem: '跟随系统',
    themeLight: '浅色',
    themeDark: '深色',
    themeMode: '模式',
    themeColor: '主题色',
    langSystem: '跟随系统',
    langZh: '中文',
    langEn: '英文',
    saveDraft: '保存草稿',
    synced: '已同步',
    draftStatus: '草稿',
    pendingPublish: '待发布',
    syncFromGitHub: '从 GitHub 同步',
    syncSuccess: '同步完成',
    syncFailed: '同步失败',
    syncDeletionCheckSkipped: '未找到文章目录，已跳过远端删除检查',
    noArticles: '暂无文章',
    deleteArticle: '删除',
    deleteConfirm: '确认删除这篇文章？',
    deleteConfirmRemote: '此文章已同步到远程仓库，删除后远程文件也会被一并删除。是否继续？',
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
    generatePermalink: '自动生成',
    topImg: '头图',
    topImgHint: '头图 URL',
    cover: '封面',
    coverHint: '封面图片 URL',
    excerpt: '摘要',
    excerptHint: '文章摘要...',
    description: '描述',
    descriptionHint: '文章描述...',
    author: '作者',
    authorHint: '作者名称',
    customFields: '自定义字段',
    addCustomField: '添加字段',
    customFieldKeyHint: '字段名',
    customFieldValueHint: '字段值',
    selectFromExisting: '从已有选择',
    addNewHint: '输入后按回车添加',
    selectTags: '选择标签',
    selectCategories: '选择分类',
    noItemsAvailable: '暂无可用项',
    selectImage: '选择图片',
    uploadImage: '上传图片',
    fromArticle: '从文章选择',
    inputUrl: '手动输入',
    noImagesInArticle: '文章中没有图片',
    imageHostNotConfigured: '图床未配置',
    imageUploadFailed: '上传失败',
    incrementalSync: '增量同步',
    incrementalSyncDesc: '只同步上次同步后变更的文件',
    fullSync: '全量同步',
    fullSyncDesc: '同步远程所有文件',
    dangerZone: '危险操作',
    clearArticleData: '清除文章数据',
    clearArticleDataDesc: '删除本地所有文章、标签和分类数据',
    clearArticleDataWarning: '此操作将永久删除本地所有文章数据，且无法恢复。远程仓库中的文章不会受到影响。',
    clearArticleDataConfirm: '确认清除',
    exportConfig: '导出配置',
    importConfig: '导入配置',
    exportSuccess: '配置已复制到剪贴板',
    importSuccess: '配置导入成功',
    importFailed: '导入失败，请检查数据和密码',
    includeSensitive: '包含敏感凭据（Token、密码）',
    enterPassword: '输入密码',
    passwordHint: '用于加密/解密配置',
    importConfigHint: '粘贴导出的配置字符串',
    importConfigConfirm: '解密导入',
    unsavedChanges: '未保存的更改',
    unsavedChangesDesc: '你有未保存的更改，确定要离开吗？',
    discard: '放弃',
    // Log viewer
    logViewer: '查看日志',
    logAll: '全部',
    logInfo: '信息',
    logWarn: '警告',
    logError: '错误',
    logUserAction: '用户操作',
    logCopyAll: '复制全部',
    logClear: '清空日志',
    logClearConfirm: '确认清空所有日志？',
    logCopied: '日志已复制',
    logEmpty: '暂无日志',
    // Image compression
    imageCompress: '图片压缩',
    imageCompressDesc: '上传前压缩图片以节省存储空间',
    imageCompressTarget: '目标大小',
    imageCompressUnlimited: '不限',
    imageCompressResult: '已压缩',
    // Friend links
    friendLinks: '友链管理',
    addFriendLink: '添加友链',
    editFriendLink: '编辑友链',
    deleteFriendLink: '删除友链',
    friendLinkName: '名称',
    friendLinkLink: '链接',
    friendLinkAvatar: '头像',
    friendLinkDescr: '简介',
    friendLinkEnabled: '启用',
    friendLinkDisabled: '已禁用',
    syncFriendLinks: '同步友链',
    addDevFriendLink: '添加作者友链',
    pasteYaml: '从 YAML 粘贴',
    friendLinkPath: '友链文件路径',
  );

  /// 应用当前语言设置，默认跟随系统。
  static AppLocale _locale = AppLocale.system;

  /// 更新应用语言设置。
  static void setLocale(AppLocale locale) {
    _locale = locale;
  }

  /// 当前语言包，基于应用设置而非系统 locale。
  static AppStrings get current => forLocale(_resolvedLocale);

  /// 当前是否为中文。
  static bool get isZh => identical(current, zh);

  static Locale get _resolvedLocale {
    switch (_locale) {
      case AppLocale.zh:
        return const Locale('zh');
      case AppLocale.en:
        return const Locale('en');
      case AppLocale.system:
        return PlatformDispatcher.instance.locale;
    }
  }

  static AppStrings forLocale(Locale locale) {
    if (locale.languageCode == 'zh') return zh;
    return en;
  }
}
