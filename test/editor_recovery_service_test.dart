import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/models/article.dart';
import 'package:inkflow/services/editor_recovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late EditorRecoveryService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = EditorRecoveryService();
  });

  test('保存并读取崩溃恢复内容', () async {
    final recovery = EditorRecovery(
      title: 'Draft',
      body: 'Unsaved body',
      date: DateTime(2026, 7, 22),
      savedAt: DateTime(2026, 7, 22, 12),
    );
    final key = service.recoveryKeyForArticle(null);

    await service.saveRecovery(key, recovery);
    final restored = await service.loadRecovery(key);

    expect(restored?.title, 'Draft');
    expect(restored?.body, 'Unsaved body');
    await service.clearRecovery(key);
    expect(await service.loadRecovery(key), isNull);
  });

  test('版本历史保留最近版本并跳过重复内容', () async {
    final first = _article(content: 'first');
    final second = _article(content: 'second');

    await service.saveRevision(first);
    await service.saveRevision(first);
    await service.saveRevision(second);
    final revisions = await service.listRevisions(1);

    expect(revisions, hasLength(2));
    expect(revisions.first.article.content, 'second');
    expect(revisions.last.article.content, 'first');
  });
}

Article _article({required String content}) {
  return Article(
    id: 1,
    title: 'Test',
    content: content,
    date: DateTime(2026),
    slug: 'test',
  );
}
