import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/editor_recovery_service.dart';
import '../services/editor_tools_service.dart';
import '../services/frontmatter_helper.dart';
import '../services/github_service.dart';
import '../services/image_host/image_host_service.dart';
import '../services/log_service.dart';
import '../services/publish_preflight_service.dart';
import '../services/sync_service.dart';
import '../services/text_diff_service.dart';
import '../widgets/responsive.dart';
import 'metadata_page.dart';

/// 窄屏吸顶工具条的固定高度（40 的按钮 + 上下各 8 内边距 + 底部分隔线，留一点余量）。
const double _kEditorToolbarHeight = 58;

class EditorPage extends StatefulWidget {
  final int? articleId;

  const EditorPage({super.key, this.articleId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _contentFocus = FocusNode();
  final _recoveryService = EditorRecoveryService();

  DateTime _selectedDate = DateTime.now();
  bool _publishing = false;
  bool _uploading = false;
  bool _previewMode = false;
  bool _dirty = false;
  bool _updatingFields = false;
  bool _autoSaving = false;
  bool _resolvingConflict = false;
  String _previewText = '';
  String _originalFrontmatter = ''; // 保留原始 frontmatter
  String? _baseRemoteContent;
  DateTime? _lastAutoSavedAt;
  Timer? _autoSaveTimer;
  int _editorRevision = 0;
  Article? _editingArticle;

  static const _autoSaveDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_handleTitleChanged);
    _contentCtrl.addListener(_handleContentChanged);
    if (widget.articleId != null) {
      _loadArticle(widget.articleId!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_maybeRestoreRecovery());
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    if (_dirty) {
      unawaited(_saveRecoveryOnly());
    }
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _handleTitleChanged() {
    if (_updatingFields) return;
    _editorRevision++;
    _scheduleAutoSave();
    if (!_dirty) setState(() => _dirty = true);
  }

  void _handleContentChanged() {
    if (_updatingFields) return;
    _editorRevision++;
    _scheduleAutoSave();
    setState(() {
      _previewText = _contentCtrl.text;
      _dirty = true;
    });
  }

  Future<void> _loadArticle(int id) async {
    final article = await articleService.getById(id);
    if (article != null && mounted) {
      final body = article.bodyContent;
      // 保留原始 frontmatter（含不支持的字段）
      final fmMatch = RegExp(
        r'^---\s*\n(.*?)\n---\s*\n',
        dotAll: true,
      ).firstMatch(article.content);
      _updatingFields = true;
      setState(() {
        _editingArticle = article;
        _originalFrontmatter = fmMatch != null ? fmMatch.group(1)! : '';
        _titleCtrl.text = article.title;
        _contentCtrl.text = body;
        _selectedDate = article.date;
        _previewText = body;
        _dirty = false;
        _baseRemoteContent =
            article.status == ArticleStatus.synced ||
                article.status == ArticleStatus.repoDraft
            ? article.content
            : null;
      });
      _updatingFields = false;
      await _maybeRestoreRecovery(article);
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        // 保留 Unicode 字母/数字（含中文），去掉其余符号；空白转连字符。
        // 这一步已滤掉所有跨平台非法字符：\ / : * ? " < > | 及控制符等。
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// 由标题生成文件系统安全的 slug：
  /// 非法字符已由 [_slugify] 的白名单滤除；此处再避开 Windows 保留设备名
  /// （CON/NUL/COM1… 用作文件名会报错），并对空结果用时间戳兜底，避免只剩 ".md"。
  String _safeSlug(String title) {
    var slug = _slugify(title);
    const reserved = {
      'con',
      'prn',
      'aux',
      'nul',
      'com1',
      'com2',
      'com3',
      'com4',
      'com5',
      'com6',
      'com7',
      'com8',
      'com9',
      'lpt1',
      'lpt2',
      'lpt3',
      'lpt4',
      'lpt5',
      'lpt6',
      'lpt7',
      'lpt8',
      'lpt9',
    };
    if (reserved.contains(slug)) {
      slug = 'post-$slug';
    }
    if (slug.isEmpty) {
      slug = 'post-${_selectedDate.millisecondsSinceEpoch ~/ 1000}';
    }
    return slug;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dirty = true;
      });
      _editorRevision++;
      _scheduleAutoSave();
    }
  }

  Article _buildArticle() {
    final title = _titleCtrl.text.trim();
    final slug = _safeSlug(title);
    final category = _editingArticle?.categories.isNotEmpty == true
        ? _editingArticle!.categories.first
        : '';

    // 已同步的文章保留原 filePath，避免路径模板变更后重新发布导致重复
    final filePath =
        (_editingArticle?.githubSha != null &&
            _editingArticle!.filePath.isNotEmpty)
        ? Article.normalizeRelativeFilePath(_editingArticle!.filePath)
        : Article.buildArticleFilePath(
            directoryPattern: settingsService.settings.githubPathPattern,
            date: _selectedDate,
            slug: slug,
            category: category,
          );
    // permalink 不再自动生成，保留已有值（由用户在元数据页手动生成或输入）

    // 合并：原始 frontmatter + 编辑后的正文
    final fullContent = _originalFrontmatter.isNotEmpty
        ? '---\n$_originalFrontmatter\n---\n${_contentCtrl.text}'
        : _contentCtrl.text;

    return Article(
      id: _editingArticle?.id,
      title: title,
      content: fullContent,
      date: _selectedDate,
      slug: slug,
      status: _editingArticle?.status ?? ArticleStatus.draft,
      filePath: filePath,
      remotePath: _editingArticle?.remotePath,
      remoteKind: _editingArticle?.remoteKind,
      githubSha: _editingArticle?.githubSha,
      createdAt: _editingArticle?.createdAt,
      tags: _editingArticle?.tags ?? [],
      categories: _editingArticle?.categories ?? [],
      permalink: _editingArticle?.permalink,
      topImg: _editingArticle?.topImg,
      cover: _editingArticle?.cover,
      excerpt: _editingArticle?.excerpt,
      description: _editingArticle?.description,
      author: _editingArticle?.author,
      customFields: _editingArticle?.customFields ?? {},
    );
  }

  ArticleStatus _statusAfterLocalSave(Article article) {
    return switch (article.status) {
      ArticleStatus.synced ||
      ArticleStatus.repoDraft ||
      ArticleStatus.pendingPublish => ArticleStatus.pendingPublish,
      ArticleStatus.draft => ArticleStatus.draft,
      ArticleStatus.remoteDeleted => ArticleStatus.remoteDeleted,
    };
  }

  Future<void> _openMetadata() async {
    if (_editingArticle == null) {
      // 新文章需要先保存一次，拿到 id
      final saved = await _saveDraft(showMessage: false);
      if (!saved || !mounted) return;
    }

    final old = _editingArticle!;
    // 快照元数据，因为 MetadataPage 会直接修改 old 对象
    final oldTags = List<String>.from(old.tags);
    final oldCategories = List<String>.from(old.categories);
    final oldPermalink = old.permalink;
    final oldTopImg = old.topImg;
    final oldCover = old.cover;
    final oldExcerpt = old.excerpt;
    final oldDescription = old.description;
    final oldAuthor = old.author;
    final oldCustomFields = Map<String, dynamic>.from(old.customFields);

    final result = await Navigator.push<Article>(
      context,
      MaterialPageRoute(
        builder: (_) => MetadataPage(
          article: old,
          settingsService: settingsService,
          articleService: articleService,
        ),
      ),
    );

    if (result != null && mounted) {
      final changed =
          !_listEquals(result.tags, oldTags) ||
          !_listEquals(result.categories, oldCategories) ||
          _neq(result.permalink, oldPermalink) ||
          _neq(result.topImg, oldTopImg) ||
          _neq(result.cover, oldCover) ||
          _neq(result.excerpt, oldExcerpt) ||
          _neq(result.description, oldDescription) ||
          _neq(result.author, oldAuthor) ||
          !_mapEquals(result.customFields, oldCustomFields);
      setState(() {
        _editingArticle = result;
        if (changed) _dirty = true;
      });
      if (changed) {
        _editorRevision++;
        _scheduleAutoSave();
      }
    }
  }

  String get _recoveryKey =>
      _recoveryService.recoveryKeyForArticle(_editingArticle?.id);

  EditorRecovery _buildRecovery() => EditorRecovery(
    title: _titleCtrl.text,
    body: _contentCtrl.text,
    date: _selectedDate,
    savedAt: DateTime.now(),
  );

  void _scheduleAutoSave() {
    if (_updatingFields || _publishing || _resolvingConflict) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () => unawaited(_autoSave()));
  }

