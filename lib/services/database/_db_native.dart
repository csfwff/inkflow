import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

Future<QueryExecutor> openConnection() async {
  final dbDir = await _getDbDir();
  final file = File(p.join(dbDir.path, 'inkflow.db'));
  return NativeDatabase.createInBackground(file);
}

Future<Directory> _getDbDir() async {
  // 尝试 path_provider，不可用时回退到可执行文件目录
  try {
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  } catch (_) {
    return Directory('.');
  }
}

// path_provider 可能不在依赖中，直接用 Platform 拿路径
Future<Directory> getApplicationDocumentsDirectory() async {
  if (Platform.isLinux) {
    final home = Platform.environment['HOME'] ?? '.';
    return Directory(p.join(home, '.local', 'share', 'inkflow'));
  }
  if (Platform.isWindows) {
    final appData = Platform.environment['APPDATA'] ?? '.';
    return Directory(p.join(appData, 'inkflow'));
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '.';
    return Directory(
        p.join(home, 'Library', 'Application Support', 'inkflow'));
  }
  // Android/iOS — 由 path_provider 处理，此处不应到达
  return Directory('.');
}
