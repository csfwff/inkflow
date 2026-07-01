import 'package:drift/drift.dart';
import '../models/friend_link.dart';
import 'database/app_database.dart';
import 'friend_link_parser.dart';
import 'github_service.dart';
import 'log_service.dart';

class FriendLinkService {
  late final AppDatabase _db;
  static final _log = LogService.instance;

  Future<void> init() async {
    _db = await AppDatabase.create();
  }

  // ── CRUD ──

  /// 获取所有友链
  Future<List<FriendLink>> getAll() async {
    final query = _db.select(_db.friendLinkRows)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    final rows = await query.get();
    return rows.map(friendLinkFromRow).toList();
  }

  /// 按 ID 获取
  Future<FriendLink?> getById(int id) async {
    final row = await (_db.select(_db.friendLinkRows)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : friendLinkFromRow(row);
  }

  /// 按名称获取
  Future<FriendLink?> getByName(String name) async {
    final row = await (_db.select(_db.friendLinkRows)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    return row == null ? null : friendLinkFromRow(row);
  }

  /// 插入友链
  Future<int> insert(FriendLink link) async {
    return await _db.into(_db.friendLinkRows).insert(friendLinkToCompanion(link));
  }

  /// 更新友链
  Future<void> update(FriendLink link) async {
    await (_db.update(_db.friendLinkRows)..where((t) => t.id.equals(link.id!)))
        .write(friendLinkToCompanion(link));
  }

  /// 删除友链
  Future<void> delete(int id) async {
    await (_db.delete(_db.friendLinkRows)..where((t) => t.id.equals(id))).go();
  }

  /// 批量插入（跳过已存在的同名友链）
  Future<int> insertBatch(List<FriendLink> links) async {
    var count = 0;
    for (final link in links) {
      final existing = await getByName(link.name);
      if (existing == null) {
        await insert(link);
        count++;
      }
    }
    return count;
  }

  // ── GitHub 同步 ──

  /// 从 GitHub 拉取友链文件并解析
  Future<SyncResult> syncFromGitHub(GitHubService github, String filePath) async {
    try {
      _log.logAction('同步友链', detail: '从 GitHub 拉取');

      final fileData = await github.getFileContent(filePath);
      if (fileData == null) {
        _log.warn('友链文件不存在: $filePath', tag: 'FriendLink');
        return SyncResult(success: true, count: 0, message: '文件不存在');
      }

      final links = FriendLinkParser.parseYaml(fileData.content);
      _log.info('解析到 ${links.length} 条友链', tag: 'FriendLink');

      // 清空本地数据并重新插入
      await _db.delete(_db.friendLinkRows).go();
      for (final link in links) {
        await insert(link);
      }

      _log.logAction('同步友链完成', detail: '${links.length} 条');
      return SyncResult(success: true, count: links.length);
    } catch (e) {
      _log.error('同步友链失败: $e', tag: 'FriendLink');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// 推送友链到 GitHub
  Future<SyncResult> pushToGitHub(GitHubService github, String filePath) async {
    try {
      _log.logAction('推送友链', detail: '推送到 GitHub');

      final links = await getAll();
      final yaml = FriendLinkParser.generateYaml(links);

      // 检查文件是否存在
      final existing = await github.getFileContent(filePath);
      if (existing != null) {
        await github.updateFile(
          remotePath: filePath,
          content: yaml,
          sha: existing.sha,
          commitMessage: 'update friend links',
        );
        _log.info('更新友链文件: $filePath', tag: 'FriendLink');
      } else {
        await github.createFile(
          remotePath: filePath,
          content: yaml,
          commitMessage: 'add friend links',
        );
        _log.info('创建友链文件: $filePath', tag: 'FriendLink');
      }

      _log.logAction('推送友链完成', detail: '${links.length} 条');
      return SyncResult(success: true, count: links.length);
    } catch (e) {
      _log.error('推送友链失败: $e', tag: 'FriendLink');
      return SyncResult(success: false, error: e.toString());
    }
  }
}

/// 同步结果
class SyncResult {
  final bool success;
  final int count;
  final String? error;
  final String? message;

  SyncResult({
    required this.success,
    this.count = 0,
    this.error,
    this.message,
  });
}
