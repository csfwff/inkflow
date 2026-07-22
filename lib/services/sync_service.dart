import '../models/article.dart';
import 'frontmatter_helper.dart';
import 'github_service.dart';
import 'log_service.dart';
import 'sync_contracts.dart';

class SyncService {
  final GitHubService github;
  final SyncArticleStore articleService;
  final SyncSettingsStore settingsService;

  static final _log = LogService.instance;

  SyncService({
    required this.github,
    required this.articleService,
    required this.settingsService,
  });

  Future<Article?> fetchRemoteArticle(Article local) async {
    final remotePath = local.remotePath;
    if (remotePath == null || remotePath.isEmpty) return null;

    final remoteKind = local.remoteKind ?? _remoteKindForPath(remotePath);
    if (remoteKind == null) return null;

    final fileData = await github.getFileContent(remotePath);
    if (fileData == null) return null;

    final prefix = _prefixForRemoteKind(remoteKind);
    final filePath = remotePath.startsWith(prefix)
        ? remotePath.substring(prefix.length)
        : local.filePath;

    return _parseFrontmatter(
      fileData.content,
      filePath: filePath,
      remotePath: remotePath,
      remoteKind: remoteKind,
      sha: fileData.sha,
      status: _statusForRemoteKind(remoteKind),
    );
  }

