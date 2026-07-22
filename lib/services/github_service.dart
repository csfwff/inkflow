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
  final http.Client? client;
  static final _log = LogService.instance;

  GitHubService({
    required this.token,
    required this.owner,
    required this.repo,
    this.branch = 'main',
    this.client,
  });

  String get _repositoryUrl => 'https://api.github.com/repos/$owner/$repo';

  String get _baseUrl => 'https://api.github.com/repos/$owner/$repo/contents';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github.v3+json',
    'Content-Type': 'application/json',
  };

  /// GitHub Contents API 默认读取仓库默认分支，必须显式传入 ref。
  Uri _contentReadUri(String path, {String? ref}) => Uri.parse(
    '$_baseUrl/$path',
  ).replace(queryParameters: {'ref': ref ?? branch});

  Future<http.Response> _get(Uri uri) {
    final configuredClient = client;
    if (configuredClient != null) {
      return configuredClient.get(uri, headers: _headers);
    }
    return http.get(uri, headers: _headers);
  }

  Future<http.Response> _put(Uri uri, {Object? body}) {
    final configuredClient = client;
    if (configuredClient != null) {
      return configuredClient.put(uri, headers: _headers, body: body);
    }
    return http.put(uri, headers: _headers, body: body);
  }

  Future<http.Response> _post(Uri uri, {Object? body}) {
    final configuredClient = client;
    if (configuredClient != null) {
      return configuredClient.post(uri, headers: _headers, body: body);
    }
    return http.post(uri, headers: _headers, body: body);
  }

  Future<http.Response> _patch(Uri uri, {Object? body}) {
    final configuredClient = client;
    if (configuredClient != null) {
      return configuredClient.patch(uri, headers: _headers, body: body);
    }
    return http.patch(uri, headers: _headers, body: body);
  }

  Future<http.Response> _delete(Uri uri, {Object? body}) {
    final configuredClient = client;
    if (configuredClient != null) {
      return configuredClient.delete(uri, headers: _headers, body: body);
    }
    return http.delete(uri, headers: _headers, body: body);
  }

  Future<Uri?> getPagesBaseUrl() async {
    final uri = Uri.parse('$_repositoryUrl/pages');
    debugPrint('[GitHub] GET pages $owner/$repo');

    try {
      final response = await _get(uri);
      debugPrint('[GitHub] pages ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          final htmlUrl = data['html_url']?.toString();
          if (htmlUrl != null && htmlUrl.isNotEmpty) {
            return _parseBaseUri(htmlUrl);
          }

          final cname = data['cname']?.toString();
          if (cname != null && cname.isNotEmpty) {
            return _parseBaseUri('https://$cname');
          }
        }
      } else if (response.statusCode != 404) {
        debugPrint('[GitHub] pages ERROR: ${response.statusCode}');
      }
    } catch (e, stack) {
      debugPrint('[GitHub] pages EXCEPTION: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '获取 GitHub Pages 设置失败: $owner/$repo',
      );
    }
    return null;
  }

  Uri? _parseBaseUri(String value) {
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return null;
    }
    if (parsed.path.endsWith('/')) return parsed;
    return parsed.replace(path: '${parsed.path}/');
  }

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
      final response = await _put(url, body: body);

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
          statusCode: response.statusCode,
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
    final url = _contentReadUri(path);
    debugPrint('[GitHub] GET $url');
    try {
      final response = await _get(url);
      debugPrint('[GitHub] ${response.statusCode} $path');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! List) {
          final error = 'Expected a directory at $path';
          debugPrint('[GitHub] ERROR: $error');
          return GitHubDirectoryResult.failure(error, statusCode: 200);
        }
        debugPrint('[GitHub] $path -> ${data.length} entries');
        return GitHubDirectoryResult.success(
          data.map((e) => GitHubFileEntry.fromJson(e)).toList(),
        );
      }

      final error =
          '${response.statusCode}: ${_extractGitHubMessage(response.body)}';
      debugPrint('[GitHub] ERROR $path: $error');
      if (response.statusCode == 404) {
        return GitHubDirectoryResult.notFound(error);
      }
      return GitHubDirectoryResult.failure(
        error,
        statusCode: response.statusCode,
      );
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

  Future<GitHubFileContent?> getFileContent(String path, {String? ref}) async {
    final result = await getFileContentResult(path, ref: ref);
    return result.content;
  }

  /// Reads a file while preserving the distinction between a missing file and
  /// a request failure. Sync and move operations must not treat both cases as
  /// the same condition.
  Future<GitHubFileResult> getFileContentResult(
    String path, {
    String? ref,
  }) async {
    final url = _contentReadUri(path, ref: ref);
    debugPrint('[GitHub] GET file $url');
    try {
      final response = await _get(url);
      debugPrint('[GitHub] file ${response.statusCode} $path');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map || data['content'] == null || data['sha'] == null) {
          return GitHubFileResult.failure(
            'Unexpected file response for $path',
            statusCode: 200,
          );
        }
        final raw = data['content'].toString().replaceAll(RegExp(r'\s'), '');
        final content = utf8.decode(base64Decode(raw));
        return GitHubFileResult.success(
          GitHubFileContent(content: content, sha: data['sha'].toString()),
        );
      }

      final error =
          '${response.statusCode}: ${_extractGitHubMessage(response.body)}';
      debugPrint('[GitHub] file ERROR $path: $error');
      if (response.statusCode == 404) {
        return GitHubFileResult.notFound(error);
      }
      return GitHubFileResult.failure(error, statusCode: response.statusCode);
    } catch (e, stack) {
      debugPrint('[GitHub] EXCEPTION getting file $path: $e');
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '获取 GitHub 文件失败: $path',
      );
      return GitHubFileResult.failure(e.toString());
    }
  }

  /// Reads a Git blob by SHA. Pending local edits keep their original blob SHA,
  /// which lets the conflict UI reconstruct the common base after an app
  /// restart without storing another copy in the article database.
  Future<GitHubFileResult> getBlobContent(String sha) async {
    final url = Uri.parse('$_repositoryUrl/git/blobs/$sha');
    debugPrint('[GitHub] GET blob $sha');
    try {
      final response = await _get(url);
      debugPrint('[GitHub] blob ${response.statusCode} $sha');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map || data['content'] == null) {
          return GitHubFileResult.failure(
            'Unexpected blob response for $sha',
            statusCode: 200,
          );
        }
        final raw = data['content'].toString().replaceAll(RegExp(r'\s'), '');
        return GitHubFileResult.success(
          GitHubFileContent(content: utf8.decode(base64Decode(raw)), sha: sha),
        );
      }

      final error =
          '${response.statusCode}: ${_extractGitHubMessage(response.body)}';
      if (response.statusCode == 404) {
        return GitHubFileResult.notFound(error);
      }
      return GitHubFileResult.failure(error, statusCode: response.statusCode);
    } catch (e, stack) {
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '获取 GitHub blob 失败: $sha',
      );
      return GitHubFileResult.failure(e.toString());
    }
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
      final response = await _put(url, body: body);

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
          statusCode: response.statusCode,
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
      final response = await _delete(url, body: body);

      if (response.statusCode == 200) {
        return GitHubResult(success: true, message: 'Deleted');
      } else {
        final data = jsonDecode(response.body);
        return GitHubResult(
          success: false,
          message: data['message'] ?? 'Delete failed: ${response.statusCode}',
          statusCode: response.statusCode,
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

  /// Moves a file between two remote paths in one Git commit.
  ///
  /// The Contents API performs creation and deletion as independent commits.
  /// That can leave both files behind when the second request fails. This
  /// method builds a new Git tree from one branch head and updates the ref only
  /// after both changes are present, so a failed ref update leaves the branch
  /// untouched.
  Future<GitHubResult> moveFileAtomically({
    required String sourcePath,
    required String sourceSha,
    required String targetPath,
    required String content,
    String? commitMessage,
  }) async {
    if (sourcePath == targetPath) {
      return GitHubResult(
        success: false,
        message:
            '${AppStrings.current.publishFailed}: source and target paths are identical',
      );
    }

    final message = commitMessage ?? 'post: move $sourcePath to $targetPath';

    try {
      final encodedBranch = Uri.encodeComponent(branch);
      final refUri = Uri.parse('$_repositoryUrl/git/ref/heads/$encodedBranch');
      final refResponse = await _get(refUri);
      if (refResponse.statusCode != 200) {
        return _gitApiFailure('读取分支引用失败', refResponse);
      }

      final refData = jsonDecode(refResponse.body);
      final refObject = refData is Map ? refData['object'] : null;
      final headSha = refObject is Map ? refObject['sha']?.toString() : null;
      if (headSha == null || headSha.isEmpty) {
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: invalid branch reference',
        );
      }

      // Both checks are pinned to the same commit. A later concurrent update
      // makes the final ref update fail instead of silently overwriting data.
      final target = await getFileContentResult(targetPath, ref: headSha);
      if (target.success) {
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: target file already exists',
        );
      }
      if (!target.notFound) {
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: cannot verify target path (${target.error ?? 'unknown error'})',
        );
      }

      final source = await getFileContentResult(sourcePath, ref: headSha);
      if (!source.success || source.content == null) {
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: source file is unavailable (${source.error ?? 'unknown error'})',
        );
      }
      if (source.content!.sha != sourceSha) {
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: remote file changed; sync before publishing',
        );
      }

      final commitResponse = await _get(
        Uri.parse('$_repositoryUrl/git/commits/$headSha'),
      );
      if (commitResponse.statusCode != 200) {
        return _gitApiFailure('读取提交树失败', commitResponse);
      }
      final commitData = jsonDecode(commitResponse.body);
      final commitTree = commitData is Map ? commitData['tree'] : null;
      final baseTreeSha = commitTree is Map
          ? commitTree['sha']?.toString()
          : null;
      if (baseTreeSha == null || baseTreeSha.isEmpty) {
        return GitHubResult(
          success: false,
          message: '${AppStrings.current.publishFailed}: invalid commit tree',
        );
      }

      final createTreeResponse = await _post(
        Uri.parse('$_repositoryUrl/git/trees'),
        body: jsonEncode({
          'base_tree': baseTreeSha,
          'tree': [
            {
              'path': targetPath,
              'mode': '100644',
              'type': 'blob',
              'content': content,
            },
            {'path': sourcePath, 'mode': '100644', 'type': 'blob', 'sha': null},
          ],
        }),
      );
      if (createTreeResponse.statusCode != 201) {
        return _gitApiFailure('创建移动树失败', createTreeResponse);
      }

      final treeData = jsonDecode(createTreeResponse.body);
      final newTreeSha = treeData is Map ? treeData['sha']?.toString() : null;
      final targetSha = _treeEntrySha(treeData, targetPath);
      if (newTreeSha == null || newTreeSha.isEmpty || targetSha == null) {
        return GitHubResult(
          success: false,
          message: '${AppStrings.current.publishFailed}: invalid tree response',
        );
      }

      final createCommitResponse = await _post(
        Uri.parse('$_repositoryUrl/git/commits'),
        body: jsonEncode({
          'message': message,
          'tree': newTreeSha,
          'parents': [headSha],
        }),
      );
      if (createCommitResponse.statusCode != 201) {
        return _gitApiFailure('创建移动提交失败', createCommitResponse);
      }

      final newCommitData = jsonDecode(createCommitResponse.body);
      final newCommitSha = newCommitData is Map
          ? newCommitData['sha']?.toString()
          : null;
      if (newCommitSha == null || newCommitSha.isEmpty) {
        return GitHubResult(
          success: false,
          message:
              '${AppStrings.current.publishFailed}: invalid commit response',
        );
      }

      final updateRefResponse = await _patch(
        refUri,
        body: jsonEncode({'sha': newCommitSha, 'force': false}),
      );
      if (updateRefResponse.statusCode != 200) {
        return _gitApiFailure('更新分支引用失败', updateRefResponse);
      }

      return GitHubResult(
        success: true,
        message: AppStrings.current.publishSuccess,
        sha: targetSha,
      );
    } catch (e, stack) {
      await _log.logException(
        e,
        stack,
        tag: 'GitHub',
        context: '原子移动 GitHub 文件失败: $sourcePath -> $targetPath',
      );
      return GitHubResult(
        success: false,
        message: '${AppStrings.current.networkError}: $e',
      );
    }
  }

  GitHubResult _gitApiFailure(String action, http.Response response) {
    return GitHubResult(
      success: false,
      message:
          '${AppStrings.current.publishFailed}: $action (${response.statusCode}: ${_extractGitHubMessage(response.body)})',
      statusCode: response.statusCode,
    );
  }

  String? _treeEntrySha(Object? treeData, String path) {
    if (treeData is! Map || treeData['tree'] is! List) return null;
    for (final entry in treeData['tree'] as List) {
      if (entry is Map && entry['path'] == path) {
        final sha = entry['sha']?.toString();
        if (sha != null && sha.isNotEmpty) return sha;
      }
    }
    return null;
  }

  /// 获取单个 commit 的详细信息（含 files 列表）
  Future<GitHubCommit?> getCommitDetail(String sha) async {
    final uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/commits/$sha',
    );

    debugPrint('[GitHub] GET commit detail $sha');

    try {
      final response = await _get(uri);
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
  Future<GitHubCommitsResult> getCommitsSince({
    required String path,
    required DateTime since,
    int perPage = 100,
    int maxDetailFetches = 20,
  }) async {
    final List<GitHubCommit> allCommits = [];
    int page = 1;

    while (true) {
      final uri = Uri.parse('$_repositoryUrl/commits').replace(
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
        final response = await _get(uri);
        debugPrint('[GitHub] commits ${response.statusCode} $path');

        if (response.statusCode != 200) {
          final error =
              '${response.statusCode}: ${_extractGitHubMessage(response.body)}';
          debugPrint('[GitHub] commits ERROR: $error');
          return GitHubCommitsResult.failure(error);
        }

        final data = jsonDecode(response.body);
        if (data is! List) {
          return GitHubCommitsResult.failure(
            'Unexpected commits response for $path',
          );
        }
        if (data.isEmpty) break;

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
        return GitHubCommitsResult.failure(e.toString());
      }
    }

    // commit 太多时跳过详情获取，让调用方降级到全量同步
    if (allCommits.length > maxDetailFetches) {
      debugPrint(
        '[GitHub] Too many commits (${allCommits.length} > $maxDetailFetches), skipping detail fetch',
      );
      return GitHubCommitsResult.success(allCommits);
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
    return GitHubCommitsResult.success(detailedCommits);
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
      final response = await _get(uri);
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
      final response = await _get(uri);
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
  final int? statusCode;

  bool get isConflict => statusCode == 409 || statusCode == 422;

  GitHubResult({
    required this.success,
    required this.message,
    this.fileUrl = '',
    this.sha,
    this.statusCode,
  });
}

enum GitHubReadStatus { success, notFound, failure }

class GitHubDirectoryResult {
  final GitHubReadStatus status;
  final List<GitHubFileEntry> entries;
  final String? error;
  final int? statusCode;

  bool get success => status == GitHubReadStatus.success;
  bool get notFound => status == GitHubReadStatus.notFound;

  GitHubDirectoryResult.success(this.entries)
    : status = GitHubReadStatus.success,
      error = null,
      statusCode = 200;

  GitHubDirectoryResult.notFound(this.error)
    : status = GitHubReadStatus.notFound,
      entries = const [],
      statusCode = 404;

  GitHubDirectoryResult.failure(this.error, {this.statusCode})
    : status = GitHubReadStatus.failure,
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

class GitHubFileResult {
  final GitHubReadStatus status;
  final GitHubFileContent? content;
  final String? error;
  final int? statusCode;

  bool get success => status == GitHubReadStatus.success;
  bool get notFound => status == GitHubReadStatus.notFound;

  GitHubFileResult.success(this.content)
    : status = GitHubReadStatus.success,
      error = null,
      statusCode = 200;

  GitHubFileResult.notFound(this.error)
    : status = GitHubReadStatus.notFound,
      content = null,
      statusCode = 404;

  GitHubFileResult.failure(this.error, {this.statusCode})
    : status = GitHubReadStatus.failure,
      content = null;
}

/// commit 中的文件变更信息
class GitHubCommitFile {
  final String filename;
  final String status; // added, modified, removed, renamed
  final String? previousFilename;

  GitHubCommitFile({
    required this.filename,
    required this.status,
    this.previousFilename,
  });

  factory GitHubCommitFile.fromJson(Map<String, dynamic> json) {
    return GitHubCommitFile(
      filename: json['filename'] ?? '',
      status: json['status'] ?? '',
      previousFilename: json['previous_filename']?.toString(),
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

class GitHubCommitsResult {
  final bool success;
  final List<GitHubCommit> commits;
  final String? error;

  GitHubCommitsResult.success(this.commits) : success = true, error = null;

  GitHubCommitsResult.failure(this.error) : success = false, commits = const [];
}
