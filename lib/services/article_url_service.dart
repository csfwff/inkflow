import 'package:path/path.dart' as p;

import '../models/article.dart';
import '../models/settings.dart';
import 'github_service.dart';

class ArticleUrlService {
  static final Map<String, Uri?> _pagesBaseCache = {};

  static bool canInferUrl(Article article, Settings settings) {
    return settings.githubOwner.trim().isNotEmpty &&
        settings.githubRepo.trim().isNotEmpty &&
        _isPublishedPost(article);
  }

  static Future<Uri?> resolveArticleUrl(
    Article article,
    Settings settings,
  ) async {
    if (!canInferUrl(article, settings)) return null;

    final baseUrl = await _resolvePagesBaseUrl(settings);
    if (baseUrl == null) return null;

    final pathOrUrl = _articlePath(article, settings);
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;

    final absolute = Uri.tryParse(pathOrUrl);
    if (absolute != null &&
        (absolute.scheme == 'http' || absolute.scheme == 'https')) {
      return _ensureHttps(absolute);
    }

    return _ensureHttps(_joinBaseAndPath(baseUrl, pathOrUrl));
  }

  /// 统一升级为 https，避免 WebView 加载 http 明文流量时
  /// 报错 err_cleartext_not_permitted（GitHub Pages 始终支持 https）。
  static Uri _ensureHttps(Uri uri) {
    if (uri.scheme == 'http') return uri.replace(scheme: 'https');
    return uri;
  }

  static bool _isPublishedPost(Article article) {
    if (article.status == ArticleStatus.draft ||
        article.status == ArticleStatus.repoDraft ||
        article.status == ArticleStatus.remoteDeleted) {
      return false;
    }
    if (article.remoteKind == ArticleRemoteKind.post) return true;
    if (article.remotePath?.startsWith('source/_posts/') == true) return true;
    return article.status == ArticleStatus.synced;
  }

  static Future<Uri?> _resolvePagesBaseUrl(Settings settings) async {
    final owner = settings.githubOwner.trim();
    final repo = settings.githubRepo.trim();
    if (owner.isEmpty || repo.isEmpty) return null;

    final cacheKey = [
      owner,
      repo,
      settings.githubBranch.trim(),
      settings.githubToken.isNotEmpty ? 'auth' : 'anon',
    ].join('/');
    if (_pagesBaseCache.containsKey(cacheKey)) {
      return _pagesBaseCache[cacheKey];
    }

    Uri? pagesUrl;
    if (settings.githubToken.trim().isNotEmpty) {
      final github = GitHubService(
        token: settings.githubToken,
        owner: owner,
        repo: repo,
        branch: settings.githubBranch,
      );
      pagesUrl = await github.getPagesBaseUrl();
    }

    pagesUrl ??= _defaultGitHubPagesUrl(owner, repo);
    _pagesBaseCache[cacheKey] = pagesUrl;
    return pagesUrl;
  }

  static Uri _defaultGitHubPagesUrl(String owner, String repo) {
    final ownerLower = owner.toLowerCase();
    final repoLower = repo.toLowerCase();
    if (repoLower == '$ownerLower.github.io') {
      return Uri.parse('https://$owner.github.io/');
    }
    return Uri.parse('https://$owner.github.io/$repo/');
  }

  static String? _articlePath(Article article, Settings settings) {
    final permalink = article.permalink?.trim();
    if (permalink != null && permalink.isNotEmpty) {
      return permalink;
    }

    final slug = _slugFor(article);
    if (slug.isEmpty) return null;

    final pattern = settings.permalinkPattern.trim();
    if (pattern.isNotEmpty) {
      return _resolvePattern(
        pattern,
        article: article,
        slug: slug,
        category: article.categories.isNotEmpty ? article.categories.first : '',
      );
    }

    return [
      article.date.year.toString().padLeft(4, '0'),
      article.date.month.toString().padLeft(2, '0'),
      article.date.day.toString().padLeft(2, '0'),
      slug,
    ].join('/');
  }

  static String _slugFor(Article article) {
    if (article.slug.trim().isNotEmpty) return article.slug.trim();
    final filePath = article.filePath.trim().isNotEmpty
        ? article.filePath.trim()
        : (article.remotePath ?? '').trim();
    if (filePath.isEmpty) return '';
    return p.basenameWithoutExtension(filePath);
  }

  static String _resolvePattern(
    String pattern, {
    required Article article,
    required String slug,
    required String category,
  }) {
    return pattern
        .replaceAll('{year}', article.date.year.toString())
        .replaceAll('{month}', article.date.month.toString().padLeft(2, '0'))
        .replaceAll('{day}', article.date.day.toString().padLeft(2, '0'))
        .replaceAll(
          '{timestamp}',
          (article.date.millisecondsSinceEpoch ~/ 1000).toString(),
        )
        .replaceAll('{slug}', slug)
        .replaceAll('{category}', category);
  }

  static Uri _joinBaseAndPath(Uri baseUrl, String path) {
    final base = _ensureTrailingSlash(baseUrl);
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    final joinedPath = '$basePath$cleanPath';
    return Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: _normalizePath(joinedPath),
    );
  }

  static Uri _ensureTrailingSlash(Uri uri) {
    if (uri.path.endsWith('/')) return uri;
    return uri.replace(path: '${uri.path}/');
  }

  static String _normalizePath(String value) {
    final hasTrailingSlash = value.endsWith('/');
    final segments = value
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .toList();
    final normalized = '/${segments.join('/')}';
    return hasTrailingSlash && normalized != '/' ? '$normalized/' : normalized;
  }
}
