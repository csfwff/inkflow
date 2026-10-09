import 'dart:io';
import 'dart:typed_data';

/// 读取剪贴板里图片文件的字节内容（原生平台实现）。
///
/// [maxBytes] 大于 0 时超过该大小的文件会被跳过。路径不存在、不是普通文件
/// 或读取失败时返回 null，由调用方决定如何回退。
Future<Uint8List?> readClipboardFileBytes(
  String path, {
  int maxBytes = 0,
}) async {
  try {
    final file = File(path);
    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) return null;
    if (stat.size <= 0) return null;
    if (maxBytes > 0 && stat.size > maxBytes) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
