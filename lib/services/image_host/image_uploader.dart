import 'dart:typed_data';

class UploadResult {
  final bool success;
  final String? url;
  final String? error;

  UploadResult({required this.success, this.url, this.error});
}

abstract class ImageUploader {
  Future<UploadResult> upload(Uint8List bytes, String filename);
}