  Future<SyncResult> syncFromGitHub() async {
    try {
      _log.write('=== syncFromGitHub START ===', tag: 'Sync');
      final List<Article> remoteArticles = [];

      // 同步已发布文章 (source/_posts)
      _log.write('Syncing source/_posts ...', tag: 'Sync');
      final posts = await _syncDirectory(
        'source/_posts',
        ArticleStatus.synced,
        ArticleRemoteKind.post,
      );
      _log.write(
        'source/_posts -> ${posts.articles.length} articles (${posts.state.name})',
        tag: 'Sync',
      );
      remoteArticles.addAll(posts.articles);

      // 同步仓库草稿 (source/_drafts)
      _log.write('Syncing source/_drafts ...', tag: 'Sync');
      final drafts = await _syncDirectory(
        'source/_drafts',
        ArticleStatus.repoDraft,
        ArticleRemoteKind.repoDraft,
      );
      _log.write(
        'source/_drafts -> ${drafts.articles.length} articles (${drafts.state.name})',
        tag: 'Sync',
      );
      remoteArticles.addAll(drafts.articles);

      _log.write(
        'Total remote articles: ${remoteArticles.length}',
        tag: 'Sync',
      );

      // 收集远程存在的完整路径，避免 posts/drafts 同名文件互相混淆。
      final remotePaths = <String>{};
      for (final a in remoteArticles) {
        final remotePath = a.remotePath;
        if (remotePath != null) remotePaths.add(remotePath);
      }
      _log.write('Remote paths: $remotePaths', tag: 'Sync');

      // upsert 远程文章
      for (final article in remoteArticles) {
        await articleService.upsertFromGitHub(article);
      }

      // 同步所有标签和分类到数据库
      final allTags = <String>{};
      final allCategories = <String>{};
      for (final article in remoteArticles) {
        allTags.addAll(article.tags);
        allCategories.addAll(article.categories);
      }
      await articleService.ensureTags(allTags.toList());
      await articleService.ensureCategories(allCategories.toList());

      int deletedCount = 0;
      final deletionReconciliationSkipped =
          posts.state != _DirectoryScanState.complete ||
          drafts.state != _DirectoryScanState.complete;

      // 只有两个根目录都完整读取成功时，才允许把本地记录判定为远端删除。
      // 404 对于新仓库是合法状态，但也可能来自错误仓库/权限配置，不能据此
      // 修改本地文章状态。
      if (deletionReconciliationSkipped) {
        _log.write(
          'Skipped remote deletion reconciliation because at least one root directory was not found',
          tag: 'Sync',
        );
      } else {
        final localSynced = await articleService.getRemoteTracked();
        _log.write(
          'Local synced/repoDraft count: ${localSynced.length}',
          tag: 'Sync',
        );
        for (final local in localSynced) {
          if (local.status == ArticleStatus.pendingPublish) {
            continue;
          }

          final remotePath = local.remotePath;
          if (remotePath == null || remotePath.isEmpty) {
            _log.write(
              'Skipped deletion reconciliation for "${local.title}" without a remote path',
              tag: 'Sync',
            );
            continue;
          }
          if (!remotePaths.contains(remotePath)) {
            _log.write(
              'Remote deleted: "${local.title}" ($remotePath)',
              tag: 'Sync',
            );
            await articleService.markAsRemoteDeleted(local.id!);
            deletedCount++;
          }
        }
      }
      if (deletedCount > 0) {
        _log.write(
          'Marked $deletedCount articles as remote deleted',
          tag: 'Sync',
        );
      }

      // 更新 lastSyncTime
      settingsService.settings.lastSyncTime = DateTime.now();
      await settingsService.save();
      _log.write(
        'Updated lastSyncTime: ${settingsService.settings.lastSyncTime}',
        tag: 'Sync',
      );

      _log.write(
        '=== syncFromGitHub DONE: ${remoteArticles.length} synced, $deletedCount remote deleted ===',
        tag: 'Sync',
      );
      return SyncResult(
        success: true,
        count: remoteArticles.length,
        deletionReconciliationSkipped: deletionReconciliationSkipped,
      );
    } catch (e, stack) {
      await _log.logException(e, stack, tag: 'Sync', context: '全量同步异常');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 增量同步：基于 commit 记录只拉取变更文件
  Future<SyncResult> syncIncremental() async {
    try {
      _log.write('=== syncIncremental START ===', tag: 'Sync');

      final lastSyncTime = settingsService.settings.lastSyncTime;
      if (lastSyncTime == null) {
        _log.write('No lastSyncTime, falling back to full sync', tag: 'Sync');
        return syncFromGitHub();
      }

      _log.write('lastSyncTime: $lastSyncTime', tag: 'Sync');

      // 获取两个目录的 commit 记录
      final postsCommitsResult = await github.getCommitsSince(
        path: 'source/_posts',
        since: lastSyncTime,
      );
      if (!postsCommitsResult.success) {
        _log.write(
          'Posts commit request failed (${postsCommitsResult.error}), falling back to full sync',
          tag: 'Sync',
        );
        return syncFromGitHub();
      }

      final draftsCommitsResult = await github.getCommitsSince(
        path: 'source/_drafts',
        since: lastSyncTime,
      );
      if (!draftsCommitsResult.success) {
        _log.write(
          'Drafts commit request failed (${draftsCommitsResult.error}), falling back to full sync',
          tag: 'Sync',
        );
        return syncFromGitHub();
      }

      final postsCommits = postsCommitsResult.commits;
      final draftsCommits = draftsCommitsResult.commits;

      _log.write(
        'Commits: posts=${postsCommits.length}, drafts=${draftsCommits.length}',
        tag: 'Sync',
      );

      // commit 太多时 getCommitsSince 会跳过详情获取（files 为空），降级到全量同步
      final hasEmptyFiles =
          postsCommits.any((c) => c.files.isEmpty) ||
          draftsCommits.any((c) => c.files.isEmpty);
      if (hasEmptyFiles &&
          (postsCommits.isNotEmpty || draftsCommits.isNotEmpty)) {
        _log.write(
          'Commits missing file details (too many?), falling back to full sync',
          tag: 'Sync',
        );
        return syncFromGitHub();
      }

      // 提取变更文件
      final postsChanges = _extractChanges(postsCommits, 'source/_posts/');
      final draftsChanges = _extractChanges(draftsCommits, 'source/_drafts/');

      _log.write(
        'Changes: posts added/modified=${postsChanges.addedOrModified.length}, removed=${postsChanges.removed.length}',
        tag: 'Sync',
      );
      _log.write(
        'Changes: drafts added/modified=${draftsChanges.addedOrModified.length}, removed=${draftsChanges.removed.length}',
        tag: 'Sync',
      );

      // 如果变更太多（>200个文件），降级到全量同步
      final totalChanges =
          postsChanges.addedOrModified.length +
          postsChanges.removed.length +
          draftsChanges.addedOrModified.length +
          draftsChanges.removed.length;
      if (totalChanges > 200) {
        _log.write(
          'Too many changes ($totalChanges), falling back to full sync',
          tag: 'Sync',
        );
        return syncFromGitHub();
      }

      // 拉取 added/modified 文件内容
      int syncedCount = 0;

      for (final filePath in postsChanges.addedOrModified) {
        final article = await _fetchAndParseFile(
          filePath,
          ArticleStatus.synced,
          ArticleRemoteKind.post,
        );
        if (article != null) {
          await articleService.upsertFromGitHub(article);
          syncedCount++;
        }
      }

      for (final filePath in draftsChanges.addedOrModified) {
        final article = await _fetchAndParseFile(
          filePath,
          ArticleStatus.repoDraft,
          ArticleRemoteKind.repoDraft,
        );
        if (article != null) {
          await articleService.upsertFromGitHub(article);
          syncedCount++;
        }
      }

      // 标记 removed 文件
      int deletedCount = 0;
      for (final filePath in postsChanges.removed) {
        deletedCount += await _markRemoteDeleted(
          filePath,
          ArticleRemoteKind.post,
        );
      }
      for (final filePath in draftsChanges.removed) {
        deletedCount += await _markRemoteDeleted(
          filePath,
          ArticleRemoteKind.repoDraft,
        );
      }

      // 同步标签和分类
      final allArticles = await articleService.getRemoteTracked();
      final allTags = <String>{};
      final allCategories = <String>{};
      for (final article in allArticles) {
        allTags.addAll(article.tags);
        allCategories.addAll(article.categories);
      }
      await articleService.ensureTags(allTags.toList());
      await articleService.ensureCategories(allCategories.toList());

      // 更新 lastSyncTime
      final latestDate = _getLatestDate(postsCommits, draftsCommits);
      if (latestDate != null) {
        settingsService.settings.lastSyncTime = latestDate;
        await settingsService.save();
        _log.write('Updated lastSyncTime: $latestDate', tag: 'Sync');
      }

      _log.write(
        '=== syncIncremental DONE: $syncedCount synced, $deletedCount deleted ===',
        tag: 'Sync',
      );
      return SyncResult(success: true, count: syncedCount);
    } catch (e, stack) {
      await _log.logException(e, stack, tag: 'Sync', context: '增量同步异常');
      // 增量同步失败，降级到全量同步
      _log.write('Falling back to full sync', tag: 'Sync');
      return syncFromGitHub();
    }
  }

  /// 从 commit 列表中提取变更文件（added/modified 和 removed）
  _ChangeSet _extractChanges(List<GitHubCommit> commits, String prefix) {
    final addedOrModified = <String>{};
    final removed = <String>{};

    // 从旧到新遍历，这样后面的 commit 会覆盖前面的状态
    for (final commit in commits.reversed) {
      for (final file in commit.files) {
        final relativePath = _relativeMarkdownPath(file.filename, prefix);
        final previousRelativePath = _relativeMarkdownPath(
          file.previousFilename,
          prefix,
        );

        switch (file.status) {
          case 'added':
          case 'modified':
            if (relativePath != null) {
              addedOrModified.add(relativePath);
              removed.remove(relativePath);
            }
            break;
          case 'removed':
            if (relativePath != null) {
              addedOrModified.remove(relativePath);
              removed.add(relativePath);
            }
            break;
          case 'renamed':
            if (previousRelativePath != null) {
              addedOrModified.remove(previousRelativePath);
              removed.add(previousRelativePath);
            }
            if (relativePath != null) {
              addedOrModified.add(relativePath);
              removed.remove(relativePath);
            }
            break;
        }
      }
    }

    return _ChangeSet(
      addedOrModified: addedOrModified.toList(),
      removed: removed.toList(),
    );
  }

  String? _relativeMarkdownPath(String? path, String prefix) {
    if (path == null || !path.startsWith(prefix) || !path.endsWith('.md')) {
      return null;
    }
    return path.substring(prefix.length);
  }

  /// 获取单个文件并解析
  Future<Article?> _fetchAndParseFile(
    String relativePath,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
  ) async {
    final prefix = _prefixForRemoteKind(remoteKind);
    final remotePath = '$prefix$relativePath';

    _log.write('Fetching: $remotePath', tag: 'Sync');
    final fileData = await github.getFileContent(remotePath);
    if (fileData == null) {
      _log.write('Failed to fetch: $remotePath', tag: 'Sync');
      return null;
    }

    return _parseFrontmatter(
      fileData.content,
      filePath: relativePath,
      remotePath: remotePath,
      remoteKind: remoteKind,
      sha: fileData.sha,
      status: status,
    );
  }

  /// 根据完整远端路径查找并标记为 remoteDeleted。
  ///
  /// posts 和 drafts 可以有相同的相对文件名，因此不能使用 endsWith 匹配。
  Future<int> _markRemoteDeleted(
    String relativePath,
    ArticleRemoteKind remoteKind,
  ) async {
    final expectedRemotePath = Article.buildRemotePath(
      kind: remoteKind,
      filePath: relativePath,
    );
    final articles = await articleService.getRemoteTracked();
    int count = 0;
    for (final article in articles) {
      if (article.status == ArticleStatus.pendingPublish) continue;
      if (article.remotePath == expectedRemotePath && article.id != null) {
        await articleService.markAsRemoteDeleted(article.id!);
        count++;
        _log.write('Marked remote deleted: "${article.title}"', tag: 'Sync');
      }
    }
    return count;
  }

  /// 获取最新的 commit 时间
  DateTime? _getLatestDate(
    List<GitHubCommit> postsCommits,
    List<GitHubCommit> draftsCommits,
  ) {
    DateTime? latest;
    for (final commit in postsCommits) {
      if (latest == null || commit.date.isAfter(latest)) {
        latest = commit.date;
      }
    }
    for (final commit in draftsCommits) {
      if (latest == null || commit.date.isAfter(latest)) {
        latest = commit.date;
      }
    }
    return latest;
  }

  Future<_DirectorySyncResult> _syncDirectory(
    String dirPath,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
  ) async {
    _log.write('_syncDirectory: $dirPath', tag: 'Sync');
    final List<Article> articles = [];
    final prefix = _prefixForRemoteKind(remoteKind);

    final rootResult = await github.listDirectoryContents(dirPath);
    if (rootResult.notFound) {
      _log.write(
        'Root directory not found (404), skipping: $dirPath',
        tag: 'Sync',
      );
      return _DirectorySyncResult.notFound();
    }
    if (!rootResult.success) {
      throw _SyncException(
        'Failed to list $dirPath: ${rootResult.error ?? 'Unknown error'}',
      );
    }

    await _traverseEntries(
      dirPath,
      rootResult.entries,
      prefix,
      status,
      remoteKind,
      articles,
    );

    _log.write('$dirPath -> ${articles.length} articles total', tag: 'Sync');
    return _DirectorySyncResult.complete(articles);
  }

  ArticleRemoteKind? _remoteKindForPath(String remotePath) {
    if (remotePath.startsWith('source/_posts/')) {
      return ArticleRemoteKind.post;
    }
    if (remotePath.startsWith('source/_drafts/')) {
      return ArticleRemoteKind.repoDraft;
    }
    return null;
  }

  String _prefixForRemoteKind(ArticleRemoteKind remoteKind) {
    return switch (remoteKind) {
      ArticleRemoteKind.post => 'source/_posts/',
      ArticleRemoteKind.repoDraft => 'source/_drafts/',
    };
  }

  ArticleStatus _statusForRemoteKind(ArticleRemoteKind remoteKind) {
    return switch (remoteKind) {
      ArticleRemoteKind.post => ArticleStatus.synced,
      ArticleRemoteKind.repoDraft => ArticleStatus.repoDraft,
    };
  }

  Future<void> _traverseDirectory(
    String currentPath,
    String prefix,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
    List<Article> articles,
  ) async {
    final result = await github.listDirectoryContents(currentPath);
    if (!result.success) {
      throw _SyncException(
        'Failed to list $currentPath: ${result.error ?? 'Unknown error'}',
      );
    }

    await _traverseEntries(
      currentPath,
      result.entries,
      prefix,
      status,
      remoteKind,
      articles,
    );
  }

  Future<void> _traverseEntries(
    String currentPath,
    List<GitHubFileEntry> entries,
    String prefix,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
    List<Article> articles,
  ) async {
    _log.write(
      '$currentPath -> ${entries.length} entries: ${entries.map((e) => '${e.name}(${e.type})').join(', ')}',
      tag: 'Sync',
    );

    for (final entry in entries) {
      // entry.path 是 API 返回的完整路径，如 source/_posts/2026/05/test.md
      if (entry.type == 'dir') {
        await _traverseDirectory(
          entry.path,
          prefix,
          status,
          remoteKind,
          articles,
        );
      } else if (entry.name.endsWith('.md')) {
        _log.write('  reading: ${entry.path}', tag: 'Sync');
        final fileData = await github.getFileContent(entry.path);
        if (fileData == null) {
          throw _SyncException('Failed to read ${entry.path}');
        }

        final filePath = entry.path.startsWith(prefix)
            ? entry.path.substring(prefix.length)
            : entry.path;
        final article = _parseFrontmatter(
          fileData.content,
          filePath: filePath,
          remotePath: entry.path,
          remoteKind: remoteKind,
          sha: fileData.sha,
          status: status,
        );
        if (article != null) {
          _log.write('  parsed: "${article.title}" ($filePath)', tag: 'Sync');
          articles.add(article);
        } else {
          _log.write(
            '  FAILED to parse frontmatter: ${entry.path}',
            tag: 'Sync',
          );
        }
      }
    }
  }

  Article? _parseFrontmatter(
    String rawContent, {
    required String filePath,
    required String remotePath,
    required ArticleRemoteKind remoteKind,
    required String sha,
    required ArticleStatus status,
  }) {
    final meta = FrontmatterHelper.parseFrontmatter(rawContent);

    String title = (meta['title'] ?? '').toString();
    final date =
        FrontmatterHelper.parseDate((meta['date'] ?? '').toString()) ??
        DateTime.now();
    final tags = _toStringList(meta['tags']);
    final categories = _toStringList(meta['categories']);
    final permalink = meta['permalink']?.toString();
    final topImg = meta['top_img']?.toString();
    final cover = meta['cover']?.toString();
    final excerpt = meta['excerpt']?.toString();
    final description = meta['description']?.toString();
    final author = meta['author']?.toString();

    // 提取自定义字段（排除已知字段）
    final knownKeys = {
      'title',
      'date',
      'tags',
      'categories',
      'permalink',
      'top_img',
      'cover',
      'excerpt',
      'description',
      'author',
    };
    final customFields = <String, dynamic>{};
    for (final entry in meta.entries) {
      if (!knownKeys.contains(entry.key)) {
        customFields[entry.key] = entry.value;
      }
    }

    final slug = filePath.split('/').last.replaceAll('.md', '');
    title = title.isNotEmpty ? title : slug;

    return Article(
      title: title,
      content: rawContent, // 保留完整内容（含 frontmatter）
      date: date,
      slug: slug,
      status: status,
      filePath: filePath,
      remotePath: remotePath,
      remoteKind: remoteKind,
      githubSha: sha,
      tags: tags,
      categories: categories,
      permalink: permalink,
      topImg: topImg,
      cover: cover,
      excerpt: excerpt,
      description: description,
      author: author,
      customFields: customFields,
    );
  }

  /// 将 YAML 值转为字符串列表。
  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}

class SyncResult {
  final bool success;
  final int count;
  final String? error;
  final bool deletionReconciliationSkipped;

  SyncResult({
    required this.success,
    this.count = 0,
    this.error,
    this.deletionReconciliationSkipped = false,
  });
}

enum _DirectoryScanState { complete, notFound }

class _DirectorySyncResult {
  final _DirectoryScanState state;
  final List<Article> articles;

  _DirectorySyncResult.complete(this.articles)
    : state = _DirectoryScanState.complete;

  _DirectorySyncResult.notFound()
    : state = _DirectoryScanState.notFound,
      articles = const [];
}

class _SyncException implements Exception {
  final String message;

  _SyncException(this.message);

  @override
  String toString() => message;
}

/// 增量同步的变更集
class _ChangeSet {
  final List<String> addedOrModified;
  final List<String> removed;

  _ChangeSet({required this.addedOrModified, required this.removed});
}
