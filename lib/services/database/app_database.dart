import 'dart:convert';
import 'package:drift/drift.dart';

import '../../models/article.dart';
import '../../models/friend_link.dart';
import '_db_native.dart' if (dart.library.js_interop) '_db_web.dart';

part 'app_database.g.dart';

class ArticleRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  TextColumn get date => text()();
  TextColumn get slug => text().withDefault(const Constant(''))();
  IntColumn get status => intEnum<ArticleStatus>()();
  TextColumn get filePath => text().withDefault(const Constant(''))();
  TextColumn get remotePath => text().nullable()();
  IntColumn get remoteKind => intEnum<ArticleRemoteKind>().nullable()();
  TextColumn get githubSha => text().nullable()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  TextColumn get categories => text().withDefault(const Constant(''))();
  TextColumn get permalink => text().nullable()();
  TextColumn get topImg => text().nullable()();
  TextColumn get cover => text().nullable()();
  TextColumn get excerpt => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get author => text().nullable()();
  TextColumn get customFields => text().withDefault(const Constant('{}'))();
}

/// 标签表
class TagRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get createdAt => text()();

  @override
  List<Set<Column>> get uniqueKeys => [{name}];
}

/// 分类表
class CategoryRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get createdAt => text()();

  @override
  List<Set<Column>> get uniqueKeys => [{name}];
}

/// 友链表
class FriendLinkRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get link => text().withDefault(const Constant(''))();
  TextColumn get avatar => text().withDefault(const Constant(''))();
  TextColumn get descr => text().withDefault(const Constant(''))();
  BoolColumn get isCommented => boolean().withDefault(const Constant(false))();
  BoolColumn get isDev => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();

  @override
  List<Set<Column>> get uniqueKeys => [{name}];
}

@DriftDatabase(tables: [ArticleRows, TagRows, CategoryRows, FriendLinkRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(friendLinkRows);
          }
          if (from < 3) {
            // 友链排序字段；旧数据保持 0，getAll 按 (sortOrder, id) 兜底，
            // 旧记录顺次落在 id（插入）序，下次同步会用文件顺序覆盖。
            await m.addColumn(friendLinkRows, friendLinkRows.sortOrder);
          }
        },
      );

  static Future<AppDatabase> create() async {
    final executor = await openConnection();
    return AppDatabase(executor);
  }
}

// --- Article model <-> ArticleRow conversion ---

ArticleRowsCompanion toCompanion(Article a) => ArticleRowsCompanion(
      id: a.id != null ? Value(a.id!) : const Value.absent(),
      title: Value(a.title),
      content: Value(a.content),
      date: Value(a.date.toIso8601String()),
      slug: Value(a.slug),
      status: Value(a.status),
      filePath: Value(a.filePath),
      remotePath: Value(a.remotePath),
      remoteKind: Value(a.remoteKind),
      githubSha: Value(a.githubSha),
      createdAt: Value(a.createdAt.toIso8601String()),
      updatedAt: Value(a.updatedAt.toIso8601String()),
      tags: Value(a.tags.join(',')),
      categories: Value(a.categories.join(',')),
      permalink: Value(a.permalink),
      topImg: Value(a.topImg),
      cover: Value(a.cover),
      excerpt: Value(a.excerpt),
      description: Value(a.description),
      author: Value(a.author),
      customFields: Value(jsonEncode(a.customFields)),
    );

Article articleFromRow(ArticleRow row) => Article(
      id: row.id,
      title: row.title,
      content: row.content,
      date: DateTime.parse(row.date),
      slug: row.slug,
      status: row.status,
      filePath: row.filePath,
      remotePath: row.remotePath,
      remoteKind: row.remoteKind,
      githubSha: row.githubSha,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
      tags: row.tags.split(',').where((t) => t.isNotEmpty).toList(),
      categories: row.categories.split(',').where((c) => c.isNotEmpty).toList(),
      permalink: row.permalink,
      topImg: row.topImg,
      cover: row.cover,
      excerpt: row.excerpt,
      description: row.description,
      author: row.author,
      customFields: _parseCustomFields(row.customFields),
    );

Map<String, String> _parseCustomFields(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map) {
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
  } catch (_) {}
  return {};
}

// --- FriendLink model <-> FriendLinkRow conversion ---

FriendLinkRowsCompanion friendLinkToCompanion(FriendLink fl) => FriendLinkRowsCompanion(
      id: fl.id != null ? Value(fl.id!) : const Value.absent(),
      name: Value(fl.name),
      link: Value(fl.link),
      avatar: Value(fl.avatar),
      descr: Value(fl.descr),
      isCommented: Value(fl.isCommented),
      isDev: Value(fl.isDev),
      sortOrder: Value(fl.sortOrder),
      createdAt: Value(fl.createdAt.toIso8601String()),
    );

FriendLink friendLinkFromRow(FriendLinkRow row) => FriendLink(
      id: row.id,
      name: row.name,
      link: row.link,
      avatar: row.avatar,
      descr: row.descr,
      isCommented: row.isCommented,
      isDev: row.isDev,
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
    );
