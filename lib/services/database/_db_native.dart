import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> openConnection() async {
  final dbDir = await _getDbDir();
  // 确保目录存在
  if (!await dbDir.exists()) {
    await dbDir.create(recursive: true);
  }
  final dbPath = p.join(dbDir.path, 'inkflow.db');
  return SqfliteQueryExecutor(path: dbPath);
}

Future<Directory> _getDbDir() async {
  if (Platform.isAndroid || Platform.isIOS) {
    // Android/iOS 使用 path_provider
    return await getApplicationDocumentsDirectory();
  }
  // 桌面平台使用自定义路径
  try {
    final dir = await _getDesktopDir();
    return dir;
  } catch (_) {
    return Directory('.');
  }
}

Future<Directory> _getDesktopDir() async {
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
    return Directory(p.join(home, 'Library', 'Application Support', 'inkflow'));
  }
  return Directory('.');
}
