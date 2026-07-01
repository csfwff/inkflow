import 'dart:typed_data';
import '../../models/settings.dart';
import 'github_image_uploader.dart';
import 'image_compressor.dart';
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
          dateFolderMode: settings.imageDateFolderMode,
          namingMode: settings.imageNamingMode,
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
          dateFolderMode: settings.imageDateFolderMode,
          namingMode: settings.imageNamingMode,
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

  /// 上传图片，如果启用了压缩则先压缩
  ///
  /// 返回 [UploadWithCompressResult] 包含上传结果和压缩信息
  Future<UploadWithCompressResult> uploadWithCompress(Uint8List bytes, String filename) async {
    final uploader = getUploader();
    if (uploader == null) {
      return UploadWithCompressResult(
        uploadResult: UploadResult(success: false, error: 'Image host not configured'),
        compressResult: null,
      );
    }

    CompressResult? compressResult;

    // 如果启用了压缩，先压缩
    if (settings.imageCompressEnabled) {
      compressResult = await ImageCompressor.compress(
        bytes,
        targetKB: settings.imageCompressTargetKB,
      );
      bytes = compressResult.bytes;
    }

    final uploadResult = await uploader.upload(bytes, filename);
    return UploadWithCompressResult(
      uploadResult: uploadResult,
      compressResult: compressResult,
    );
  }
}

/// 带压缩信息的上传结果
class UploadWithCompressResult {
  final UploadResult uploadResult;
  final CompressResult? compressResult;

  UploadWithCompressResult({
    required this.uploadResult,
    this.compressResult,
  });

  bool get success => uploadResult.success;
  String? get url => uploadResult.url;
  String? get error => uploadResult.error;
  bool get wasCompressed => compressResult != null && compressResult!.compressedSize < compressResult!.originalSize;
}
