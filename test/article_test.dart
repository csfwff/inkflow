import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/models/article.dart';
import 'package:inkflow/services/frontmatter_helper.dart';

void main() {
  group('Article.buildRemotePath', () {
    test('post 类型生成 source/_posts/ 前缀', () {
      expect(
        Article.buildRemotePath(
          kind: ArticleRemoteKind.post,
          filePath: '2026/06/hello.md',
        ),
        'source/_posts/2026/06/hello.md',
      );
    });

    test('repoDraft 类型生成 source/_drafts/ 前缀', () {
      expect(
        Article.buildRemotePath(
          kind: ArticleRemoteKind.repoDraft,
          filePath: 'hello.md',
        ),
        'source/_drafts/hello.md',
      );
    });
  });

  group('Article.bodyContent', () {
    test('去掉 frontmatter 返回正文', () {
      final article = Article(
        title: 'Test',
        content: '---\ntitle: Test\n---\nHello World',
        date: DateTime(2026),
        slug: 'test',
      );
      expect(article.bodyContent, 'Hello World');
    });

    test('没有 frontmatter 返回原始内容', () {
      final article = Article(
        title: 'Test',
        content: 'Just plain text.',
        date: DateTime(2026),
        slug: 'test',
      );
      expect(article.bodyContent, 'Just plain text.');
    });

    test('正文中包含 --- 不影响提取', () {
      final article = Article(
        title: 'Test',
        content: '---\ntitle: Test\n---\nSome\n\n---\n\nMore',
        date: DateTime(2026),
        slug: 'test',
      );
      expect(article.bodyContent, 'Some\n\n---\n\nMore');
    });
  });

  group('Article.buildFrontmatter', () {
    test('生成基本字段', () {
      final article = Article(
        title: 'Hello',
        content: '',
        date: DateTime(2026, 1, 15, 10, 30, 0),
        slug: 'hello',
      );
      final fm = article.buildFrontmatter();
      expect(fm, contains('title: Hello'));
      expect(fm, contains('date: 2026-01-15 10:30:00'));
      expect(fm, startsWith('---\n'));
      expect(fm, endsWith('---\n'));
    });

    test('tags 和 categories 非空时写入', () {
      final article = Article(
        title: 'Test',
        content: '',
        date: DateTime(2026),
        slug: 'test',
        tags: ['dart', 'flutter'],
        categories: ['Tech'],
      );
      final fm = article.buildFrontmatter();
      expect(fm, contains('tags: [dart, flutter]'));
      expect(fm, contains('categories: [Tech]'));
    });

    test('tags/categories 为空时不写入', () {
      final article = Article(
        title: 'Test',
        content: '',
        date: DateTime(2026),
        slug: 'test',
      );
      final fm = article.buildFrontmatter();
      expect(fm, isNot(contains('tags')));
      expect(fm, isNot(contains('categories')));
    });

    test('含特殊字符的 title 正确编码', () {
      final article = Article(
        title: 'Hello: World',
        content: '',
        date: DateTime(2026),
        slug: 'test',
      );
      final fm = article.buildFrontmatter();
      expect(fm, contains('title: "Hello: World"'));
    });
  });

  group('Article.updateFrontmatter', () {
    test('更新已有字段', () {
      final article = Article(
        title: 'New Title',
        content: '---\ntitle: Old\ndate: 2024-01-01 00:00:00\n---\nBody',
        date: DateTime(2026),
        slug: 'test',
      );
      final result = article.updateFrontmatter();
      expect(result, contains('title: New Title'));
      expect(result, contains('Body'));
    });

    test('保留未知字段', () {
      final article = Article(
        title: 'Test',
        content: '---\ntitle: Test\nmyField: hello\n---\nBody',
        date: DateTime(2026),
        slug: 'test',
      );
      final result = article.updateFrontmatter();
      expect(result, contains('myField: hello'));
    });

    test('没有 frontmatter 时新建', () {
      final article = Article(
        title: 'New',
        content: 'Just body.',
        date: DateTime(2026),
        slug: 'test',
      );
      final result = article.updateFrontmatter();
      expect(result, startsWith('---\n'));
      expect(result, contains('title: New'));
      expect(result, contains('Just body.'));
    });

    test('未编辑的自定义字段保留 YAML 类型', () {
      final article = Article(
        title: 'Test',
        content: '---\ntitle: Test\n---\nBody',
        date: DateTime(2026),
        slug: 'test',
        customFields: {
          'comments': true,
          'priority': 3,
          'related': ['a', 'b'],
          'settings': {'featured': true},
        },
      );

      final result = article.updateFrontmatter();
      final parsed = FrontmatterHelper.parseFrontmatter(result);
      expect(parsed['comments'], isTrue);
      expect(parsed['priority'], 3);
      expect(parsed['related'], ['a', 'b']);
      expect(parsed['settings'], {'featured': true});
    });
  });

  test('自定义字段经 JSON 存储后保留类型', () {
    final article = Article(
      title: 'Test',
      content: '',
      date: DateTime(2026),
      slug: 'test',
      customFields: {
        'comments': true,
        'priority': 3,
        'related': ['a', 'b'],
        'settings': {'featured': true},
      },
    );

    final stored =
        jsonDecode(jsonEncode(article.toMap())) as Map<String, dynamic>;
    final restored = Article.fromMap(stored);

    expect(restored.customFields['comments'], isTrue);
    expect(restored.customFields['priority'], 3);
    expect(restored.customFields['related'], ['a', 'b']);
    expect(restored.customFields['settings'], {'featured': true});
  });
}
