import 'dart:typed_data';

/// 读取剪贴板里图片文件的字节内容（Web 实现）。
///
/// 浏览器剪贴板不提供本地文件路径，因此始终返回 null；网页端仍然支持
/// 通过位图数据粘贴图片。
Future<Uint8List?> readClipboardFileBytes(
  String path, {
  int maxBytes = 0,
}) async {
  return null;
}
