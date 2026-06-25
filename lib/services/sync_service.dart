import 'package:flutter/foundation.dart';
import '../models/article.dart';
import 'frontmatter_helper.dart';
import 'github_service.dart';
import 'article_service.dart';
import 'settings_service.dart';

class SyncService {
  final GitHubService github;
  final ArticleService articleService;
  final SettingsService settingsService;

  SyncService({
    required this.github,
    required this.articleService,
    required this.settingsService,
  });

  Future<Article?> fetchRemoteArticle(Article local) async {
    final remotePath = local.remotePath;
    if (remotePath == null || remotePath.isEmpty) return null;

    final remoteKind =
        local.remoteKind ?? _remoteKindForPath(remotePath);
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
      debugPrint('[Sync] === syncFromGitHub START ===');
      final List<Article> remoteArticles = [];

      // 同步已发布文章 (source/_posts)
      debugPrint('[Sync] Syncing source/_posts ...');
      final posts = await _syncDirectory(
        'source/_posts',
        ArticleStatus.synced,
        ArticleRemoteKind.post,
      );
      debugPrint('[Sync] source/_posts -> ${posts.length} articles');
      remoteArticles.addAll(posts);

      // 同步仓库草稿 (source/_drafts)
      debugPrint('[Sync] Syncing source/_drafts ...');
      final drafts = await _syncDirectory(
        'source/_drafts',
        ArticleStatus.repoDraft,
        ArticleRemoteKind.repoDraft,
      );
      debugPrint('[Sync] source/_drafts -> ${drafts.length} articles');
      remoteArticles.addAll(drafts);

      debugPrint('[Sync] Total remote articles: ${remoteArticles.length}');

      // 收集远程存在的完整路径，避免 posts/drafts 同名文件互相混淆。
      final remotePaths = <String>{};
      for (final a in remoteArticles) {
        final remotePath = a.remotePath;
        if (remotePath != null) remotePaths.add(remotePath);
      }
      debugPrint('[Sync] Remote paths: $remotePaths');

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

      // 检测远程已删除：本地 synced/repoDraft 但远程不存在的
      final localSynced = await articleService.getRemoteTracked();
      debugPrint('[Sync] Local synced/repoDraft count: ${localSynced.length}');
      int deletedCount = 0;
      for (final local in localSynced) {
        if (local.status == ArticleStatus.pendingPublish) {
          continue;
        }

        final remotePath = local.remotePath;
        if (remotePath == null || !remotePaths.contains(remotePath)) {
          debugPrint(
              '[Sync] Remote deleted: "${local.title}" (${remotePath ?? local.filePath})');
          await articleService.markAsRemoteDeleted(local.id!);
          deletedCount++;
        }
      }
      if (deletedCount > 0) {
        debugPrint('[Sync] Marked $deletedCount articles as remote deleted');
      }

      // 更新 lastSyncTime
      settingsService.settings.lastSyncTime = DateTime.now();
      await settingsService.save();
      debugPrint('[Sync] Updated lastSyncTime: ${settingsService.settings.lastSyncTime}');

      debugPrint(
          '[Sync] === syncFromGitHub DONE: ${remoteArticles.length} synced, $deletedCount remote deleted ===');
      return SyncResult(success: true, count: remoteArticles.length);
    } catch (e, stack) {
      debugPrint('[Sync] EXCEPTION: $e');
      debugPrint('[Sync] STACK: $stack');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 增量同步：基于 commit 记录只拉取变更文件
  Future<SyncResult> syncIncremental() async {
    try {
      debugPrint('[Sync] === syncIncremental START ===');

      final lastSyncTime = settingsService.settings.lastSyncTime;
      if (lastSyncTime == null) {
        debugPrint('[Sync] No lastSyncTime, falling back to full sync');
        return syncFromGitHub();
      }

      debugPrint('[Sync] lastSyncTime: $lastSyncTime');

      // 获取两个目录的 commit 记录
      final postsCommits = await github.getCommitsSince(
        path: 'source/_posts',
        since: lastSyncTime,
      );
      final draftsCommits = await github.getCommitsSince(
        path: 'source/_drafts',
        since: lastSyncTime,
      );

      debugPrint(
          '[Sync] Commits: posts=${postsCommits.length}, drafts=${draftsCommits.length}');

      // 提取变更文件
      final postsChanges = _extractChanges(postsCommits, 'source/_posts/');
      final draftsChanges = _extractChanges(draftsCommits, 'source/_drafts/');

      debugPrint(
          '[Sync] Changes: posts added/modified=${postsChanges.addedOrModified.length}, removed=${postsChanges.removed.length}');
      debugPrint(
          '[Sync] Changes: drafts added/modified=${draftsChanges.addedOrModified.length}, removed=${draftsChanges.removed.length}');

      // 如果变更太多（>200个文件），降级到全量同步
      final totalChanges = postsChanges.addedOrModified.length +
          postsChanges.removed.length +
          draftsChanges.addedOrModified.length +
          draftsChanges.removed.length;
      if (totalChanges > 200) {
        debugPrint(
            '[Sync] Too many changes ($totalChanges), falling back to full sync');
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
        deletedCount += await _markRemoteDeleted(filePath);
      }
      for (final filePath in draftsChanges.removed) {
        deletedCount += await _markRemoteDeleted(filePath);
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
        debugPrint('[Sync] Updated lastSyncTime: $latestDate');
      }

      debugPrint(
          '[Sync] === syncIncremental DONE: $syncedCount synced, $deletedCount deleted ===');
      return SyncResult(success: true, count: syncedCount);
    } catch (e, stack) {
      debugPrint('[Sync] Incremental sync EXCEPTION: $e');
      debugPrint('[Sync] STACK: $stack');
      // 增量同步失败，降级到全量同步
      debugPrint('[Sync] Falling back to full sync');
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
        if (!file.filename.startsWith(prefix)) continue;
        if (!file.filename.endsWith('.md')) continue;

        final relativePath =
            file.filename.substring(prefix.length);

        switch (file.status) {
          case 'added':
          case 'modified':
            addedOrModified.add(relativePath);
            removed.remove(relativePath);
            break;
          case 'removed':
            addedOrModified.remove(relativePath);
            removed.add(relativePath);
            break;
          case 'renamed':
            // renamed 的 old_filename 可能需要特殊处理
            // 简单起见，把新文件当作 added
            addedOrModified.add(relativePath);
            break;
        }
      }
    }

    return _ChangeSet(
      addedOrModified: addedOrModified.toList(),
      removed: removed.toList(),
    );
  }

