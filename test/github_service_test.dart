import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkflow/services/github_service.dart';

void main() {
  GitHubService createService(http.Client client) => GitHubService(
    token: 'token',
    owner: 'owner',
    repo: 'repo',
    branch: 'feature/friend-links',
    client: client,
  );

  test('目录读取请求携带配置分支 ref', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode([
          {
            'name': 'hello.md',
            'type': 'file',
            'path': 'source/_posts/hello.md',
            'download_url': null,
            'sha': 'directory-sha',
          },
        ]),
        200,
      );
    });

    final result = await createService(
      client,
    ).listDirectoryContents('source/_posts');

    expect(result.success, isTrue);
    expect(requestedUri?.path, '/repos/owner/repo/contents/source/_posts');
    expect(requestedUri?.queryParameters, {'ref': 'feature/friend-links'});
  });

  test('文件读取请求携带配置分支 ref', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'content': base64Encode(utf8.encode('article body')),
          'sha': 'file-sha',
        }),
        200,
      );
    });

    final file = await createService(
      client,
    ).getFileContent('source/_posts/hello.md');

    expect(file?.content, 'article body');
    expect(file?.sha, 'file-sha');
    expect(
      requestedUri?.path,
      '/repos/owner/repo/contents/source/_posts/hello.md',
    );
    expect(requestedUri?.queryParameters, {'ref': 'feature/friend-links'});
  });

  test('跨目录移动通过单个 Git 提交完成', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final path = request.url.path;

      if (request.method == 'GET' &&
          path == '/repos/owner/repo/git/ref/heads/main') {
        return http.Response(
          jsonEncode({
            'object': {'sha': 'head-sha'},
          }),
          200,
        );
      }
      if (request.method == 'GET' &&
          path == '/repos/owner/repo/contents/source/_posts/hello.md') {
        return http.Response(jsonEncode({'message': 'Not Found'}), 404);
      }
      if (request.method == 'GET' &&
          path == '/repos/owner/repo/contents/source/_drafts/hello.md') {
        return http.Response(
          jsonEncode({
            'content': base64Encode(utf8.encode('old content')),
            'sha': 'source-sha',
          }),
          200,
        );
      }
      if (request.method == 'GET' &&
          path == '/repos/owner/repo/git/commits/head-sha') {
        return http.Response(
          jsonEncode({
            'tree': {'sha': 'base-tree'},
          }),
          200,
        );
      }
      if (request.method == 'POST' && path == '/repos/owner/repo/git/trees') {
        return http.Response(
          jsonEncode({
            'sha': 'new-tree',
            'tree': [
              {'path': 'source/_posts/hello.md', 'sha': 'target-sha'},
            ],
          }),
          201,
        );
      }
      if (request.method == 'POST' && path == '/repos/owner/repo/git/commits') {
        return http.Response(jsonEncode({'sha': 'new-commit'}), 201);
      }
      if (request.method == 'PATCH' &&
          path == '/repos/owner/repo/git/ref/heads/main') {
        return http.Response('{}', 200);
      }
      return http.Response('unexpected request: ${request.method} $path', 500);
    });
    final service = GitHubService(
      token: 'token',
      owner: 'owner',
      repo: 'repo',
      branch: 'main',
      client: client,
    );

    final result = await service.moveFileAtomically(
      sourcePath: 'source/_drafts/hello.md',
      sourceSha: 'source-sha',
      targetPath: 'source/_posts/hello.md',
      content: 'new content',
      commitMessage: 'post: publish hello',
    );

    expect(result.success, isTrue);
    expect(result.sha, 'target-sha');
    expect(requests.map((request) => request.method).toList(), [
      'GET',
      'GET',
      'GET',
      'GET',
      'POST',
      'POST',
      'PATCH',
    ]);

    final createTreeRequest = requests[4];
    final treeBody = jsonDecode(createTreeRequest.body) as Map<String, dynamic>;
    expect(treeBody['base_tree'], 'base-tree');
    expect(treeBody['tree'], [
      {
        'path': 'source/_posts/hello.md',
        'mode': '100644',
        'type': 'blob',
        'content': 'new content',
      },
      {
        'path': 'source/_drafts/hello.md',
        'mode': '100644',
        'type': 'blob',
        'sha': null,
      },
    ]);
  });

  test('原子移动不会覆盖已存在的目标文件', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/repos/owner/repo/git/ref/heads/main') {
        return http.Response(
          jsonEncode({
            'object': {'sha': 'head-sha'},
          }),
          200,
        );
      }
      if (request.url.path ==
          '/repos/owner/repo/contents/source/_posts/hello.md') {
        return http.Response(
          jsonEncode({
            'content': base64Encode(utf8.encode('existing')),
            'sha': 'target-sha',
          }),
          200,
        );
      }
      return http.Response('unexpected request', 500);
    });
    final service = GitHubService(
      token: 'token',
      owner: 'owner',
      repo: 'repo',
      branch: 'main',
      client: client,
    );

    final result = await service.moveFileAtomically(
      sourcePath: 'source/_drafts/hello.md',
      sourceSha: 'source-sha',
      targetPath: 'source/_posts/hello.md',
      content: 'new content',
    );

    expect(result.success, isFalse);
    expect(result.message, contains('target file already exists'));
  });

  test('更新冲突保留 GitHub 状态码', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'message': 'Conflict'}), 409),
    );

    final result = await createService(client).updateFile(
      remotePath: 'source/_posts/hello.md',
      content: 'new content',
      sha: 'old-sha',
    );

    expect(result.success, isFalse);
    expect(result.statusCode, 409);
    expect(result.isConflict, isTrue);
  });

  test('按 blob SHA 读取冲突共同基线内容', () async {
    Uri? requestedUri;
    final client = MockClient((request) async {
      requestedUri = request.url;
      return http.Response(
        jsonEncode({
          'content': base64Encode(utf8.encode('base content')),
          'encoding': 'base64',
        }),
        200,
      );
    });

    final result = await createService(client).getBlobContent('base-sha');

    expect(result.success, isTrue);
    expect(result.content?.content, 'base content');
    expect(requestedUri?.path, '/repos/owner/repo/git/blobs/base-sha');
  });
}
