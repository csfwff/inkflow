import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 日志等级
enum LogLevel { debug, info, warn, error }

/// 简单的文件日志服务，最大 5MB，超出后截断重写。
class LogService {
  static const int _maxSize = 5 * 1024 * 1024; // 5MB
  static LogService? _instance;
  File? _logFile;

  LogService._();

  static LogService get instance {
    _instance ??= LogService._();
    return _instance!;
  }

  Future<File> get logFile async {
    if (_logFile != null) return _logFile!;
    final dir = await getApplicationSupportDirectory();
    _logFile = File('${dir.path}${Platform.pathSeparator}inkflow.log');
    return _logFile!;
  }

  /// 写入一条日志（带等级）
  Future<void> log(LogLevel level, String message, {String tag = 'App'}) async {
    try {
      final file = await logFile;
      final now = DateTime.now().toString().substring(0, 23);
      final levelStr = level.name.toUpperCase().padRight(5);
      final line = '[$now][$levelStr][$tag] $message\n';

      // 同时输出到 debug console
      debugPrint(line.trimRight());

      // 检查文件大小，超过限制则截断（保留后半部分）
      if (await file.exists()) {
        final size = await file.length();
        if (size > _maxSize) {
          final content = await file.readAsString(encoding: utf8);
          final half = content.length ~/ 2;
          // 从中间位置找到下一个换行符，避免截断行
          final nextLine = content.indexOf('\n', half);
          final keep = nextLine > 0 ? content.substring(nextLine + 1) : content.substring(half);
          await file.writeAsString('[--- log truncated ---]\n$keep', encoding: utf8);
        }
      }

      // 追加写入
      await file.writeAsString(line, mode: FileMode.append, encoding: utf8);
    } catch (_) {
      // 日志写入失败不应影响正常功能
    }
  }

  /// 写入一条日志（兼容旧接口）
  Future<void> write(String message, {String tag = 'App'}) async {
    await log(LogLevel.info, message, tag: tag);
  }

  /// 便捷方法
  Future<void> debug(String message, {String tag = 'App'}) async {
    await log(LogLevel.debug, message, tag: tag);
  }

  Future<void> info(String message, {String tag = 'App'}) async {
    await log(LogLevel.info, message, tag: tag);
  }

  Future<void> warn(String message, {String tag = 'App'}) async {
    await log(LogLevel.warn, message, tag: tag);
  }

  Future<void> error(String message, {String tag = 'App'}) async {
    await log(LogLevel.error, message, tag: tag);
  }

  /// 记录用户操作路径
  Future<void> logAction(String action, {String? detail}) async {
    final msg = detail != null ? '$action - $detail' : action;
    await log(LogLevel.info, msg, tag: 'UserAction');
  }

  /// 读取全部日志内容
  Future<String> readAll() async {
    try {
      final file = await logFile;
      if (await file.exists()) {
        return await file.readAsString(encoding: utf8);
      }
    } catch (_) {}
    return '';
  }

  /// 清空日志
  Future<void> clear() async {
    try {
      final file = await logFile;
      if (await file.exists()) {
        await file.writeAsString('');
      }
    } catch (_) {}
  }

  /// 获取日志文件路径
  Future<String> get filePath async {
    final file = await logFile;
    return file.path;
  }
}
