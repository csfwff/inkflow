import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkflow/models/article.dart';
import 'package:inkflow/models/settings.dart';
import 'package:inkflow/services/github_service.dart';
import 'package:inkflow/services/sync_contracts.dart';
import 'package:inkflow/services/sync_service.dart';

void main() {
  group('SyncService safety', () {
    test('根目录不存在时跳过远端删除对账', () async {
      final store = _FakeArticleStore([
        _article(
          id: 1,
          status: ArticleStatus.synced,
          remotePath: 'source/_posts/keep.md',
        ),
      ]);
      final settings = _FakeSettingsStore(Settings());
      final sync = _syncService(
        MockClient(
          (_) async => http.Response(jsonEncode({'message': 'Not Found'}), 404),
        ),
        store,
        settings,
      );

      final result = await sync.syncFromGitHub();

      expect(result.success, isTrue);
      expect(result.deletionReconciliationSkipped, isTrue);
      expect(store.markedRemoteDeleted, isEmpty);
      expect(settings.saveCount, 1);
    });

    test('目录请求失败时不改变本地文章状态', () async {
      final store = _FakeArticleStore([
        _article(
          id: 1,
          status: ArticleStatus.synced,
          remotePath: 'source/_posts/keep.md',
        ),
      ]);
      final settings = _FakeSettingsStore(Settings());
      final sync = _syncService(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Bad credentials'}), 401),
        ),
        store,
        settings,
      );

      final result = await sync.syncFromGitHub();

      expect(result.success, isFalse);
      expect(store.markedRemoteDeleted, isEmpty);
      expect(settings.saveCount, 0);
    });

    test('增量 commit 请求失败不会被当作没有更新', () async {
      final store = _FakeArticleStore([
        _article(
          id: 1,
          status: ArticleStatus.synced,
          remotePath: 'source/_posts/keep.md',
        ),
      ]);
      final settings = _FakeSettingsStore(
        Settings(lastSyncTime: DateTime.utc(2026, 1, 1)),
      );
      final sync = _syncService(
        MockClient((request) async {
          if (request.url.path == '/repos/owner/repo/commits') {
            return http.Response(jsonEncode({'message': 'Server Error'}), 500);
          }
          return http.Response(jsonEncode({'message': 'Server Error'}), 500);
        }),
        store,
        settings,
      );

      final result = await sync.syncIncremental();

      expect(result.success, isFalse);
      expect(store.markedRemoteDeleted, isEmpty);
      expect(settings.saveCount, 0);
    });

    test('增量删除只标记对应远端目录的同名文章', () async {
      final post = _article(
        id: 1,
        status: ArticleStatus.synced,
        remotePath: 'source/_posts/same-name.md',
      );
      final draft = _article(
        id: 2,
        status: ArticleStatus.repoDraft,
        remotePath: 'source/_drafts/same-name.md',
      );
      final store = _FakeArticleStore([post, draft]);
      final settings = _FakeSettingsStore(
        Settings(lastSyncTime: DateTime.utc(2026, 1, 1)),
      );
      final sync = _syncService(
        MockClient((request) async {
          if (request.url.path == '/repos/owner/repo/commits') {
            if (request.url.queryParameters['path'] == 'source/_posts') {
              return http.Response(_commitList('post-commit'), 200);
            }
            if (request.url.queryParameters['path'] == 'source/_drafts') {
              return http.Response('[]', 200);
            }
          }
          if (request.url.path == '/repos/owner/repo/commits/post-commit') {
            return http.Response(
              jsonEncode({
                'sha': 'post-commit',
                'commit': {
                  'committer': {'date': '2026-01-02T00:00:00Z'},
                },
                'files': [
                  {
                    'filename': 'source/_posts/same-name.md',
                    'status': 'removed',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('unexpected request: ${request.url}', 500);
        }),
        store,
        settings,
      );

      final result = await sync.syncIncremental();

      expect(result.success, isTrue);
      expect(store.markedRemoteDeleted, [1]);
      expect(post.status, ArticleStatus.remoteDeleted);
      expect(draft.status, ArticleStatus.repoDraft);
    });
  });
}

SyncService _syncService(
  http.Client client,
  SyncArticleStore articleStore,
  SyncSettingsStore settingsStore,
) {
  return SyncService(
    github: GitHubService(
      token: 'token',
      owner: 'owner',
      repo: 'repo',
      client: client,
    ),
    articleService: articleStore,
    settingsService: settingsStore,
  );
}

String _commitList(String sha) => jsonEncode([
  {
    'sha': sha,
    'commit': {
      'committer': {'date': '2026-01-02T00:00:00Z'},
    },
  },
]);

Article _article({
  required int id,
  required ArticleStatus status,
  required String remotePath,
}) {
  return Article(
    id: id,
    title: 'Article $id',
    content: '',
    date: DateTime(2026),
    slug: 'article-$id',
    status: status,
    filePath: remotePath.split('/').last,
    remotePath: remotePath,
    remoteKind: status == ArticleStatus.repoDraft
        ? ArticleRemoteKind.repoDraft
        : ArticleRemoteKind.post,
    githubSha: 'sha-$id',
  );
}

class _FakeArticleStore implements SyncArticleStore {
  final List<Article> articles;
  final List<int> markedRemoteDeleted = [];

  _FakeArticleStore(this.articles);

  @override
  Future<void> ensureCategories(List<String> names) async {}

  @override
  Future<void> ensureTags(List<String> names) async {}

  @override
  Future<List<Article>> getRemoteTracked() async => articles;

  @override
  Future<void> markAsRemoteDeleted(int id) async {
    markedRemoteDeleted.add(id);
    articles.firstWhere((article) => article.id == id).status =
        ArticleStatus.remoteDeleted;
  }

  @override
  Future<void> replaceWithRemote(Article article) async {}

  @override
  Future<void> upsertFromGitHub(Article article) async {}
}

class _FakeSettingsStore implements SyncSettingsStore {
  @override
  final Settings settings;
  int saveCount = 0;

  _FakeSettingsStore(this.settings);

  @override
  Future<void> save() async {
    saveCount++;
  }
}
