import 'package:drift/drift.dart';
import '../models/article.dart';
import 'database/app_database.dart';

class ArticleService {
  late final AppDatabase _db;

  Future<void> init() async {
    _db = await AppDatabase.create();
  }

  Future<int> insert(Article article) async {
    return await _db.into(_db.articleRows).insert(toCompanion(article));
  }

  Future<void> update(Article article) async {
    await (_db.update(_db.articleRows)
          ..where((t) => t.id.equals(article.id!)))
        .write(toCompanion(article));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.articleRows)..where((t) => t.id.equals(id))).go();
  }

  Future<Article?> getById(int id) async {
    final row = await (_db.select(_db.articleRows)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : articleFromRow(row);
  }

  Future<List<Article>> getAll({ArticleStatus? status}) async {
    final query = _db.select(_db.articleRows)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);
    if (status != null) {
      query.where((t) => t.status.equalsValue(status));
    }
    final rows = await query.get();
    return rows.map(articleFromRow).toList();
  }

  Future<List<Article>> getDrafts() => getAll(status: ArticleStatus.draft);

  Future<List<Article>> getSynced() => getAll(status: ArticleStatus.synced);

  Future<List<Article>> getRepoDrafts() =>
      getAll(status: ArticleStatus.repoDraft);

  Future<List<Article>> getSyncedAndRepoDrafts() async {
    final rows = await (_db.select(_db.articleRows)
          ..where((t) =>
              t.status.equalsValue(ArticleStatus.synced) |
              t.status.equalsValue(ArticleStatus.repoDraft))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(articleFromRow).toList();
  }

  Future<void> upsertFromGitHub(Article article) async {
    final existing = await (_db.select(_db.articleRows)
          ..where((t) => t.filePath.equals(article.filePath))
          ..limit(1))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.articleRows)
            ..where((t) => t.id.equals(existing.id)))
          .write(ArticleRowsCompanion(
        title: Value(article.title),
        content: Value(article.content),
        date: Value(article.date.toIso8601String()),
        slug: Value(article.slug),
        status: Value(article.status),
        githubSha: Value(article.githubSha),
        updatedAt: Value(DateTime.now().toIso8601String()),
        tags: Value(article.tags.join(',')),
        categories: Value(article.categories.join(',')),
        permalink: Value(article.permalink),
        topImg: Value(article.topImg),
        cover: Value(article.cover),
        layout: Value(article.layout),
        comments: Value(article.comments == true ? 1 : 0),
        published: Value(article.published == true ? 1 : 0),
        excerpt: Value(article.excerpt),
        description: Value(article.description),
        author: Value(article.author),
      ));
    } else {
      await _db.into(_db.articleRows).insert(toCompanion(article));
    }
  }

  Future<void> markAsSynced(int id, String githubSha) async {
    await (_db.update(_db.articleRows)..where((t) => t.id.equals(id))).write(
      ArticleRowsCompanion(
        status: const Value(ArticleStatus.synced),
        githubSha: Value(githubSha),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> markAsRepoDraft(int id, String githubSha) async {
    await (_db.update(_db.articleRows)..where((t) => t.id.equals(id))).write(
      ArticleRowsCompanion(
        status: const Value(ArticleStatus.repoDraft),
        githubSha: Value(githubSha),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> markAsDraft(int id) async {
    await (_db.update(_db.articleRows)..where((t) => t.id.equals(id))).write(
      ArticleRowsCompanion(
        status: const Value(ArticleStatus.draft),
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
  }
}