  Future<void> _saveRecoveryOnly() async {
    final hasContent =
        _editingArticle != null ||
        _titleCtrl.text.isNotEmpty ||
        _contentCtrl.text.isNotEmpty;
    if (!hasContent) return;
    await _recoveryService.saveRecovery(_recoveryKey, _buildRecovery());
  }

  Future<void> _autoSave() async {
    if (!_dirty || _autoSaving || _publishing || _resolvingConflict) return;
    final versionBeforeSave = _editorRevision;
    await _saveRecoveryOnly();
    if (_titleCtrl.text.trim().isEmpty) return;

    if (mounted) setState(() => _autoSaving = true);
    Article? saved;
    try {
      saved = await _persistLocal();
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Editor',
        context: '自动保存失败',
      );
    }
    if (!mounted) return;
    _autoSaving = false;
    if (saved == null) {
      setState(() {});
      return;
    }

    if (versionBeforeSave == _editorRevision) {
      setState(() {
        _dirty = false;
        _lastAutoSavedAt = DateTime.now();
      });
    } else {
      setState(() {});
      _scheduleAutoSave();
    }
  }

  Future<Article?> _persistLocal() async {
    final previous = _editingArticle;
    final previousRecoveryKey = _recoveryKey;
    final article = _buildArticle();

    if (previous != null) {
      await _recoveryService.saveRevision(previous);
      article.status = _statusAfterLocalSave(previous);
      article.updatedAt = DateTime.now();
      await articleService.update(article);
      _editingArticle = article;
    } else {
      final id = await articleService.insert(article);
      _editingArticle = await articleService.getById(id);
    }

    await articleService.ensureTags(article.tags);
    await articleService.ensureCategories(article.categories);
    await _recoveryService.clearRecovery(previousRecoveryKey);
    await _recoveryService.clearRecovery(_recoveryKey);
    return _editingArticle;
  }

  Future<bool> _saveDraft({bool showMessage = true}) async {
    final s = AppStrings.current;
    final title = _titleCtrl.text.trim();

    LogService.instance.logAction('保存草稿', detail: title);
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.titleHint)));
      return false;
    }

    await _saveRecoveryOnly();
    final article = await _persistLocal();
    if (article == null || !mounted) return false;
    setState(() => _dirty = false);

    if (showMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.articleSaved)));
    }
    return true;
  }

  Future<void> _maybeRestoreRecovery([Article? article]) async {
    final key = _recoveryService.recoveryKeyForArticle(article?.id);
    final recovery = await _recoveryService.loadRecovery(key);
    if (recovery == null || !mounted) return;

    if (article != null && !recovery.savedAt.isAfter(article.updatedAt)) {
      await _recoveryService.clearRecovery(key);
      return;
    }

    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_label('发现本地恢复内容', 'Local recovery found')),
        content: Text(
          _label(
            '检测到 ${_formatRecoveryTime(recovery.savedAt)} 自动保存的内容。是否恢复？',
            'Auto-saved content from ${_formatRecoveryTime(recovery.savedAt)} was found. Restore it?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_label('忽略', 'Discard')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_label('恢复', 'Restore')),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (restore == true) {
      _updatingFields = true;
      setState(() {
        _titleCtrl.text = recovery.title;
        _contentCtrl.text = recovery.body;
        _selectedDate = recovery.date;
        _previewText = recovery.body;
        _dirty = true;
      });
      _updatingFields = false;
      _editorRevision++;
      _scheduleAutoSave();
    } else {
      await _recoveryService.clearRecovery(key);
    }
  }

  String _formatRecoveryTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmPublishPreflight() async {
    final issues = PublishPreflightService.check(
      title: _titleCtrl.text,
      body: _contentCtrl.text,
    );
    if (issues.isEmpty) return true;
    final hasErrors = issues.any(
      (issue) => issue.severity == PublishIssueSeverity.error,
    );

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_label('发布前检查', 'Pre-publish check')),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasErrors
                    ? _label(
                        '请先处理以下问题：',
                        'Resolve these issues before publishing:',
                      )
                    : _label(
                        '发现以下提醒，仍要继续发布吗？',
                        'Warnings were found. Publish anyway?',
                      ),
              ),
              const SizedBox(height: 12),
              ...issues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        issue.severity == PublishIssueSeverity.error
                            ? Icons.error_outline
                            : Icons.warning_amber_outlined,
                        color: issue.severity == PublishIssueSeverity.error
                            ? Theme.of(ctx).colorScheme.error
                            : const Color(0xFF9A6A1F),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_publishIssueLabel(issue))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              hasErrors
                  ? _label('返回修改', 'Back to edit')
                  : AppStrings.current.cancel,
            ),
          ),
          if (!hasErrors)
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_label('继续发布', 'Publish anyway')),
            ),
        ],
      ),
    );
    return shouldContinue == true;
  }

  String _publishIssueLabel(PublishIssue issue) {
    return switch (issue.code) {
      PublishIssueCode.emptyTitle => _label(
        '文章标题不能为空',
        'Article title is required',
      ),
      PublishIssueCode.emptyBody => _label(
        '文章正文不能为空',
        'Article body is required',
      ),
      PublishIssueCode.emptyLinkTarget => _label(
        '发现空链接或图片地址',
        'An empty link or image target was found',
      ),
      PublishIssueCode.malformedLink => _label(
        '链接地址可能无效：${issue.detail}',
        'A link target may be invalid: ${issue.detail}',
      ),
      PublishIssueCode.unclosedCodeFence => _label(
        '代码块围栏未闭合',
        'A fenced code block is not closed',
      ),
    };
  }

  Future<void> _publish({bool drafts = false}) async {
    if (_publishing || _resolvingConflict) return;
    final s = AppStrings.current;
    final settings = settingsService.settings;

    LogService.instance.logAction('发布文章', detail: drafts ? '存为草稿' : '正式发布');

    if (settings.githubToken.isEmpty ||
        settings.githubOwner.isEmpty ||
        settings.githubRepo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.githubNotConfigured)));
      return;
    }

    if (!await _confirmPublishPreflight()) return;
    final title = _titleCtrl.text.trim();

    setState(() => _publishing = true);

    final article = _buildArticle();
    final fileName = article.filePath;
    final fullContent = article.fullContent;

    final service = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
      branch: settings.githubBranch,
    );

    final targetStatus = drafts
        ? ArticleStatus.repoDraft
        : ArticleStatus.synced;
    final targetRemoteKind = drafts
        ? ArticleRemoteKind.repoDraft
        : ArticleRemoteKind.post;
    final targetRemotePath = Article.buildRemotePath(
      kind: targetRemoteKind,
      filePath: fileName,
    );
    final previousRemotePath = _editingArticle?.remotePath;
    final previousSha = _editingArticle?.githubSha;
    final commitPrefix = drafts ? 'draft' : 'post';

    GitHubResult result;

    if (previousSha != null &&
        previousSha.isNotEmpty &&
        previousRemotePath == targetRemotePath) {
      result = await service.updateFile(
        remotePath: targetRemotePath,
        content: fullContent,
        sha: previousSha,
        commitMessage: '$commitPrefix: update $title',
      );
    } else if (previousRemotePath != null &&
        previousRemotePath.isNotEmpty &&
        previousSha != null &&
        previousSha.isNotEmpty) {
      // 草稿和正式文章之间切换需要同时创建目标并删除来源。使用 Git Data
      // API 的单个 commit，避免 Contents API 两步调用只成功一半。
      result = await service.moveFileAtomically(
        sourcePath: previousRemotePath,
        sourceSha: previousSha,
        targetPath: targetRemotePath,
        content: fullContent,
        commitMessage: '$commitPrefix: move $title',
      );
    } else {
      result = await service.createFile(
        remotePath: targetRemotePath,
        content: fullContent,
        commitMessage: '$commitPrefix: $title',
      );
    }

    if (!mounted) return;
    setState(() => _publishing = false);

    if (!result.success &&
        result.isConflict &&
        previousRemotePath != null &&
        previousRemotePath == targetRemotePath &&
        previousSha != null &&
        previousSha.isNotEmpty) {
      await _resolvePublishConflict(
        service: service,
        localArticle: article,
        remotePath: targetRemotePath,
        targetStatus: targetStatus,
        targetRemoteKind: targetRemoteKind,
        baseSha: previousSha,
      );
      return;
    }

    if (result.success) {
      await _applyPublishSuccess(
        article: article,
        content: fullContent,
        sha: result.sha,
        status: targetStatus,
        remotePath: targetRemotePath,
        remoteKind: targetRemoteKind,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _applyPublishSuccess({
    required Article article,
    required String content,
    required String? sha,
    required ArticleStatus status,
    required String remotePath,
    required ArticleRemoteKind remoteKind,
  }) async {
    article.content = content;
    article.status = status;
    article.remotePath = remotePath;
    article.remoteKind = remoteKind;
    article.githubSha = sha;

    if (_editingArticle != null) {
      article.updatedAt = DateTime.now();
      await articleService.update(article);
      _editingArticle = article;
    } else {
      final id = await articleService.insert(article);
      _editingArticle = await articleService.getById(id);
    }

    _baseRemoteContent = content;
    await _recoveryService.clearRecovery(_recoveryKey);
    if (mounted) {
      setState(() {
        _dirty = false;
        _lastAutoSavedAt = DateTime.now();
      });
    }
  }

  Future<void> _resolvePublishConflict({
    required GitHubService service,
    required Article localArticle,
    required String remotePath,
    required ArticleStatus targetStatus,
    required ArticleRemoteKind targetRemoteKind,
    required String baseSha,
  }) async {
    if (!mounted) return;
    setState(() => _resolvingConflict = true);

    try {
      final remoteResult = await service.getFileContentResult(remotePath);
      if (!remoteResult.success || remoteResult.content == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _label(
                  '无法读取远端最新内容，请同步后重试',
                  'Unable to load the latest remote content. Sync and try again.',
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final baseContent = await _loadConflictBase(service, baseSha);
      if (!mounted) return;
      final remoteBody = FrontmatterHelper.extractBody(
        remoteResult.content!.content,
      );
      final baseBody = FrontmatterHelper.extractBody(baseContent);
      final choice = await showDialog<_ConflictChoice>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ConflictResolutionDialog(
          base: baseBody,
          local: _contentCtrl.text,
          remote: remoteBody,
          label: _label,
        ),
      );
      if (choice == null || !mounted) return;

      if (choice == _ConflictChoice.useRemote) {
        await _useRemoteConflictVersion(service, localArticle);
        return;
      }

      var articleToPublish = localArticle;
      if (choice == _ConflictChoice.manualMerge) {
        final mergedBody = await _showManualMergeDialog(
          base: baseBody,
          local: _contentCtrl.text,
          remote: remoteBody,
        );
        if (mergedBody == null || !mounted) return;
        _updatingFields = true;
        setState(() {
          _contentCtrl.text = mergedBody;
          _previewText = mergedBody;
          _dirty = true;
        });
        _updatingFields = false;
        _editorRevision++;
        articleToPublish = _buildArticle();
      }

      final retry = await service.updateFile(
        remotePath: remotePath,
        content: articleToPublish.fullContent,
        sha: remoteResult.content!.sha,
        commitMessage: 'post: resolve conflict ${articleToPublish.title}',
      );
      if (retry.success) {
        await _applyPublishSuccess(
          article: articleToPublish,
          content: articleToPublish.fullContent,
          sha: retry.sha,
          status: targetStatus,
          remotePath: remotePath,
          remoteKind: targetRemoteKind,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(retry.message),
          backgroundColor: retry.success ? Colors.green : Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _resolvingConflict = false);
    }
  }

  Future<String> _loadConflictBase(
    GitHubService service,
    String baseSha,
  ) async {
    final cached = _baseRemoteContent;
    if (cached != null) return cached;
    final base = await service.getBlobContent(baseSha);
    return base.success && base.content != null ? base.content!.content : '';
  }

  Future<void> _useRemoteConflictVersion(
    GitHubService github,
    Article localArticle,
  ) async {
    final sync = SyncService(
      github: github,
      articleService: articleService,
      settingsService: settingsService,
    );
    final remoteArticle = await sync.fetchRemoteArticle(localArticle);
    if (remoteArticle == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _label(
                '远端内容已不可用，未覆盖本地内容',
                'Remote content is unavailable; local content was kept.',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final id = localArticle.id;
    if (id != null) {
      await _recoveryService.saveRevision(localArticle);
      await articleService.replaceWithRemote(remoteArticle);
      await _recoveryService.clearRecovery(
        _recoveryService.recoveryKeyForArticle(id),
      );
      await _loadArticle(id);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_label('已使用远端版本', 'Remote version restored'))),
      );
    }
  }

  Future<String?> _showManualMergeDialog({
    required String base,
    required String local,
    required String remote,
  }) async {
    final controller = TextEditingController(text: local);
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(_label('手工合并', 'Manual merge')),
          content: SizedBox(
            width: 760,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label(
                    '编辑合并后的正文。下方可查看基线和远端版本。',
                    'Edit the merged body. The base and remote versions are shown below.',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 118,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ConflictTextPane(
                          title: _label('基线', 'Base'),
                          text: base,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ConflictTextPane(
                          title: _label('远端', 'Remote'),
                          text: remote,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.current.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text(_label('使用合并结果', 'Use merged result')),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showRevisionHistory() async {
    final article = _editingArticle;
    final id = article?.id;
    if (article == null || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _label('保存文章后即可查看历史版本', 'Save the article to view its history.'),
          ),
        ),
      );
      return;
    }

    final revisions = await _recoveryService.listRevisions(id);
    if (!mounted) return;
    if (revisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_label('暂无历史版本', 'No local history yet'))),
      );
      return;
    }

    final selected = await showModalBottomSheet<ArticleRevision>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 460,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(_label('本地历史版本', 'Local version history')),
                subtitle: Text(
                  _label(
                    '选择一个版本恢复到编辑器',
                    'Select a version to restore into the editor',
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: revisions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final revision = revisions[index];
                    final preview = revision.article.bodyContent
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim();
                    return ListTile(
                      leading: const Icon(Icons.restore_page_outlined),
                      title: Text(_formatRecoveryTime(revision.savedAt)),
                      subtitle: Text(
                        preview.isEmpty
                            ? _label('（空正文）', '(empty body)')
                            : preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(ctx, revision),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await _restoreRevision(selected);
  }

  Future<void> _restoreRevision(ArticleRevision revision) async {
    final current = _editingArticle;
    final id = current?.id;
    if (current == null || id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_label('恢复历史版本', 'Restore history version')),
        content: Text(
          _label(
            '当前内容会先保存为一个历史版本，然后恢复所选版本。',
            'The current content will be saved in history before the selected version is restored.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_label('恢复', 'Restore')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _recoveryService.saveRevision(current);
    final snapshot = revision.article;
    final restored = Article(
      id: id,
      title: snapshot.title,
      content: snapshot.content,
      date: snapshot.date,
      slug: snapshot.slug,
      status: _statusAfterLocalSave(current),
      filePath: current.filePath,
      remotePath: current.remotePath,
      remoteKind: current.remoteKind,
      githubSha: current.githubSha,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      tags: List<String>.from(snapshot.tags),
      categories: List<String>.from(snapshot.categories),
      permalink: snapshot.permalink,
      topImg: snapshot.topImg,
      cover: snapshot.cover,
      excerpt: snapshot.excerpt,
      description: snapshot.description,
      author: snapshot.author,
      customFields: Map<String, dynamic>.from(snapshot.customFields),
    );
    await articleService.update(restored);
    await _recoveryService.clearRecovery(
      _recoveryService.recoveryKeyForArticle(id),
    );
    await _loadArticle(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_label('已恢复历史版本', 'History version restored'))),
      );
    }
  }

  EditorMetrics get _editorMetrics =>
      EditorToolsService.analyze(_contentCtrl.text);

  Future<void> _showOutline() async {
    final headings = _editorMetrics.headings;
    if (headings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_label('文章中暂无标题', 'No headings in this article')),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<EditorHeading>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.format_list_bulleted),
                title: Text(_label('文章大纲', 'Article outline')),
                subtitle: Text(
                  '${headings.length} ${_label('个标题', 'headings')}',
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: headings.length,
                  itemBuilder: (_, index) {
                    final heading = headings[index];
                    return ListTile(
                      contentPadding: EdgeInsets.only(
                        left: 16 + (heading.level - 1) * 18.0,
                        right: 16,
                      ),
                      leading: Text(
                        'H${heading.level}',
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      title: Text(heading.text),
                      trailing: Text('${heading.line}'),
                      onTap: () => Navigator.pop(ctx, heading),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    _contentCtrl.selection = TextSelection.collapsed(offset: selected.offset);
    _contentFocus.requestFocus();
  }

  Future<void> _showFindReplace() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _FindReplaceDialog(
        contentController: _contentCtrl,
        contentFocus: _contentFocus,
        label: _label,
      ),
    );
  }

  Future<void> _restoreFromRemote() async {
    final article = _editingArticle;
    if (article == null ||
        article.status != ArticleStatus.pendingPublish ||
        article.remotePath == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_label('从远端覆盖', 'Restore from remote')),
        content: Text(
          _label(
            '这会放弃本地未发布修改，并用远端最新内容覆盖当前文章。',
            'This discards local unpublished changes and replaces this article with the latest remote content.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_label('覆盖本地', 'Restore')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final settings = settingsService.settings;
    if (settings.githubToken.isEmpty ||
        settings.githubOwner.isEmpty ||
        settings.githubRepo.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.current.githubNotConfigured)),
      );
      return;
    }

    final github = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
      branch: settings.githubBranch,
    );
    final sync = SyncService(
      github: github,
      articleService: articleService,
      settingsService: settingsService,
    );
    final remoteArticle = await sync.fetchRemoteArticle(article);

    if (!mounted) return;
    if (remoteArticle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _label(
              '远端文件不存在或读取失败',
              'Remote file does not exist or could not be read',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (article.id != null) {
      await _recoveryService.saveRevision(article);
      await articleService.replaceWithRemote(remoteArticle);
      await _recoveryService.clearRecovery(
        _recoveryService.recoveryKeyForArticle(article.id),
      );
      await _loadArticle(article.id!);
    } else {
      await articleService.replaceWithRemote(remoteArticle);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_label('已从远端覆盖本地', 'Restored from remote'))),
    );
  }

  Future<void> _pickAndUploadImage() async {
    // Check image host config
    final imageHost = ImageHostService(settings: settingsService.settings);
    if (!imageHost.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _label('请先在设置中配置图床', 'Please configure image host in settings'),
          ),
        ),
      );
      return;
    }

    // Show source picker (gallery / camera)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_label('从相册选择', 'Gallery')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (Theme.of(ctx).platform == TargetPlatform.android ||
                Theme.of(ctx).platform == TargetPlatform.iOS)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(_label('拍照', 'Camera')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Pick image
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 2048);
    if (file == null) return;

    if (!mounted) return;
    setState(() => _uploading = true);

    // Upload (with compression if enabled)
    final bytes = await file.readAsBytes();
    final result = await imageHost.uploadWithCompress(bytes, file.name);

    if (!mounted) return;
    setState(() => _uploading = false);

    if (result.success && result.url != null) {
      _insertBlock('![${file.name}](${result.url})');

      // Show compression effect if compressed
      if (result.wasCompressed && mounted) {
        final compressResult = result.compressResult!;
        final s = AppStrings.current;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${s.imageCompressResult}: ${compressResult.originalSizeFormatted} → ${compressResult.compressedSizeFormatted} '
              '(-${compressResult.ratio.toStringAsFixed(0)}%)',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_label('上传失败', 'Upload failed')}: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final s = AppStrings.current;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.unsavedChanges),
        content: Text(
          '${s.unsavedChangesDesc}\n\n${_label('离开前会保留一份本地恢复内容。', 'A local recovery copy will be kept before leaving.')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppStrings.isZh ? '确认' : 'Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);
    final s = AppStrings.current;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            unawaited(_saveDraft()),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () =>
            unawaited(_saveDraft()),
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
            unawaited(_showFindReplace()),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): () =>
            unawaited(_showFindReplace()),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
            unawaited(_publish()),
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () =>
            unawaited(_publish()),
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final discard = await _confirmDiscard();
            if (discard && context.mounted) {
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _editingArticle == null ? s.newArticle : s.editorTitle,
              ),
              actions: _buildAppBarActions(wide),
            ),
            body: SafeArea(child: wide ? _buildWide() : _buildNarrow()),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(bool wide) {
    final s = AppStrings.current;
    if (_publishing || _resolvingConflict) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    return [
      if (_editingArticle?.status == ArticleStatus.pendingPublish &&
          _editingArticle?.remotePath != null)
        IconButton(
          onPressed: _restoreFromRemote,
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: _label('从远端覆盖', 'Restore from remote'),
        ),
      IconButton(
        onPressed: _showOutline,
        icon: const Icon(Icons.format_list_bulleted),
        tooltip: _label('文章大纲', 'Article outline'),
      ),
      IconButton(
        onPressed: _showFindReplace,
        icon: const Icon(Icons.find_replace),
        tooltip: _label('查找替换', 'Find and replace'),
      ),
      IconButton(
        onPressed: _showRevisionHistory,
        icon: const Icon(Icons.history),
        tooltip: _label('历史版本', 'Version history'),
      ),
      IconButton(
        onPressed: _openMetadata,
        icon: const Icon(Icons.tune),
        tooltip: s.metadata,
      ),
      _ActionButton(
        wide: wide,
        icon: Icons.save_outlined,
        label: s.saveDraft,
        onPressed: () => _saveDraft(),
      ),
      _ActionButton(
        wide: wide,
        icon: Icons.drafts_outlined,
        label: s.pushToDraft,
        onPressed: () => _publish(drafts: true),
      ),
      _ActionButton(
        wide: wide,
        icon: Icons.cloud_upload_outlined,
        label: s.publish,
        onPressed: () => _publish(),
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildNarrow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 内容区至少填满「视口 - 吸顶工具条」，保证空文档也有完整的编辑/预览区域，
        // 内容变长后整页可上滑、工具条吸顶。
        final fillHeight = (constraints.maxHeight - _kEditorToolbarHeight)
            .clamp(0.0, double.infinity);
        return CustomScrollView(
          slivers: [
            // 标题、编辑/预览切换：随页面一起上滑
            SliverToBoxAdapter(child: _buildTitlePanel()),
            SliverToBoxAdapter(child: _buildModeSwitch()),
            // 工具条：吸顶
            SliverPersistentHeader(
              pinned: true,
              delegate: _ToolbarHeaderDelegate(
                height: _kEditorToolbarHeight,
                child: _buildToolbar(),
              ),
            ),
            SliverToBoxAdapter(
              child: _previewMode
                  ? _buildPreviewBody(minHeight: fillHeight)
                  : _buildEditorBody(minHeight: fillHeight),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWide() {
    return Column(
      children: [
        _buildTitlePanel(),
        _buildToolbar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildEditorSurface(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                ),
              ),
              VerticalDivider(width: 1),
              Expanded(
                child: _buildPreviewSurface(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitlePanel() {
    final colorScheme = Theme.of(context).colorScheme;
    final metrics = _editorMetrics;
    final metricsLabel = AppStrings.isZh
        ? '${metrics.characters} 字 · ${metrics.readingMinutes} 分钟'
        : '${metrics.wordCount} words · ${metrics.readingMinutes} min';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: AppStrings.current.titleHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DatePill(
                    label: _formatDate(_selectedDate),
                    onTap: _pickDate,
                  ),
                  _EditorPill(
                    icon: _statusIcon,
                    label: _statusLabel,
                    color: _statusColor,
                  ),
                  _EditorPill(
                    icon: _dirty ? Icons.circle : Icons.check_circle_outline,
                    label: _dirty
                        ? _label('未保存', 'Unsaved')
                        : _autoSaving
                        ? _label('自动保存中', 'Auto-saving')
                        : _lastAutoSavedAt != null
                        ? _label('已自动保存', 'Auto-saved')
                        : _label('已保存', 'Saved'),
                    color: _dirty
                        ? const Color(0xFF9A6A1F)
                        : const Color(0xFF2F7D57),
                  ),
                  _EditorPill(
                    icon: Icons.text_fields,
                    label: metricsLabel,
                    color: const Color(0xFF4B6EA8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _HeadingButton(label: _label, contentCtrl: _contentCtrl),
                _ToolButton(
                  icon: Icons.format_bold,
                  tooltip: _label('加粗', 'Bold'),
                  onPressed: () =>
                      _toggleMarkdown('**', '**', _label('重点', 'bold')),
                ),
                _ToolButton(
                  icon: Icons.format_italic,
                  tooltip: _label('斜体', 'Italic'),
                  onPressed: () =>
                      _toggleMarkdown('*', '*', _label('强调', 'italic')),
                ),
                _ToolButton(
                  icon: Icons.link,
                  tooltip: _label('插入链接', 'Insert link'),
                  onPressed: () => _insertMarkdown(
                    '[',
                    '](https://example.com)',
                    _label('链接文字', 'link text'),
                  ),
                ),
                _ToolButton(
                  icon: Icons.format_quote,
                  tooltip: _label('引用', 'Quote'),
                  onPressed: () => _toggleLine('> ', _label('引用内容', 'Quote')),
                ),
                _ToolButton(
                  icon: Icons.code,
                  tooltip: _label('代码块', 'Code block'),
                  onPressed: () =>
                      _insertBlock('```\n${_label('代码', 'code')}\n```'),
                ),
                _ToolButton(
                  icon: Icons.find_replace,
                  tooltip: _label('查找替换', 'Find and replace'),
                  onPressed: _showFindReplace,
                ),
                _ToolButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: _label('文章大纲', 'Article outline'),
                  onPressed: _showOutline,
                ),
                _ToolButton(
                  icon: _uploading ? Icons.hourglass_top : Icons.image_outlined,
                  tooltip: _label('插入图片', 'Insert image'),
                  onPressed: _uploading ? null : () => _pickAndUploadImage(),
                ),
                _ToolButton(
                  icon: Icons.music_note,
                  tooltip: _label('插入音乐', 'Insert music'),
                  onPressed: () => _showMusicSearch(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.edit_outlined),
            label: Text(_label('编辑', 'Edit')),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(_label('预览', 'Preview')),
          ),
        ],
        selected: {_previewMode},
        onSelectionChanged: (value) {
          setState(() => _previewMode = value.first);
        },
      ),
    );
  }

  Widget _buildEditorSurface({required EdgeInsets padding}) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: _contentCtrl,
        focusNode: _contentFocus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: AppStrings.current.editorHint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.all(4),
        ),
        style: const TextStyle(fontSize: 16, height: 1.55),
      ),
    );
  }

  Widget _buildPreviewSurface({required EdgeInsets padding}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: _previewText.trim().isEmpty
            ? Center(
                child: Text(
                  AppStrings.current.editorHint,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : Markdown(
                data: _previewText,
                padding: const EdgeInsets.all(22),
                selectable: true,
              ),
      ),
    );
  }

  // 窄屏：无边框、随内容增高的编辑区。内容超出视口时整页滚动、工具条吸顶；
  // 内容较短时用 minHeight 撑满，保证有完整的可点按编辑区域。
  Widget _buildEditorBody({required double minHeight}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: TextField(
          controller: _contentCtrl,
          focusNode: _contentFocus,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: AppStrings.current.editorHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isCollapsed: true,
          ),
          style: const TextStyle(fontSize: 16, height: 1.55),
        ),
      ),
    );
  }

  // 窄屏预览：随内容增高（MarkdownBody 不自带滚动），与编辑区共用整页滚动。
  Widget _buildPreviewBody({required double minHeight}) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_previewText.trim().isEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Center(
          child: Text(
            AppStrings.current.editorHint,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: MarkdownBody(data: _previewText, selectable: true),
      ),
    );
  }

  void _insertMarkdown(String prefix, String suffix, String placeholder) {
    final value = _contentCtrl.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selected = start == end
        ? placeholder
        : value.text.substring(start, end);
    final replacement = '$prefix$selected$suffix';
    final nextText = value.text.replaceRange(start, end, replacement);
    final selectionStart = start + prefix.length;
    final selectionEnd = selectionStart + selected.length;

    _contentCtrl.value = value.copyWith(
      text: nextText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
      composing: TextRange.empty,
    );
  }

  void _toggleMarkdown(String prefix, String suffix, String placeholder) {
    final value = _contentCtrl.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    // Check if the selected text is already wrapped: prefix + content + suffix
    final beforeStart = start - prefix.length;
    final afterEnd = end + suffix.length;
    if (beforeStart >= 0 &&
        afterEnd <= text.length &&
        text.substring(beforeStart, start) == prefix &&
        text.substring(end, afterEnd) == suffix) {
      // Already wrapped → unwrap
      final inner = text.substring(start, end);
      final nextText = text.replaceRange(beforeStart, afterEnd, inner);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection(
          baseOffset: beforeStart,
          extentOffset: beforeStart + inner.length,
        ),
        composing: TextRange.empty,
      );
    } else {
      // Not wrapped → wrap (same as _insertMarkdown)
      final selected = start == end ? placeholder : text.substring(start, end);
      final replacement = '$prefix$selected$suffix';
      final nextText = text.replaceRange(start, end, replacement);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + selected.length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  void _toggleLine(String prefix, String placeholder) {
    final value = _contentCtrl.value;
    final text = value.text;
    final selection = value.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    // Find current line boundaries
    final lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0) + 1;
    int lineEnd = text.indexOf('\n', cursor);
    if (lineEnd < 0) lineEnd = text.length;

    final line = text.substring(lineStart, lineEnd);

    if (line.startsWith(prefix)) {
      // Already has prefix → remove it
      final newLine = line.substring(prefix.length);
      final nextText = text.replaceRange(lineStart, lineEnd, newLine);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: lineStart + newLine.length),
        composing: TextRange.empty,
      );
    } else {
      // No prefix → add it
      final needsNewLine = lineStart > 0;
      final selected = line.isEmpty ? placeholder : line;
      final replacement =
          '${needsNewLine && lineStart > 0 ? '' : ''}$prefix$selected';
      final nextText = text.replaceRange(lineStart, lineEnd, replacement);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection(
          baseOffset: lineStart + prefix.length,
          extentOffset: lineStart + prefix.length + selected.length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  void _insertBlock(String block) {
    final value = _contentCtrl.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final needsLeadingNewLine = start > 0 && value.text[start - 1] != '\n';
    final needsTrailingNewLine =
        end < value.text.length && value.text[end] != '\n';
    final replacement =
        '${needsLeadingNewLine ? '\n' : ''}$block${needsTrailingNewLine ? '\n' : ''}';
    final nextText = value.text.replaceRange(start, end, replacement);
    final cursor = start + replacement.length;

    _contentCtrl.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  String get _statusLabel {
    final s = AppStrings.current;
    final article = _editingArticle;
    if (article == null) return s.draftStatus;

    return switch (article.status) {
      ArticleStatus.synced => s.synced,
      ArticleStatus.repoDraft => s.repoDraft,
      ArticleStatus.pendingPublish => s.pendingPublish,
      ArticleStatus.remoteDeleted => s.remoteDeleted,
      ArticleStatus.draft => s.draftStatus,
    };
  }

  IconData get _statusIcon {
    final article = _editingArticle;
    if (article == null) return Icons.edit_note;

    return switch (article.status) {
      ArticleStatus.synced => Icons.cloud_done,
      ArticleStatus.repoDraft => Icons.drafts_outlined,
      ArticleStatus.pendingPublish => Icons.cloud_upload_outlined,
      ArticleStatus.remoteDeleted => Icons.cloud_off_outlined,
      ArticleStatus.draft => Icons.edit_note,
    };
  }

  Color get _statusColor {
    final article = _editingArticle;
    if (article == null) return const Color(0xFF6F7672);

    return switch (article.status) {
      ArticleStatus.synced => const Color(0xFF2F7D57),
      ArticleStatus.repoDraft => const Color(0xFF9A6A1F),
      ArticleStatus.pendingPublish => const Color(0xFF7A5CDB),
      ArticleStatus.remoteDeleted => const Color(0xFFB64B45),
      ArticleStatus.draft => const Color(0xFF6F7672),
    };
  }

  Future<void> _showMusicSearch() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _MusicSearchSheet(),
    );
    if (result != null && result.isNotEmpty) {
      _insertBlock(result);
    }
  }

  String _label(String zh, String en) {
    return AppStrings.isZh ? zh : en;
  }

  /// null 与空字符串视为相等
  bool _neq(String? a, String? b) => (a ?? '') != (b ?? '');

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!_valueEquals(b[entry.key], entry.value)) return false;
    }
    return true;
  }

  bool _valueEquals(Object? a, Object? b) {
    if (identical(a, b) || a == b) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_valueEquals(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final entry in a.entries) {
        if (!b.containsKey(entry.key) ||
            !_valueEquals(b[entry.key], entry.value)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

enum _ConflictChoice { keepLocal, useRemote, manualMerge }

enum _ConflictView { diff, local, remote, base }

class _ConflictResolutionDialog extends StatefulWidget {
  final String base;
  final String local;
  final String remote;
  final String Function(String zh, String en) label;

  const _ConflictResolutionDialog({
    required this.base,
    required this.local,
    required this.remote,
    required this.label,
  });

  @override
  State<_ConflictResolutionDialog> createState() =>
      _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<_ConflictResolutionDialog> {
  _ConflictView _view = _ConflictView.diff;

  @override
  Widget build(BuildContext context) {
    final diff = TextDiffService.compare(widget.local, widget.remote);
    final colorScheme = Theme.of(context).colorScheme;
    final viewContent = switch (_view) {
      _ConflictView.diff =>
        diff.truncated
            ? Center(
                child: Text(
                  widget.label(
                    '内容较长，已省略行级差异；请查看三个版本或使用手工合并。',
                    'The document is too long for a line diff. Review the versions or use manual merge.',
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: diff.lines.length,
                itemBuilder: (_, index) {
                  final line = diff.lines[index];
                  final (prefix, color) = switch (line.kind) {
                    TextDiffKind.unchanged => (' ', colorScheme.onSurface),
                    TextDiffKind.added => ('+', const Color(0xFF2F7D57)),
                    TextDiffKind.removed => ('-', colorScheme.error),
                  };
                  return Container(
                    color: line.kind == TextDiffKind.added
                        ? const Color(0xFF2F7D57).withValues(alpha: 0.08)
                        : line.kind == TextDiffKind.removed
                        ? colorScheme.error.withValues(alpha: 0.08)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: SelectableText(
                      '$prefix ${line.text}',
                      style: TextStyle(
                        color: color,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
      _ConflictView.local => _ConflictTextPane(
        title: widget.label('本地版本', 'Local version'),
        text: widget.local,
      ),
      _ConflictView.remote => _ConflictTextPane(
        title: widget.label('远端版本', 'Remote version'),
        text: widget.remote,
      ),
      _ConflictView.base => _ConflictTextPane(
        title: widget.label('共同基线', 'Common base'),
        text: widget.base,
      ),
    };

    return AlertDialog(
      title: Text(widget.label('检测到远端冲突', 'Remote conflict detected')),
      content: SizedBox(
        width: 860,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label(
                '远端文章在你编辑期间被更新。请比较差异后选择处理方式。',
                'The remote article changed while you were editing. Compare the versions and choose how to continue.',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label(
                '差异：远端新增 ${diff.addedCount} 行，本地独有 ${diff.removedCount} 行',
                'Diff: ${diff.addedCount} remote-only lines, ${diff.removedCount} local-only lines',
              ),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_ConflictView>(
              segments: [
                ButtonSegment(
                  value: _ConflictView.diff,
                  label: Text(widget.label('差异', 'Diff')),
                ),
                ButtonSegment(
                  value: _ConflictView.local,
                  label: Text(widget.label('本地', 'Local')),
                ),
                ButtonSegment(
                  value: _ConflictView.remote,
                  label: Text(widget.label('远端', 'Remote')),
                ),
                ButtonSegment(
                  value: _ConflictView.base,
                  label: Text(widget.label('基线', 'Base')),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) {
                setState(() => _view = selection.first);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: viewContent,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.label('稍后处理', 'Not now')),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, _ConflictChoice.useRemote),
          child: Text(widget.label('使用远端', 'Use remote')),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, _ConflictChoice.manualMerge),
          child: Text(widget.label('手工合并', 'Manual merge')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ConflictChoice.keepLocal),
          child: Text(widget.label('保留本地并覆盖', 'Keep local and overwrite')),
        ),
      ],
    );
  }
}

class _ConflictTextPane extends StatelessWidget {
  final String title;
  final String text;

  const _ConflictTextPane({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(10),
            child: SelectableText(
              text.isEmpty ? '—' : text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _FindReplaceDialog extends StatefulWidget {
  final TextEditingController contentController;
  final FocusNode contentFocus;
  final String Function(String zh, String en) label;

  const _FindReplaceDialog({
    required this.contentController,
    required this.contentFocus,
    required this.label,
  });

  @override
  State<_FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<_FindReplaceDialog> {
  final _findCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  bool _caseSensitive = false;
  String? _message;

  @override
  void dispose() {
    _findCtrl.dispose();
    _replaceCtrl.dispose();
    super.dispose();
  }

  void _findNext() {
    final value = widget.contentController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.end : 0;
    final match = EditorToolsService.findNext(
      value.text,
      _findCtrl.text,
      start,
      caseSensitive: _caseSensitive,
    );
    if (match == null) {
      setState(() => _message = widget.label('未找到匹配内容', 'No match found'));
      return;
    }
    widget.contentController.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
    widget.contentFocus.requestFocus();
    setState(() => _message = widget.label('已定位到下一处匹配', 'Moved to next match'));
  }

  void _replaceCurrent() {
    final query = _findCtrl.text;
    if (query.isEmpty) return;
    final value = widget.contentController.value;
    final selection = value.selection;
    final selected = selection.isValid && !selection.isCollapsed
        ? value.text.substring(selection.start, selection.end)
        : '';
    final matches = _caseSensitive
        ? selected == query
        : selected.toLowerCase() == query.toLowerCase();
    if (!matches) {
      _findNext();
      return;
    }
    final replacement = _replaceCtrl.text;
    final nextText = value.text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );
    final cursor = selection.start + replacement.length;
    widget.contentController.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
    _findNext();
  }

  void _replaceAll() {
    final result = EditorToolsService.replaceAll(
      widget.contentController.text,
      _findCtrl.text,
      _replaceCtrl.text,
      caseSensitive: _caseSensitive,
    );
    if (result.count == 0) {
      setState(() => _message = widget.label('未找到匹配内容', 'No match found'));
      return;
    }
    widget.contentController.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.text.length),
    );
    widget.contentFocus.requestFocus();
    setState(
      () => _message = widget.label(
        '已替换 ${result.count} 处',
        'Replaced ${result.count} matches',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label('查找替换', 'Find and replace')),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _findCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.label('查找内容', 'Find'),
                suffixIcon: IconButton(
                  onPressed: _findNext,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: widget.label('查找下一个', 'Find next'),
                ),
              ),
              onSubmitted: (_) => _findNext(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _replaceCtrl,
              decoration: InputDecoration(
                labelText: widget.label('替换为', 'Replace with'),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _caseSensitive,
              onChanged: (value) =>
                  setState(() => _caseSensitive = value ?? false),
              title: Text(widget.label('区分大小写', 'Match case')),
            ),
            if (_message != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.label('关闭', 'Close')),
        ),
        OutlinedButton(
          onPressed: _replaceCurrent,
          child: Text(widget.label('替换', 'Replace')),
        ),
        FilledButton(
          onPressed: _replaceAll,
          child: Text(widget.label('全部替换', 'Replace all')),
        ),
      ],
    );
  }
}

class _ToolbarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _ToolbarHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 工具条自带背景与底部分隔线，铺满吸顶高度即可。
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _ToolbarHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _ActionButton extends StatelessWidget {
  final bool wide;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.wide,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return IconButton(onPressed: onPressed, icon: Icon(icon), tooltip: label);
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DatePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _EditorPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _EditorPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadingButton extends StatelessWidget {
  final TextEditingController contentCtrl;
  final String Function(String zh, String en) label;

  const _HeadingButton({required this.contentCtrl, required this.label});

  /// Returns (startOffset, currentLevel) for the line under cursor.
  /// currentLevel 0 = no heading, 1-6 = H1-H6.
  (int, int) _detectHeading() {
    final text = contentCtrl.text;
    if (text.isEmpty) return (0, 0);
    final cursor = contentCtrl.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return (text.length, 0);

    // Find line start
    final searchFrom = cursor > 0 ? cursor - 1 : 0;
    int lineStart = text.lastIndexOf('\n', searchFrom) + 1;
    // Find line end
    int lineEnd = text.indexOf('\n', cursor);
    if (lineEnd < 0) lineEnd = text.length;

    if (lineStart < 0 || lineStart > lineEnd) return (0, 0);
    final line = text.substring(lineStart, lineEnd);
    final match = RegExp(r'^(#{1,4})\s').matchAsPrefix(line);
    if (match == null) return (lineStart, 0);
    return (lineStart, match.group(1)!.length);
  }

  void _toggleHeading() {
    final (lineStart, level) = _detectHeading();
    final text = contentCtrl.text;

    String newLine;
    int newCursorOffset;

    if (level == 0) {
      // No heading → insert H1
      final lineEnd = text.indexOf('\n', lineStart);
      final end = lineEnd < 0 ? text.length : lineEnd;
      final line = text.substring(lineStart, end);
      newLine = '# $line';
      newCursorOffset = lineStart + 2; // after "# "
    } else if (level < 4) {
      // H1-H3 → bump up one level
      final lineEnd = text.indexOf('\n', lineStart);
      final end = lineEnd < 0 ? text.length : lineEnd;
      final line = text.substring(lineStart, end);
      final oldPrefix = '${'#' * level} ';
      final newPrefix = '${'#' * (level + 1)} ';
      newLine = newPrefix + line.substring(oldPrefix.length);
      newCursorOffset = lineStart + newPrefix.length;
    } else {
      // H4 → clear heading
      final lineEnd = text.indexOf('\n', lineStart);
      final end = lineEnd < 0 ? text.length : lineEnd;
      final line = text.substring(lineStart, end);
      newLine = line.substring(5); // remove "#### "
      newCursorOffset = lineStart;
    }

    final nextText = text.replaceRange(
      lineStart,
      text.indexOf('\n', lineStart) < 0
          ? text.length
          : text.indexOf('\n', lineStart),
      newLine,
    );
    contentCtrl.value = contentCtrl.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (_, level) = _detectHeading();
    final displayLevel = level == 0 ? '' : '$level';

    return SizedBox(
      width: 40,
      height: 40,
      child: TextButton(
        onPressed: _toggleHeading,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Transform.translate(
              offset: const Offset(0, -2),
              child: Text(
                'H',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ),
            if (displayLevel.isNotEmpty)
              Text(
                displayLevel,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 网易云音乐搜索面板
class _MusicSearchSheet extends StatefulWidget {
  const _MusicSearchSheet();

  @override
  State<_MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<_MusicSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<_MusicResult> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _searchCtrl.text.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final uri = Uri.parse(
        'https://music.163.com/api/search/get/web',
      ).replace(queryParameters: {'s': keyword, 'type': '1', 'limit': '10'});
      final resp = await http.get(
        uri,
        headers: {
          'Referer': 'https://music.163.com',
          'User-Agent': 'Mozilla/5.0',
        },
      );

      if (resp.statusCode != 200) {
        setState(() {
          _loading = false;
          _error = AppStrings.isZh ? '搜索失败' : 'Search failed';
        });
        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      final songs = result?['songs'] as List<dynamic>? ?? [];

      setState(() {
        _loading = false;
        _results = songs.map((s) => _MusicResult.fromJson(s)).toList();
      });
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Editor',
        context: '搜索音乐失败',
      );
      setState(() {
        _loading = false;
        _error = AppStrings.isZh ? '网络错误' : 'Network error';
      });
    }
  }

  void _select(_MusicResult song) {
    final zh = AppStrings.isZh;
    int width = 330;
    int height = 86;
    int playerHeight = 66;
    bool autoPlay = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 歌曲信息
                  Row(
                    children: [
                      const Icon(Icons.music_note, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${song.name} - ${song.artist}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 尺寸选择
                  Text(
                    zh ? '播放器尺寸' : 'Player size',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _sizeChip(
                        zh ? '小' : 'Small',
                        330,
                        86,
                        66,
                        width,
                        height,
                        playerHeight,
                        (w, h, ph) => setSheetState(() {
                          width = w;
                          height = h;
                          playerHeight = ph;
                        }),
                      ),
                      _sizeChip(
                        zh ? '迷你' : 'Mini',
                        298,
                        52,
                        32,
                        width,
                        height,
                        playerHeight,
                        (w, h, ph) => setSheetState(() {
                          width = w;
                          height = h;
                          playerHeight = ph;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 自动播放
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      zh ? '自动播放' : 'Autoplay',
                      style: const TextStyle(fontSize: 14),
                    ),
                    value: autoPlay,
                    onChanged: (v) => setSheetState(() => autoPlay = v),
                  ),
                  const SizedBox(height: 16),
                  // 插入按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final auto = autoPlay ? 1 : 0;
                        final embed =
                            '<iframe frameborder="no" border="0" marginwidth="0" '
                            'marginheight="0" width=$width height=$height '
                            'src="//music.163.com/outchain/player?type=2'
                            '&id=${song.id}&auto=$auto&height=$playerHeight">'
                            '</iframe>';
                        Navigator.pop(ctx); // 关闭配置面板
                        Navigator.pop(context, embed); // 返回结果
                      },
                      child: Text(zh ? '插入' : 'Insert'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sizeChip(
    String label,
    int w,
    int h,
    int ph,
    int currentW,
    int currentH,
    int currentPh,
    void Function(int w, int h, int ph) onSelected,
  ) {
    final selected = currentW == w && currentH == h && currentPh == ph;
    return ChoiceChip(
      label: Text('$label ($w×$h)'),
      selected: selected,
      onSelected: (_) => onSelected(w, h, ph),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zh = AppStrings.isZh;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.music_note),
                  const SizedBox(width: 8),
                  Text(
                    zh ? '插入音乐' : 'Insert Music',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: zh ? '搜索歌曲名...' : 'Search songs...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _search,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : _results.isEmpty
                  ? Center(
                      child: Text(
                        zh ? '输入关键词搜索网易云音乐' : 'Search NetEase Music',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final song = _results[i];
                        return ListTile(
                          leading: const Icon(Icons.music_note, size: 20),
                          title: Text(
                            song.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            _formatDuration(song.duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () => _select(song),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int ms) {
    final sec = ms ~/ 1000;
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _MusicResult {
  final int id;
  final String name;
  final String artist;
  final int duration;

  _MusicResult({
    required this.id,
    required this.name,
    required this.artist,
    required this.duration,
  });

  factory _MusicResult.fromJson(Map<String, dynamic> json) {
    final artists =
        (json['artists'] as List<dynamic>?)
            ?.map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        [];
    return _MusicResult(
      id: json['id'] as int? ?? 0,
      name: (json['name'] as String?) ?? '',
      artist: artists.join(' / '),
      duration: (json['duration'] as int?) ?? 0,
    );
  }
}
