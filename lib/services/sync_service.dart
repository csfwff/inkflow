import 'package:flutter/foundation.dart';
import '../models/article.dart';
import 'frontmatter_helper.dart';
import 'github_service.dart';
import 'article_service.dart';

class SyncService {
  final GitHubService github;
  final ArticleService articleService;

  SyncService({required this.github, required this.articleService});

  Future<Article?> fetchRemoteArticle(Article local) async {
    final remotePath = local.effectiveRemotePath;
    if (remotePath == null || remotePath.isEmpty) return null;

    final remoteKind =
        local.effectiveRemoteKind ?? _remoteKindForPath(remotePath);
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
        final remotePath = a.effectiveRemotePath;
        if (remotePath != null) remotePaths.add(remotePath);
      }
      debugPrint('[Sync] Remote paths: $remotePaths');

      // upsert 远程文章
      for (final article in remoteArticles) {
        await articleService.upsertFromGitHub(article);
      }

      // 检测远程已删除：本地 synced/repoDraft 但远程不存在的
      final localSynced = await articleService.getRemoteTracked();
      debugPrint('[Sync] Local synced/repoDraft count: ${localSynced.length}');
      int deletedCount = 0;
      for (final local in localSynced) {
        if (local.status == ArticleStatus.pendingPublish) {
          continue;
        }

        final remotePath = local.effectiveRemotePath;
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

      debugPrint(
          '[Sync] === syncFromGitHub DONE: ${remoteArticles.length} synced, $deletedCount remote deleted ===');
      return SyncResult(success: true, count: remoteArticles.length);
    } catch (e, stack) {
      debugPrint('[Sync] EXCEPTION: $e');
      debugPrint('[Sync] STACK: $stack');
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<List<Article>> _syncDirectory(
    String dirPath,
    ArticleStatus status,
    ArticleRemoteKind remoteKind,
  ) async {
    debugPrint('[Sync] _syncDirectory: $dirPath');
    final List<Article> articles = [];
    final prefix = _prefixForRemoteKind(remoteKind);

    await _traverseDirectory(dirPath, prefix, status, remoteKind, articles);

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
    final topImg = (meta['top_img'] ?? meta['topImg'])?.toString();
    final cover = meta['cover']?.toString();
    final excerpt = meta['excerpt']?.toString();
    final description = meta['description']?.toString();
    final author = meta['author']?.toString();

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
    );
  }

  /// 将 YAML 值转为字符串列表（兼容行内 `[a, b]` 和块状列表写法）。
  static List<String> _toStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      // 兼容旧的逗号分隔格式
      return value.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
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
