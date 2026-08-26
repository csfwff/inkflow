import 'dart:typed_data';

import 'package:pasteboard/pasteboard.dart';

class ClipboardImage {
  final Uint8List bytes;
  final String filename;

  const ClipboardImage({required this.bytes, required this.filename});

  static Future<ClipboardImage?> read() async {
    final bytes = await Pasteboard.image;
    if (bytes == null || bytes.isEmpty) return null;

    return ClipboardImage(
      bytes: bytes,
      filename:
          'clipboard-${DateTime.now().millisecondsSinceEpoch}.${_extensionFor(bytes)}',
    );
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
