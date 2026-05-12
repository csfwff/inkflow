import 'dart:typed_data';
import '../../models/settings.dart';
import 'image_uploader.dart';
import 'upyun_uploader.dart';

class ImageHostService {
  final Settings settings;

  ImageHostService({required this.settings});

  ImageUploader? getUploader() {
    switch (settings.imageHostType) {
      case ImageHostType.upyun:
        if (settings.upyunBucket.isEmpty ||
            settings.upyunOperator.isEmpty ||
            settings.upyunPassword.isEmpty ||
            settings.upyunDomain.isEmpty) {
          return null;
        }
        return UpyunUploader(
          bucket: settings.upyunBucket,
          operator: settings.upyunOperator,
          password: settings.upyunPassword,
          domain: settings.upyunDomain,
          path: settings.upyunPath,
        );
      default:
        return null;
    }
  }

  bool get isConfigured => getUploader() != null;

  Future<UploadResult> upload(Uint8List bytes, String filename) async {
    final uploader = getUploader();
    if (uploader == null) {
      return UploadResult(success: false, error: 'Image host not configured');
    }
    return uploader.upload(bytes, filename);
  }
}
