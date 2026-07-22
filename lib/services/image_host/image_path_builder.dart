import '../../models/settings.dart';

/// 各图床上传器 + 配置页预览共用的远程路径构造。
///
/// 规范化 [basePath] 的首尾斜杠，按 [dateFolderMode] 决定是否插入子目录，
/// 再按 [namingMode] 决定文件名，最终用 `/` 拼接（不含前导斜杠）。
String buildRemoteImagePath(
  String basePath,
  String filename, {
  required ImageDateFolderMode dateFolderMode,
  required ImageNamingMode namingMode,
}) {
  final now = DateTime.now();
  final cleanBase = basePath
      .replaceAll(RegExp(r'^/+|/+$'), '')
      .replaceAll(RegExp(r'/+'), '/');
  final parts = <String>[
    if (cleanBase.isNotEmpty) cleanBase,
    if (dateFolderMode == ImageDateFolderMode.year) '${now.year}',
    if (dateFolderMode == ImageDateFolderMode.yearMonth)
      '${now.year}/${now.month.toString().padLeft(2, '0')}',
    _resolveName(filename, namingMode, now),
  ];
  return parts.join('/');
}

String _resolveName(String filename, ImageNamingMode mode, DateTime now) {
  switch (mode) {
    case ImageNamingMode.original:
      return filename;
    case ImageNamingMode.timestamp:
      final dot = filename.lastIndexOf('.');
      final ext = dot >= 0 ? filename.substring(dot) : '';
      return '${now.millisecondsSinceEpoch}$ext';
    case ImageNamingMode.timestampOriginal:
      return '${now.millisecondsSinceEpoch}_$filename';
  }
}
