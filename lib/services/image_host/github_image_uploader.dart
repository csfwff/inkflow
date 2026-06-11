import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'image_uploader.dart';

class GitHubImageUploader implements ImageUploader {
  final String token;
  final String owner;
  final String repo;
  final String branch;
  final String path;
  final String? domain;

  GitHubImageUploader({
    required this.token,
    required this.owner,
    required this.repo,
    this.branch = 'main',
    this.path = 'images',
    this.domain,
  });

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      };

  String get _baseUrl => 'https://api.github.com/repos/$owner/$repo/contents';

  String _buildPath(String filename) {
    final now = DateTime.now();
    final datePath = '${now.year}/${now.month.toString().padLeft(2, '0')}';
    final timestamp = now.millisecondsSinceEpoch;
    final name = '${timestamp}_$filename';
    final cleanPath = path.endsWith('/') ? path : '$path/';
    return '$cleanPath$datePath/$name';
  }

  @override
  Future<UploadResult> upload(Uint8List bytes, String filename) async {
    final remotePath = _buildPath(filename);
    final encodedContent = base64Encode(bytes);

    final body = jsonEncode({
      'message': 'image: upload $filename',
      'content': encodedContent,
      'branch': branch,
    });

    final url = Uri.parse('$_baseUrl/$remotePath');

    try {
      final response = await http.put(url, headers: _headers, body: body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // 优先用自定义域名，否则用 GitHub raw URL
        String imageUrl;
        if (domain != null && domain!.isNotEmpty) {
          final cleanDomain = domain!.endsWith('/') ? domain!.substring(0, domain!.length - 1) : domain!;
          final cleanRemote = remotePath.startsWith('/') ? remotePath : '/$remotePath';
          imageUrl = '$cleanDomain$cleanRemote';
        } else {
          imageUrl = data['content']?['download_url'] ?? '';
        }
        return UploadResult(success: true, url: imageUrl);
      } else {
        final data = jsonDecode(response.body);
        return UploadResult(
          success: false,
          error: data['message'] ?? 'Upload failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UploadResult(success: false, error: 'Network error: $e');
    }
  }
}
