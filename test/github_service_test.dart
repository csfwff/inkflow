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
}
