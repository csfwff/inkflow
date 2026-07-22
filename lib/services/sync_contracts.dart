import '../models/article.dart';
import '../models/settings.dart';

/// 最小化同步服务对文章存储的依赖，便于隔离测试同步安全逻辑。
abstract interface class SyncArticleStore {
  Future<void> upsertFromGitHub(Article article);

  Future<void> replaceWithRemote(Article article);

  Future<List<Article>> getRemoteTracked();

  Future<void> ensureTags(List<String> names);

  Future<void> ensureCategories(List<String> names);

  Future<void> markAsRemoteDeleted(int id);
}

/// 最小化同步服务对设置存储的依赖。
abstract interface class SyncSettingsStore {
  Settings get settings;

  Future<void> save();
}
