import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/article.dart';

class ArticleService {
  late Database _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'inkflow.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE articles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            date TEXT NOT NULL,
            slug TEXT NOT NULL,
            status INTEGER NOT NULL DEFAULT 0,
            filePath TEXT NOT NULL DEFAULT '',
            githubSha TEXT,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insert(Article article) async {
    final map = article.toMap();
    map.remove('id');
    return await _db.insert('articles', map);
  }

  Future<void> update(Article article) async {
    await _db.update(
      'articles',
      article.toMap(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
  }

  Future<void> delete(int id) async {
    await _db.delete('articles', where: 'id = ?', whereArgs: [id]);
  }

  Future<Article?> getById(int id) async {
    final maps = await _db.query('articles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Article.fromMap(maps.first);
  }

  Future<List<Article>> getAll({ArticleStatus? status}) async {
    final orderBy = 'date DESC';
    if (status != null) {
      final maps = await _db.query(
        'articles',
        where: 'status = ?',
        whereArgs: [status.index],
        orderBy: orderBy,
      );
      return maps.map((m) => Article.fromMap(m)).toList();
    }
    final maps = await _db.query('articles', orderBy: orderBy);
    return maps.map((m) => Article.fromMap(m)).toList();
  }

  Future<List<Article>> getDrafts() => getAll(status: ArticleStatus.draft);

  Future<List<Article>> getSynced() => getAll(status: ArticleStatus.synced);

  Future<List<Article>> getRepoDrafts() => getAll(status: ArticleStatus.repoDraft);

  Future<void> upsertFromGitHub(Article article) async {
    final existing = await _db.query(
      'articles',
      where: 'filePath = ?',
      whereArgs: [article.filePath],
    );
    if (existing.isNotEmpty) {
      await _db.update(
        'articles',
        {
          'title': article.title,
          'content': article.content,
          'date': article.date.toIso8601String(),
          'slug': article.slug,
          'status': article.status.index,
          'githubSha': article.githubSha,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'filePath = ?',
        whereArgs: [article.filePath],
      );
    } else {
      await _db.insert('articles', article.toMap()..remove('id'));
    }
  }

  Future<void> markAsSynced(int id, String githubSha) async {
    await _db.update(
      'articles',
      {
        'status': ArticleStatus.synced.index,
        'githubSha': githubSha,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsRepoDraft(int id, String githubSha) async {
    await _db.update(
      'articles',
      {
        'status': ArticleStatus.repoDraft.index,
        'githubSha': githubSha,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Article>> getSyncedAndRepoDrafts() async {
    final maps = await _db.query(
      'articles',
      where: 'status IN (?, ?)',
      whereArgs: [ArticleStatus.synced.index, ArticleStatus.repoDraft.index],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Article.fromMap(m)).toList();
  }

  Future<void> markAsDraft(int id) async {
    await _db.update(
      'articles',
      {
        'status': ArticleStatus.draft.index,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
