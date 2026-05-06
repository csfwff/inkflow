import 'dart:convert';
import 'package:http/http.dart' as http;
import '../l10n/app_strings.dart';

class GitHubService {
  final String token;
  final String owner;
  final String repo;

  GitHubService({
    required this.token,
    required this.owner,
    required this.repo,
  });

  String get _baseUrl => 'https://api.github.com/repos/$owner/$repo/contents';

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      };

  /// 在 source/_posts/ 目录下创建文章
  /// [fileName] 文件名，如 "hello-world.md"
  /// [content] Markdown 内容
  /// [commitMessage] 提交信息，默认自动生成
  Future<GitHubResult> createPost({
    required String fileName,
    required String content,
    String? commitMessage,
  }) async {
    final path = 'source/_posts/$fileName';
    final message = commitMessage ?? 'post: add $fileName';
    final encodedContent = base64Encode(utf8.encode(content));

    final body = jsonEncode({
      'message': message,
      'content': encodedContent,
    });

    final url = Uri.parse('$_baseUrl/$path');

    try {
      final response = await http.put(url, headers: _headers, body: body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: true,
          message: AppStrings.current.publishSuccess,
          fileUrl: data['content']?['html_url'] ?? '',
        );
      } else {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: false,
          message: '${AppStrings.current.publishFailed}: ${data['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      return GitHubResult(
        success: false,
        message: '${AppStrings.current.networkError}: $e',
      );
    }
  }
}

class GitHubResult {
  final bool success;
  final String message;
  final String fileUrl;

  GitHubResult({
    required this.success,
    required this.message,
    this.fileUrl = '',
  });
}
