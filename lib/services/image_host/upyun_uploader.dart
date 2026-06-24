import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/settings.dart';
import 'image_path_builder.dart';
import 'image_uploader.dart';

class UpyunUploader implements ImageUploader {
  final String bucket;
  final String operator;
  final String password;
  final String domain;
  final String path;
  final ImageDateFolderMode dateFolderMode;
  final ImageNamingMode namingMode;

  UpyunUploader({
    required this.bucket,
    required this.operator,
    required this.password,
    required this.domain,
    this.path = 'images/',
    this.dateFolderMode = ImageDateFolderMode.none,
    this.namingMode = ImageNamingMode.timestamp,
  });

  String get _auth {
    final credentials = '$operator:$password';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  String get _baseUrl => 'https://v0.api.upyun.com/$bucket';

  @override
  Future<UploadResult> upload(Uint8List bytes, String filename) async {
    final remotePath = buildRemoteImagePath(
      path,
      filename,
      dateFolderMode: dateFolderMode,
      namingMode: namingMode,
    );
    final url = '$_baseUrl/$remotePath';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': _auth,
          'Content-Length': bytes.length.toString(),
        },
        body: bytes,
      );

      if (response.statusCode == 200) {
        final cleanDomain = domain.endsWith('/') ? domain.substring(0, domain.length - 1) : domain;
        final cleanRemote = remotePath.startsWith('/') ? remotePath : '/$remotePath';
        final imageUrl = '$cleanDomain$cleanRemote';
        return UploadResult(success: true, url: imageUrl);
      } else {
        final data = jsonDecode(response.body);
        return UploadResult(
          success: false,
          error: data['msg'] ?? 'Upload failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UploadResult(success: false, error: 'Network error: $e');
    }
  }
}