  /// 获取单个文件并解析
  Future<Article?> _fetchAndParseFile(
    String relativePath,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
  ) async {
    final prefix = _prefixForRemoteKind(remoteKind);
    final remotePath = '$prefix$relativePath';

    debugPrint('[Sync] Fetching: $remotePath');
    final fileData = await github.getFileContent(remotePath);
    if (fileData == null) {
      debugPrint('[Sync] Failed to fetch: $remotePath');
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

  /// 根据 remotePath 查找并标记为 remoteDeleted
  Future<int> _markRemoteDeleted(String relativePath) async {
    final articles = await articleService.getRemoteTracked();
    int count = 0;
    for (final article in articles) {
      if (article.remotePath != null &&
          article.remotePath!.endsWith('/$relativePath')) {
        await articleService.markAsRemoteDeleted(article.id!);
        count++;
        debugPrint('[Sync] Marked remote deleted: "${article.title}"');
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

  Future<List<Article>> _syncDirectory(
    String dirPath,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
  ) async {
    debugPrint('[Sync] _syncDirectory: $dirPath');
    final List<Article> articles = [];
    final prefix = _prefixForRemoteKind(remoteKind);

    try {
      await _traverseDirectory(dirPath, prefix, status, remoteKind, articles);
    } on _SyncException catch (e) {
      // 根目录（source/_posts、source/_drafts）不存在时允许跳过
      if (e.message.contains('404')) {
        debugPrint('[Sync] Directory not found (404), skipping: $dirPath');
        return articles;
      }
      rethrow;
    }

    debugPrint('[Sync] $dirPath -> ${articles.length} articles total');
    return articles;
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

    final entries = result.entries;
    debugPrint(
        '[Sync] $currentPath -> ${entries.length} entries: ${entries.map((e) => '${e.name}(${e.type})').join(', ')}');

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
        debugPrint('[Sync]   reading: ${entry.path}');
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
          debugPrint('[Sync]   parsed: "${article.title}" ($filePath)');
          articles.add(article);
        } else {
          debugPrint('[Sync]   FAILED to parse frontmatter: ${entry.path}');
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
    final date = FrontmatterHelper.parseDate((meta['date'] ?? '').toString()) ??
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
      'title', 'date', 'tags', 'categories', 'permalink',
      'top_img', 'cover', 'excerpt', 'description', 'author',
    };
    final customFields = <String, String>{};
    for (final entry in meta.entries) {
      if (!knownKeys.contains(entry.key)) {
        customFields[entry.key] = entry.value.toString();
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
      return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
}

class SyncResult {
  final bool success;
  final int count;
  final String? error;

  SyncResult({required this.success, this.count = 0, this.error});
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

  _ChangeSet({
    required this.addedOrModified,
    required this.removed,
  });
}
