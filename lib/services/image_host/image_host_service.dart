import 'dart:typed_data';
import '../../models/settings.dart';
import 'github_image_uploader.dart';
import 'image_uploader.dart';
import 'upyun_uploader.dart';

class ImageHostService {
  final Settings settings;

  ImageHostService({required this.settings});

  ImageUploader? getUploader() {
    switch (settings.imageHostType) {
      case ImageHostType.github:
        if (settings.imageGithubRepo.isEmpty) return null;
        return GitHubImageUploader(
          token: settings.githubToken,
          owner: settings.githubOwner,
          repo: settings.imageGithubRepo,
          branch: settings.githubBranch,
          path: settings.imageGithubPath,
          domain: settings.imageGithubDomain.isNotEmpty ? settings.imageGithubDomain : null,
        );
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
