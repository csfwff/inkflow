import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../models/friend_link.dart';
import 'database/app_database.dart';
import 'friend_link_parser.dart';
import 'github_service.dart';
import 'log_service.dart';

/// 链接检测结果
class LinkCheckResult {
  final int? linkId;
  final String name;
  final String url;
  final bool isAccessible;
  final int? statusCode;
  final String? error;

  LinkCheckResult({
    this.linkId,
    required this.name,
    required this.url,
    required this.isAccessible,
    this.statusCode,
    this.error,
  });
}

class FriendLinkService {
  late final AppDatabase _db;
  static final _log = LogService.instance;

  /// 初始化服务，共享已有的数据库实例
  Future<void> init(AppDatabase db) async {
    _db = db;
  }

  // ── CRUD ──

  /// 获取所有友链（按列表顺序，即文件中的顺序）
  Future<List<FriendLink>> getAll() async {
    final query = _db.select(_db.friendLinkRows)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.id),
      ]);
    final rows = await query.get();
    return rows.map(friendLinkFromRow).toList();
  }

  /// 按 ID 获取
  Future<FriendLink?> getById(int id) async {
    final row = await (_db.select(
      _db.friendLinkRows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : friendLinkFromRow(row);
  }

  /// 按名称获取
  Future<FriendLink?> getByName(String name) async {
    final row = await (_db.select(
      _db.friendLinkRows,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    return row == null ? null : friendLinkFromRow(row);
  }

  /// 插入友链（自动追加到列表末尾）
  Future<int> insert(FriendLink link) async {
    link.sortOrder = await _nextSortOrder();
    return await _db
        .into(_db.friendLinkRows)
        .insert(friendLinkToCompanion(link));
  }

  /// 下一个可用的排序序号（追加到末尾用）
  Future<int> _nextSortOrder() async {
    final query = _db.select(_db.friendLinkRows)
      ..orderBy([(t) => OrderingTerm.desc(t.sortOrder)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return (row?.sortOrder ?? -1) + 1;
  }

  /// 更新友链
  Future<void> update(FriendLink link) async {
    await (_db.update(
      _db.friendLinkRows,
    )..where((t) => t.id.equals(link.id!))).write(friendLinkToCompanion(link));
  }

  /// 删除友链
  Future<void> delete(int id) async {
    await (_db.delete(_db.friendLinkRows)..where((t) => t.id.equals(id))).go();
  }

  /// 批量插入（跳过已存在的同名友链，按传入顺序追加到末尾）
  Future<int> insertBatch(List<FriendLink> links) async {
    var count = 0;
    var order = await _nextSortOrder();
    for (final link in links) {
      final existing = await getByName(link.name);
      if (existing == null) {
        link.sortOrder = order++;
        await _db.into(_db.friendLinkRows).insert(friendLinkToCompanion(link));
        count++;
      }
    }
    return count;
  }

  /// 持久化新的列表顺序（拖拽排序后调用）
  ///
  /// [orderedLinks] 为排序后的完整列表，仅写入序号发生变化的行。
  Future<void> saveOrder(List<FriendLink> orderedLinks) async {
    for (var i = 0; i < orderedLinks.length; i++) {
      final link = orderedLinks[i];
      if (link.id != null && link.sortOrder != i) {
        await update(link.copyWith(sortOrder: i));
      }
    }
  }

  // ── 链接检测 ──

  /// 检测单个链接是否可访问
  Future<LinkCheckResult> checkLink(FriendLink link) async {
    try {
      final response = await http
          .head(Uri.parse(link.link))
          .timeout(const Duration(seconds: 10));
      return LinkCheckResult(
        linkId: link.id,
        name: link.name,
        url: link.link,
        isAccessible: response.statusCode >= 200 && response.statusCode < 400,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return LinkCheckResult(
        linkId: link.id,
        name: link.name,
        url: link.link,
        isAccessible: false,
        error: e.toString(),
      );
    }
  }

  /// 批量检测所有启用的友链
  Future<List<LinkCheckResult>> checkAllLinks() async {
    final links = await getAll();
    final enabledLinks = links.where((l) => !l.isCommented).toList();

    _log.logAction('检测友链', detail: '${enabledLinks.length} 条');

    final results = <LinkCheckResult>[];
    for (final link in enabledLinks) {
      final result = await checkLink(link);
      results.add(result);
    }

    final accessible = results.where((r) => r.isAccessible).length;
    _log.info('友链检测完成: $accessible/${results.length} 可访问', tag: 'FriendLink');

    return results;
  }

  // ── GitHub 同步 ──

  /// 从 GitHub 拉取友链文件并解析
  Future<SyncResult> syncFromGitHub(
    GitHubService github,
    String filePath,
  ) async {
    try {
      _log.logAction('同步友链', detail: '从 GitHub 拉取');

      final fileData = await github.getFileContent(filePath);
      if (fileData == null) {
        _log.warn('友链文件不存在: $filePath', tag: 'FriendLink');
        return SyncResult(success: true, count: 0, message: '文件不存在');
      }

      final links = FriendLinkParser.parseYaml(fileData.content);
      _log.info('解析到 ${links.length} 条友链', tag: 'FriendLink');

      // 清空本地数据并按文件中的顺序重新插入
      await _db.delete(_db.friendLinkRows).go();
      for (var i = 0; i < links.length; i++) {
        final link = links[i]..sortOrder = i;
        await _db.into(_db.friendLinkRows).insert(friendLinkToCompanion(link));
      }

      _log.logAction('同步友链完成', detail: '${links.length} 条');
      return SyncResult(success: true, count: links.length);
    } catch (e, stack) {
      await _log.logException(e, stack, tag: 'FriendLink', context: '同步友链失败');
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
    } catch (e, stack) {
      await _log.logException(e, stack, tag: 'FriendLink', context: '推送友链失败');
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

  SyncResult({required this.success, this.count = 0, this.error, this.message});
}
