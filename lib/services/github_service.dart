import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_strings.dart';
import 'log_service.dart';

class GitHubService {
  final String token;
  final String owner;
  final String repo;
  final String branch;
  static final _log = LogService.instance;

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
    } catch (e, stack) {
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '创建 GitHub 文件失败: $remotePath',
      );
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
    } catch (e, stack) {
      debugPrint('[GitHub] EXCEPTION listing $path: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '列出 GitHub 目录失败: $path',
      );
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
          '[GitHub] file ERROR ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, stack) {
      debugPrint('[GitHub] EXCEPTION getting file $path: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '获取 GitHub 文件失败: $path',
      );
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
    } catch (e, stack) {
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '更新 GitHub 文件失败: $remotePath',
      );
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

    final body = jsonEncode({'message': message, 'sha': sha, 'branch': branch});

    final url = Uri.parse('$_baseUrl/$remotePath');

    try {
      final response = await http.delete(url, headers: _headers, body: body);

      if (response.statusCode == 200) {
        return GitHubResult(success: true, message: 'Deleted');
      } else {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: false,
          message: data['message'] ?? 'Delete failed: ${response.statusCode}',
        );
      }
    } catch (e, stack) {
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '删除 GitHub 文件失败: $remotePath',
      );
      return GitHubResult(
        success: false,
        message: '${AppStrings.current.networkError}: $e',
      );
    }
  }

  /// 获取单个 commit 的详细信息（含 files 列表）
  Future<GitHubCommit?> getCommitDetail(String sha) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/commits/$sha',
    );

    debugPrint('[GitHub] GET commit detail $sha');

    try {
      final response = await http.get(uri, headers: _headers);
      debugPrint('[GitHub] commit detail ${response.statusCode} $sha');

      if (response.statusCode == 200) {
        return _parseCommit(jsonDecode(response.body));
      }
      debugPrint('[GitHub] commit detail ERROR: ${response.statusCode}');
    } catch (e, stack) {
      debugPrint('[GitHub] commit detail EXCEPTION: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '获取 GitHub commit 详情失败: $sha',
      );
    }
    return null;
  }

  /// 获取指定路径下某个时间之后的 commit 记录（带分页）
  /// 列表 API 不返回 files，需逐个获取 commit 详情。
  /// commit 数量超过 [maxDetailFetches] 时跳过详情获取，返回的 commit 不含 files。
  Future<List<GitHubCommit>> getCommitsSince({
    required String path,
    required DateTime since,
    int perPage = 100,
    int maxDetailFetches = 20,
  }) async {
    final List<GitHubCommit> allCommits = [];
    int page = 1;

    while (true) {
      final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/commits')
          .replace(
            queryParameters: {
              'sha': branch,
              'path': path,
              'since': since.toUtc().toIso8601String(),
              'per_page': perPage.toString(),
              'page': page.toString(),
            },
          );

      debugPrint('[GitHub] GET commits $path since=$since page=$page');

      try {
        final response = await http.get(uri, headers: _headers);
        debugPrint('[GitHub] commits ${response.statusCode} $path');

        if (response.statusCode != 200) {
          debugPrint('[GitHub] commits ERROR: ${response.statusCode}');
          break;
        }

        final data = jsonDecode(response.body);
        if (data is! List || data.isEmpty) break;

        for (final commitJson in data) {
          final commit = _parseCommit(commitJson);
          if (commit != null) {
            allCommits.add(commit);
          }
        }

        // 如果返回的数据少于 per_page，说明没有更多了
        if (data.length < perPage) break;
        page++;
      } catch (e, stack) {
        debugPrint('[GitHub] commits EXCEPTION: $e');
        await _log.logException(
          e,
          stack,
          tag: 'GitHub',
          context: '获取 GitHub commit 列表失败: $path page=$page',
        );
        break;
      }
    }

    // commit 太多时跳过详情获取，让调用方降级到全量同步
    if (allCommits.length > maxDetailFetches) {
      debugPrint(
        '[GitHub] Too many commits (${allCommits.length} > $maxDetailFetches), skipping detail fetch',
      );
      return allCommits;
    }

    // 列表 API 不含 files，逐个获取详情以拿到变更文件列表
    final List<GitHubCommit> detailedCommits = [];
    for (final commit in allCommits) {
      final detail = await getCommitDetail(commit.sha);
      if (detail != null) {
        detailedCommits.add(detail);
      } else {
        // 详情获取失败，保留无 files 的原始 commit
        detailedCommits.add(commit);
      }
    }

    debugPrint('[GitHub] Total commits for $path: ${detailedCommits.length}');
    return detailedCommits;
  }

  /// 列出用户的仓库列表
  Future<List<GitHubRepo>> listRepositories({
    int perPage = 100,
    int page = 1,
  }) async {
    final uri = Uri.parse('https://api.github.com/user/repos').replace(
      queryParameters: {
        'per_page': perPage.toString(),
        'page': page.toString(),
        'sort': 'updated',
        'direction': 'desc',
      },
    );

    debugPrint('[GitHub] GET repos page=$page');

    try {
      final response = await http.get(uri, headers: _headers);
      debugPrint('[GitHub] repos ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => GitHubRepo.fromJson(e)).toList();
        }
      }
      debugPrint('[GitHub] repos ERROR: ${response.statusCode}');
    } catch (e, stack) {
      debugPrint('[GitHub] repos EXCEPTION: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '列出 GitHub 仓库失败',
      );
    }
    return [];
  }

  /// 列出仓库的分支列表
  Future<List<String>> listBranches({int perPage = 100, int page = 1}) async {
    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/branches')
        .replace(
          queryParameters: {
            'per_page': perPage.toString(),
            'page': page.toString(),
          },
        );

    debugPrint('[GitHub] GET branches page=$page');

    try {
      final response = await http.get(uri, headers: _headers);
      debugPrint('[GitHub] branches ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((e) => e['name'] as String).toList();
        }
      }
      debugPrint('[GitHub] branches ERROR: ${response.statusCode}');
    } catch (e, stack) {
      debugPrint('[GitHub] branches EXCEPTION: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '列出 GitHub 分支失败: $owner/$repo',
      );
    }
    return [];
  }

  GitHubCommit? _parseCommit(Map<String, dynamic> json) {
    try {
      final sha = json['sha'] ?? '';
      final commitInfo = json['commit'];
      final dateStr = commitInfo?['committer']?['date'];
      if (dateStr == null) return null;

      final date = DateTime.parse(dateStr);
      final files = <GitHubCommitFile>[];

      if (json['files'] != null) {
        for (final fileJson in json['files']) {
          files.add(GitHubCommitFile.fromJson(fileJson));
        }
      }

      return GitHubCommit(sha: sha, date: date, files: files);
    } catch (e) {
      debugPrint('[GitHub] parseCommit error: $e');
      return null;
    }
  }
}

