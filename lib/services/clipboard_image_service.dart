import 'dart:typed_data';

import 'package:pasteboard/pasteboard.dart';

import '_clipboard_file_native.dart'
    if (dart.library.js_interop) '_clipboard_file_web.dart';

/// 剪贴板里可以上传的图片。
class ClipboardImage {
  /// 图片字节内容。
  final Uint8List bytes;

  /// 上传时使用的文件名。
  final String filename;

  /// 是否来自剪贴板中的图片文件（而不是位图数据）。
  final bool fromFile;

  const ClipboardImage({
    required this.bytes,
    required this.filename,
    this.fromFile = false,
  });

  /// 单张图片文件大小上限，超过的会被跳过。
  static const int _maxFileBytes = 64 * 1024 * 1024;

  /// 剪贴板中支持读取的图片文件扩展名。
  static const Set<String> _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'bmp',
    'avif',
    'heic',
    'tif',
    'tiff',
  };

  /// 读取剪贴板中的图片，只取第一张。
  static Future<ClipboardImage?> read() async {
    final images = await readAll();
    return images.isEmpty ? null : images.first;
  }

  /// 读取剪贴板中的全部图片。
  ///
  /// 先尝试位图数据（截图、或在网页上「复制图片」）；剪贴板里没有位图时再
  /// 回退到图片文件，这样在文件管理器中复制的一张或多张图片文件也能直接
  /// 粘贴上传。
  static Future<List<ClipboardImage>> readAll() async {
    final bitmap = await _readBitmap();
    if (bitmap != null) return <ClipboardImage>[bitmap];

    return _readImageFiles();
  }

  static Future<ClipboardImage?> _readBitmap() async {
    Uint8List? bytes;
    try {
      bytes = await Pasteboard.image;
    } catch (_) {
      // 部分平台在没有位图时会抛错，交给文件回退处理。
      return null;
    }
    if (bytes == null || bytes.isEmpty) return null;

    return ClipboardImage(
      bytes: bytes,
      filename:
          'clipboard-${DateTime.now().millisecondsSinceEpoch}.${_extensionFor(bytes)}',
    );
  }

  static Future<List<ClipboardImage>> _readImageFiles() async {
    List<String> paths;
    try {
      paths = await Pasteboard.files();
    } catch (_) {
      return const <ClipboardImage>[];
    }
    if (paths.isEmpty) return const <ClipboardImage>[];

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final images = <ClipboardImage>[];
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final extension = _imageExtensionOf(path);
      if (extension == null) continue;

      final bytes = await readClipboardFileBytes(path, maxBytes: _maxFileBytes);
      if (bytes == null || bytes.isEmpty) continue;

      images.add(
        ClipboardImage(
          bytes: bytes,
          filename: _fileNameOf(
            path,
            fallback: 'clipboard-$stamp-$i.$extension',
          ),
          fromFile: true,
        ),
      );
    }
    return images;
  }

  /// 返回路径对应的图片扩展名，不受支持时返回 null。
  static String? _imageExtensionOf(String path) {
    final name = _fileNameOf(path, fallback: '');
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return null;

    final extension = name.substring(dot + 1).toLowerCase();
    return _imageExtensions.contains(extension) ? extension : null;
  }

  /// 取出路径中的文件名，同时兼容 Windows 与 POSIX 分隔符。
  static String _fileNameOf(String path, {required String fallback}) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.substring(normalized.lastIndexOf('/') + 1);
    return name.isEmpty ? fallback : name;
  }

  static String _extensionFor(Uint8List bytes) {
    if (_matches(bytes, const [0x89, 0x50, 0x4E, 0x47])) return 'png';
    if (_matches(bytes, const [0xFF, 0xD8, 0xFF])) return 'jpg';
    if (_matches(bytes, const [0x47, 0x49, 0x46, 0x38])) return 'gif';
    if (_matches(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    return 'png';
  }

  static bool _matches(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
