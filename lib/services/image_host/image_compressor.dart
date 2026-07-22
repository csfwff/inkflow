import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 图片压缩结果
class CompressResult {
  final Uint8List bytes;
  final int originalSize;
  final int compressedSize;
  final int? originalWidth;
  final int? originalHeight;
  final int? compressedWidth;
  final int? compressedHeight;

  CompressResult({
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
    this.originalWidth,
    this.originalHeight,
    this.compressedWidth,
    this.compressedHeight,
  });

  /// 压缩比例 (0-100)
  double get ratio =>
      originalSize > 0 ? (1 - compressedSize / originalSize) * 100 : 0;

  /// 格式化的原始大小
  String get originalSizeFormatted => _formatSize(originalSize);

  /// 格式化的压缩后大小
  String get compressedSizeFormatted => _formatSize(compressedSize);

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// 图片压缩工具类
class ImageCompressor {
  static const int _minQuality = 60;
  static const int _startQuality = 85;
  static const int _qualityStep = 5;

  /// 压缩图片到目标大小
  ///
  /// [bytes] 原始图片字节
  /// [targetKB] 目标大小 (KB)，0 表示不限制大小
  /// [maxWidth] 最大宽度，0 表示不限制
  /// [maxHeight] 最大高度，0 表示不限制
  static Future<CompressResult> compress(
    Uint8List bytes, {
    int targetKB = 1024,
    int maxWidth = 0,
    int maxHeight = 0,
  }) async {
    final originalSize = bytes.length;

    // 如果目标为 0 且没有尺寸限制，直接返回
    if (targetKB == 0 && maxWidth == 0 && maxHeight == 0) {
      return CompressResult(
        bytes: bytes,
        originalSize: originalSize,
        compressedSize: originalSize,
      );
    }

    // 如果已经小于目标大小且没有尺寸限制，直接返回
    final targetBytes = targetKB * 1024;
    if (targetKB > 0 &&
        originalSize <= targetBytes &&
        maxWidth == 0 &&
        maxHeight == 0) {
      return CompressResult(
        bytes: bytes,
        originalSize: originalSize,
        compressedSize: originalSize,
      );
    }

    // 解码图片
    final image = img.decodeImage(bytes);
    if (image == null) {
      // 无法解码，返回原图
      return CompressResult(
        bytes: bytes,
        originalSize: originalSize,
        compressedSize: originalSize,
      );
    }

    var currentImage = image;
    var currentWidth = image.width;
    var currentHeight = image.height;

    // 第一步：缩小尺寸
    if (maxWidth > 0 && currentWidth > maxWidth) {
      final ratio = maxWidth / currentWidth;
      currentWidth = maxWidth;
      currentHeight = (currentHeight * ratio).round();
      currentImage = img.copyResize(
        currentImage,
        width: currentWidth,
        height: currentHeight,
      );
    }
    if (maxHeight > 0 && currentHeight > maxHeight) {
      final ratio = maxHeight / currentHeight;
      currentHeight = maxHeight;
      currentWidth = (currentWidth * ratio).round();
      currentImage = img.copyResize(
        currentImage,
        width: currentWidth,
        height: currentHeight,
      );
    }

    // 如果目标为 0（不限大小），只做尺寸缩放
    if (targetKB == 0) {
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(currentImage, quality: _startQuality),
      );
      return CompressResult(
        bytes: compressedBytes,
        originalSize: originalSize,
        compressedSize: compressedBytes.length,
        originalWidth: image.width,
        originalHeight: image.height,
        compressedWidth: currentWidth,
        compressedHeight: currentHeight,
      );
    }

    // 第二步：逐步降低质量直到满足目标大小
    var quality = _startQuality;
    Uint8List? compressedBytes;

    while (quality >= _minQuality) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(currentImage, quality: quality),
      );
      if (encoded.length <= targetBytes) {
        compressedBytes = encoded;
        break;
      }
      // 如果当前质量已经是最小质量，使用这个结果
      if (quality == _minQuality) {
        compressedBytes = encoded;
        break;
      }
      quality -= _qualityStep;
    }

    // 如果还是太大，尝试进一步缩小尺寸
    if (compressedBytes != null && compressedBytes.length > targetBytes) {
      while (currentWidth > 100 && currentHeight > 100) {
        currentWidth = (currentWidth * 0.8).round();
        currentHeight = (currentHeight * 0.8).round();
        currentImage = img.copyResize(
          currentImage,
          width: currentWidth,
          height: currentHeight,
        );
        final encoded = Uint8List.fromList(
          img.encodeJpg(currentImage, quality: _minQuality),
        );
        if (encoded.length <= targetBytes) {
          compressedBytes = encoded;
          break;
        }
        compressedBytes = encoded;
      }
    }

    compressedBytes ??= bytes;

    return CompressResult(
      bytes: compressedBytes,
      originalSize: originalSize,
      compressedSize: compressedBytes.length,
      originalWidth: image.width,
      originalHeight: image.height,
      compressedWidth: currentWidth,
      compressedHeight: currentHeight,
    );
  }
}