/// GitHub 仓库信息
class GitHubRepo {
  final String name;
  final String fullName;
  final String defaultBranch;
  final String? description;
  final bool private;

  GitHubRepo({
    required this.name,
    required this.fullName,
    required this.defaultBranch,
    this.description,
    this.private = false,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['name'] ?? '',
      fullName: json['full_name'] ?? '',
      defaultBranch: json['default_branch'] ?? 'main',
      description: json['description'],
      private: json['private'] ?? false,
    );
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

  GitHubDirectoryResult.success(this.entries) : success = true, error = null;

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

/// commit 中的文件变更信息
class GitHubCommitFile {
  final String filename;
  final String status; // added, modified, removed, renamed

  GitHubCommitFile({required this.filename, required this.status});

  factory GitHubCommitFile.fromJson(Map<String, dynamic> json) {
    return GitHubCommitFile(
      filename: json['filename'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

/// commit 记录
class GitHubCommit {
  final String sha;
  final DateTime date;
  final List<GitHubCommitFile> files;

  GitHubCommit({required this.sha, required this.date, required this.files});
}

/// 增量同步结果
class IncrementalSyncResult {
  final bool success;
  final List<String> addedOrModified;
  final List<String> removed;
  final DateTime? latestCommitDate;
  final String? error;

  IncrementalSyncResult({
    required this.success,
    this.addedOrModified = const [],
    this.removed = const [],
    this.latestCommitDate,
    this.error,
  });
}
