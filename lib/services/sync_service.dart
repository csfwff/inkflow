import 'package:flutter/foundation.dart';
import '../models/article.dart';
import 'github_service.dart';
import 'article_service.dart';

class SyncService {
  final GitHubService github;
  final ArticleService articleService;

  SyncService({required this.github, required this.articleService});

  Future<SyncResult> syncFromGitHub() async {
    try {
      debugPrint('[Sync] === syncFromGitHub START ===');
      final List<Article> remoteArticles = [];

      // 同步已发布文章 (source/_posts)
      debugPrint('[Sync] Syncing source/_posts ...');
      final posts = await _syncDirectory('source/_posts', ArticleStatus.synced);
      debugPrint('[Sync] source/_posts -> ${posts.length} articles');
      remoteArticles.addAll(posts);

      // 同步仓库草稿 (source/_drafts)
      debugPrint('[Sync] Syncing source/_drafts ...');
      final drafts = await _syncDirectory('source/_drafts', ArticleStatus.repoDraft);
      debugPrint('[Sync] source/_drafts -> ${drafts.length} articles');
      remoteArticles.addAll(drafts);

      debugPrint('[Sync] Total remote articles: ${remoteArticles.length}');

      // 收集远程存在的 filePath（posts 和 drafts 分开，带前缀以区分来源）
      final remoteFilePaths = <String>{};
      for (final a in remoteArticles) {
        remoteFilePaths.add(a.filePath);
      }
      debugPrint('[Sync] Remote filePaths: $remoteFilePaths');

      // upsert 远程文章
      for (final article in remoteArticles) {
        await articleService.upsertFromGitHub(article);
      }

      // 检测远程已删除：本地 synced/repoDraft 但远程不存在的
      final localSynced = await articleService.getSyncedAndRepoDrafts();
      debugPrint('[Sync] Local synced/repoDraft count: ${localSynced.length}');
      int deletedCount = 0;
      for (final local in localSynced) {
        if (!remoteFilePaths.contains(local.filePath)) {
          debugPrint('[Sync] Remote deleted: "${local.title}" (${local.filePath})');
          await articleService.markAsDraft(local.id!);
          deletedCount++;
        }
      }
      if (deletedCount > 0) {
        debugPrint('[Sync] Marked $deletedCount articles as remote deleted');
      }

      debugPrint('[Sync] === syncFromGitHub DONE: ${remoteArticles.length} synced, $deletedCount remote deleted ===');
      return SyncResult(success: true, count: remoteArticles.length);
    } catch (e, stack) {
      debugPrint('[Sync] EXCEPTION: $e');
      debugPrint('[Sync] STACK: $stack');
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<List<Article>> _syncDirectory(String dirPath, ArticleStatus status) async {
    debugPrint('[Sync] _syncDirectory: $dirPath');
    final List<Article> articles = [];
    final prefix = '$dirPath/';

    await _traverseDirectory(dirPath, prefix, status, articles);

    debugPrint('[Sync] $dirPath -> ${articles.length} articles total');
    return articles;
  }

  Future<void> _traverseDirectory(
    String currentPath,
    String prefix,
    ArticleStatus status,
    List<Article> articles,
  ) async {
    final entries = await github.listDirectoryContents(currentPath);
    debugPrint('[Sync] $currentPath -> ${entries.length} entries: ${entries.map((e) => '${e.name}(${e.type})').join(', ')}');

    for (final entry in entries) {
      // entry.path 是 API 返回的完整路径，如 source/_posts/2026/05/test.md
      if (entry.type == 'dir') {
        await _traverseDirectory(entry.path, prefix, status, articles);
      } else if (entry.name.endsWith('.md')) {
        debugPrint('[Sync]   reading: ${entry.path}');
        final fileData = await github.getFileContent(entry.path);
        if (fileData == null) {
          debugPrint('[Sync]   FAILED to read ${entry.path}');
          continue;
        }

        final filePath = entry.path.startsWith(prefix)
            ? entry.path.substring(prefix.length)
            : entry.path;
        final article = _parseFrontmatter(
          fileData.content,
          filePath: filePath,
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
    required String sha,
    required ArticleStatus status,
  }) {
    final regex = RegExp(r'^---\s*\n(.*?)\n---\s*\n(.*)$', dotAll: true);
    final match = regex.firstMatch(rawContent);

    String title = '';
    DateTime date = DateTime.now();
    List<String> tags = [];
    List<String> categories = [];
    String? permalink;
    String? topImg;
    String? cover;
    String? excerpt;
    String? description;
    String? author;

    if (match != null) {
      final meta = match.group(1)!;

      for (final line in meta.split('\n')) {
        if (line.startsWith('title:')) {
          title = line.substring(6).trim();
        } else if (line.startsWith('date:')) {
          date = DateTime.tryParse(line.substring(5).trim()) ?? DateTime.now();
        } else if (line.startsWith('tags:')) {
          final raw = line.substring(5).trim();
          // tags: [a, b, c] or tags: a, b, c
          final inner = raw.startsWith('[') && raw.endsWith(']')
              ? raw.substring(1, raw.length - 1)
              : raw;
          tags = inner.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
        } else if (line.startsWith('categories:')) {
          // categories 是多行的，后面以 - 开头
          // 这里简单处理：跳过，下面用循环收集
        } else if (line.trimLeft().startsWith('- ') && categories.isEmpty == false) {
          // 已在 categories 模式中
        } else if (line.startsWith('permalink:')) {
          permalink = line.substring(10).trim();
        } else if (line.startsWith('top_img:')) {
          topImg = line.substring(8).trim();
        } else if (line.startsWith('cover:')) {
          cover = line.substring(6).trim();
        } else if (line.startsWith('excerpt:')) {
          excerpt = line.substring(8).trim();
        } else if (line.startsWith('description:')) {
          description = line.substring(12).trim();
        } else if (line.startsWith('author:')) {
          author = line.substring(7).trim();
        }
      }

      // tags / categories 的块状写法（key 下方以 `  - item` 多行列出）。
      // tags 已在上面解析了行内写法（[a, b] / a, b），仅当行内为空时再按块状解析。
      if (tags.isEmpty) {
        tags = _parseBlockList(meta, 'tags');
      }
      categories = _parseBlockList(meta, 'categories');
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

  /// 解析块状列表写法（key 下方以 `  - item` 多行列出），tags / categories 共用。
  /// 行内写法（如 `tags: [a, b]`）不在此处理，返回空列表。
  static List<String> _parseBlockList(String meta, String key) {
    final match = RegExp(key + r':\s*\n((?:\s+-\s+.+\n?)*)').firstMatch(meta);
    if (match == null) return [];
    return RegExp(r'-\s+(.+)')
        .allMatches(match.group(1)!)
        .map((m) => m.group(1)!.trim())
        .toList();
  }
}

class SyncResult {
  final bool success;
  final int count;
  final String? error;

  SyncResult({required this.success, this.count = 0, this.error});
}
