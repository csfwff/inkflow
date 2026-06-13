import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_strings.dart';

class GitHubService {
  final String token;
  final String owner;
  final String repo;
  final String branch;

  GitHubService({
    required this.token,
    required this.owner,
    required this.repo,
    this.branch = 'main',
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
    bool drafts = false,
  }) async {
    final dir = drafts ? 'source/_drafts' : 'source/_posts';
    final path = '$dir/$fileName';
    final message = commitMessage ?? 'post: add $fileName';
    return createFile(
      remotePath: path,
      content: content,
      commitMessage: message,
    );
  }

  Future<GitHubResult> createFile({
    required String remotePath,
    required String content,
    String? commitMessage,
  }) async {
    final message = commitMessage ?? 'post: add $remotePath';
    final encodedContent = base64Encode(utf8.encode(content));

    final body = jsonEncode({
      'message': message,
      'content': encodedContent,
      'branch': branch,
    });

    final url = Uri.parse('$_baseUrl/$remotePath');

    try {
      final response = await http.put(url, headers: _headers, body: body);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: true,
          message: AppStrings.current.publishSuccess,
          fileUrl: data['content']?['html_url'] ?? '',
          sha: data['content']?['sha'] ?? '',
        );
      } else {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: ${data['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      return GitHubResult(
        success: false,
        message: '${AppStrings.current.networkError}: $e',
      );
    }
  }

  Future<GitHubDirectoryResult> listDirectoryContents(String path) async {
    final url = Uri.parse('$_baseUrl/$path');
    debugPrint('[GitHub] GET $url');
    try {
      final response = await http.get(url, headers: _headers);
      debugPrint('[GitHub] ${response.statusCode} $path');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          final error = 'Expected a directory at $path';
          debugPrint('[GitHub] ERROR: $error');
          return GitHubDirectoryResult.failure(error);
        }
        debugPrint('[GitHub] $path -> ${data.length} entries');
        return GitHubDirectoryResult.success(
          data.map((e) => GitHubFileEntry.fromJson(e)).toList(),
        );
      }

      final error =
          '${response.statusCode}: ${_extractGitHubMessage(response.body)}';
      debugPrint('[GitHub] ERROR $path: $error');
      return GitHubDirectoryResult.failure(error);
    } catch (e) {
      debugPrint('[GitHub] EXCEPTION listing $path: $e');
      return GitHubDirectoryResult.failure(e.toString());
    }
  }

  String _extractGitHubMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {
      // Fall back to the raw response body below.
    }
    return body.isEmpty ? 'Unknown error' : body;
  }

  Future<GitHubFileContent?> getFileContent(String path) async {
    final url = Uri.parse('$_baseUrl/$path');
    debugPrint('[GitHub] GET file $path');
    try {
      final response = await http.get(url, headers: _headers);
      debugPrint('[GitHub] file ${response.statusCode} $path');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['content'].replaceAll(RegExp(r'\s'), '');
        final content = utf8.decode(base64Decode(raw));
        return GitHubFileContent(content: content, sha: data['sha']);
      } else {
        debugPrint(
            '[GitHub] file ERROR ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[GitHub] EXCEPTION getting file $path: $e');
    }
    return null;
  }

  Future<GitHubResult> updatePost({
    required String filePath,
    required String content,
    required String sha,
    String? commitMessage,
    bool drafts = false,
  }) async {
    final dir = drafts ? 'source/_drafts' : 'source/_posts';
    final path = '$dir/$filePath';
    final message = commitMessage ?? 'post: update $filePath';
    return updateFile(
      remotePath: path,
      content: content,
      sha: sha,
      commitMessage: message,
    );
  }

  Future<GitHubResult> updateFile({
    required String remotePath,
    required String content,
    required String sha,
    String? commitMessage,
  }) async {
    final message = commitMessage ?? 'post: update $remotePath';
    final encodedContent = base64Encode(utf8.encode(content));

    final body = jsonEncode({
      'message': message,
      'content': encodedContent,
      'sha': sha,
      'branch': branch,
    });

    final url = Uri.parse('$_baseUrl/$remotePath');

    try {
      final response = await http.put(url, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: true,
          message: AppStrings.current.publishSuccess,
          fileUrl: data['content']?['html_url'] ?? '',
          sha: data['content']?['sha'] ?? '',
        );
      } else {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: ${data['message'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      return GitHubResult(
        success: false,
        message: '${AppStrings.current.networkError}: $e',
      );
    }
  }

  Future<GitHubResult> deletePost({
    required String filePath,
    required String sha,
    String? commitMessage,
    bool drafts = false,
  }) async {
    final dir = drafts ? 'source/_drafts' : 'source/_posts';
    final path = '$dir/$filePath';
    final message = commitMessage ?? 'post: delete $filePath';
    return deleteFile(remotePath: path, sha: sha, commitMessage: message);
  }

  Future<GitHubResult> deleteFile({
    required String remotePath,
    required String sha,
    String? commitMessage,
  }) async {
    final message = commitMessage ?? 'post: delete $remotePath';

    final body = jsonEncode({
      'message': message,
      'sha': sha,
      'branch': branch,
    });

    final url = Uri.parse('$_baseUrl/$remotePath');

    try {
      final response = await http.delete(url, headers: _headers, body: body);

      if (response.statusCode == 200) {
        return GitHubResult(
          success: true,
          message: 'Deleted',
        );
      } else {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: false,
          message: data['message'] ?? 'Delete failed: ${response.statusCode}',
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
  final String? sha;

  GitHubResult({
    required this.success,
    required this.message,
    this.fileUrl = '',
    this.sha,
  });
}

class GitHubDirectoryResult {
  final bool success;
  final List<GitHubFileEntry> entries;
  final String? error;

  GitHubDirectoryResult.success(this.entries)
      : success = true,
        error = null;

  GitHubDirectoryResult.failure(this.error)
      : success = false,
        entries = const [];
}

class GitHubFileEntry {
  final String name;
  final String type;
  final String path;
  final String? downloadUrl;
  final String? sha;

  GitHubFileEntry({
    required this.name,
    required this.type,
    required this.path,
    this.downloadUrl,
    this.sha,
  });

  factory GitHubFileEntry.fromJson(Map<String, dynamic> json) {
    return GitHubFileEntry(
      name: json['name'],
      type: json['type'],
      path: json['path'],
      downloadUrl: json['download_url'],
      sha: json['sha'],
    );
  }
}

class GitHubFileContent {
  final String content;
  final String sha;

  GitHubFileContent({required this.content, required this.sha});
}
