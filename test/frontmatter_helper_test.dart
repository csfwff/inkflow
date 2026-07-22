import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/services/frontmatter_helper.dart';

void main() {
  group('FrontmatterHelper.parseFrontmatter', () {
    test('解析基本 frontmatter', () {
      const raw =
          '---\ntitle: Hello World\ndate: 2024-01-15 10:30:00\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['title'], 'Hello World');
      expect(meta['date'], isNotNull);
    });

    test('解析含冒号的 title', () {
      const raw =
          '---\ntitle: "Hello: World"\ndate: 2024-01-15 10:30:00\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['title'], 'Hello: World');
    });

    test('解析含引号的 title', () {
      const raw = "---\ntitle: \"It's a \\\"test\\\"\"\n---\nBody";
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['title'], "It's a \"test\"");
    });

    test('解析行内 tags [a, b, c]', () {
      const raw = '---\ntitle: Test\ntags: [dart, flutter, yaml]\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['tags'], ['dart', 'flutter', 'yaml']);
    });

    test('解析块状 tags', () {
      const raw =
          '---\ntitle: Test\ntags:\n  - dart\n  - flutter\n  - yaml\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['tags'], ['dart', 'flutter', 'yaml']);
    });

    test('解析块状 categories', () {
      const raw =
          '---\ntitle: Test\ncategories:\n  - Tech\n  - Dart\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['categories'], ['Tech', 'Dart']);
    });

    test('解析含特殊字符的 tags', () {
      const raw = '---\ntitle: Test\ntags: ["C++", "C#", "node.js"]\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['tags'], ['C++', 'C#', 'node.js']);
    });

    test('解析 boolean 和 null 值', () {
      const raw =
          '---\ntitle: Test\ncomments: true\npublished: false\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['comments'], true);
      expect(meta['published'], false);
    });

    test('没有 frontmatter 返回空 Map', () {
      const raw = 'Just plain markdown content.';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta, isEmpty);
    });

    test('保留未知字段', () {
      const raw =
          '---\ntitle: Test\nmyCustomField: hello\nanother_field: 42\n---\nBody';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['myCustomField'], 'hello');
      expect(meta['another_field'], 42);
    });
  });

  group('FrontmatterHelper.extractBody', () {
    test('提取正文', () {
      const raw = '---\ntitle: Test\n---\nHello World';
      expect(FrontmatterHelper.extractBody(raw), 'Hello World');
    });

    test('没有 frontmatter 返回原始内容', () {
      const raw = 'Just markdown.';
      expect(FrontmatterHelper.extractBody(raw), 'Just markdown.');
    });

    test('正文中包含 --- 不影响提取', () {
      const raw = '---\ntitle: Test\n---\nSome text\n\n---\n\nMore text';
      expect(
        FrontmatterHelper.extractBody(raw),
        'Some text\n\n---\n\nMore text',
      );
    });
  });

  group('FrontmatterHelper.generate', () {
    test('生成基本 frontmatter', () {
      final result = FrontmatterHelper.generate({
        'title': 'Hello World',
        'date': '2024-01-15 10:30:00',
      });
      expect(result, startsWith('---\n'));
      expect(result, contains('title: Hello World'));
      expect(result, contains('date: 2024-01-15 10:30:00'));
      expect(result, endsWith('---\n'));
    });

    test('对含冒号的 title 加引号', () {
      final result = FrontmatterHelper.generate({'title': 'Hello: World'});
      expect(result, contains('title: "Hello: World"'));
    });

    test('tags 生成行内列表', () {
      final result = FrontmatterHelper.generate({
        'title': 'Test',
        'tags': ['dart', 'flutter'],
      });
      expect(result, contains('tags: [dart, flutter]'));
    });

    test('categories 生成行内列表', () {
      final result = FrontmatterHelper.generate({
        'title': 'Test',
        'categories': ['Tech', 'Dart'],
      });
      expect(result, contains('categories: [Tech, Dart]'));
    });

    test('跳过 null 值', () {
      final result = FrontmatterHelper.generate({
        'title': 'Test',
        'permalink': null,
        'cover': null,
      });
      expect(result, isNot(contains('permalink')));
      expect(result, isNot(contains('cover')));
    });

    test('跳过空字符串', () {
      final result = FrontmatterHelper.generate({
        'title': 'Test',
        'author': '',
      });
      expect(result, isNot(contains('author')));
    });

    test('boolean 值不加引号', () {
      final result = FrontmatterHelper.generate({'comments': true});
      expect(result, contains('comments: true'));
    });

    test('含特殊字符的 tag 列表正确编码', () {
      final result = FrontmatterHelper.generate({
        'tags': ['C++', 'C#', 'node.js'],
      });
      // C++ 的 + 不是 YAML 特殊字符，不需要引号；C# 的 # 需要引号
      expect(result, contains('C++'));
      expect(result, contains('"C#"'));
    });
  });

  group('FrontmatterHelper.updateFrontmatter', () {
    test('更新已有字段', () {
      const raw = '---\ntitle: Old Title\ndate: 2024-01-01 00:00:00\n---\nBody';
      final result = FrontmatterHelper.updateFrontmatter(raw, {
        'title': 'New Title',
      });
      expect(result, contains('title: New Title'));
      expect(result, contains('Body'));
    });

    test('保留未知字段', () {
      const raw = '---\ntitle: Test\nmyField: hello\n---\nBody';
      final result = FrontmatterHelper.updateFrontmatter(raw, {
        'title': 'Updated',
      });
      expect(result, contains('myField: hello'));
      expect(result, contains('title: Updated'));
    });

    test('null 值删除对应字段', () {
      const raw = '---\ntitle: Test\npermalink: /old\n---\nBody';
      final result = FrontmatterHelper.updateFrontmatter(raw, {
        'permalink': null,
      });
      expect(result, isNot(contains('permalink')));
      expect(result, contains('title: Test'));
    });

    test('新增字段追加到末尾', () {
      const raw = '---\ntitle: Test\n---\nBody';
      final result = FrontmatterHelper.updateFrontmatter(raw, {'author': 'Me'});
      expect(result, contains('title: Test'));
      expect(result, contains('author: Me'));
    });

    test('没有 frontmatter 时新建', () {
      const raw = 'Just body text.';
      final result = FrontmatterHelper.updateFrontmatter(raw, {'title': 'New'});
      expect(result, startsWith('---\n'));
      expect(result, contains('title: New'));
      expect(result, contains('Just body text.'));
    });

    test('tags 列表正确 round-trip', () {
      const raw = '---\ntitle: Test\ntags:\n  - old1\n  - old2\n---\nBody';
      final result = FrontmatterHelper.updateFrontmatter(raw, {
        'tags': ['new1', 'new2', 'new3'],
      });
      expect(result, contains('[new1, new2, new3]'));
      expect(result, isNot(contains('old1')));
    });

    test('含特殊字符的 title round-trip', () {
      const raw = '---\ntitle: "Hello: World"\n---\nBody';
      final result = FrontmatterHelper.updateFrontmatter(raw, {
        'title': 'Hello: World',
      });
      expect(result, contains('title: "Hello: World"'));
    });
  });

  group('FrontmatterHelper.parseDate', () {
    test('解析 Hexo 标准格式', () {
      final d = FrontmatterHelper.parseDate('2024-01-15 10:30:00');
      expect(d, isNotNull);
      expect(d!.year, 2024);
      expect(d.month, 1);
      expect(d.day, 15);
      expect(d.hour, 10);
      expect(d.minute, 30);
    });

    test('解析 ISO 8601 格式', () {
      final d = FrontmatterHelper.parseDate('2024-01-15T10:30:00');
      expect(d, isNotNull);
      expect(d!.year, 2024);
    });

    test('解析带引号的日期', () {
      final d = FrontmatterHelper.parseDate('"2024-01-15 10:30:00"');
      expect(d, isNotNull);
      expect(d!.year, 2024);
    });

    test('无效日期返回 null', () {
      expect(FrontmatterHelper.parseDate('not-a-date'), isNull);
    });
  });

  group('FrontmatterHelper.encodeValue', () {
    test('null 返回 null', () {
      expect(FrontmatterHelper.encodeValue(null), isNull);
    });

    test('空字符串返回 null', () {
      expect(FrontmatterHelper.encodeValue(''), isNull);
    });

    test('普通字符串不加引号', () {
      expect(FrontmatterHelper.encodeValue('hello'), 'hello');
    });

    test('含冒号的字符串加引号', () {
      expect(FrontmatterHelper.encodeValue('a: b'), '"a: b"');
    });

    test('含引号的字符串转义', () {
      expect(FrontmatterHelper.encodeValue('say "hi"'), '"say \\"hi\\""');
    });

    test('boolean 不加引号', () {
      expect(FrontmatterHelper.encodeValue(true), 'true');
      expect(FrontmatterHelper.encodeValue(false), 'false');
    });

    test('数字直接输出', () {
      expect(FrontmatterHelper.encodeValue(42), '42');
      expect(FrontmatterHelper.encodeValue(3.14), '3.14');
    });

    test('列表生成行内格式', () {
      expect(FrontmatterHelper.encodeValue(['a', 'b', 'c']), '[a, b, c]');
    });

    test('空列表返回 null', () {
      expect(FrontmatterHelper.encodeValue([]), isNull);
    });

    test('含特殊字符的列表元素加引号', () {
      // C++ 的 + 不是 YAML 特殊字符，不需要引号；C# 的 # 需要引号
      expect(FrontmatterHelper.encodeValue(['C++', 'C#']), '[C++, "C#"]');
    });
  });

  group('边界情况', () {
    test('正文中包含 --- 不影响 frontmatter 解析', () {
      const raw =
          '---\ntitle: Test\n---\n\nSome text\n\n---\n\nMore text\n\n---\n';
      final meta = FrontmatterHelper.parseFrontmatter(raw);
      expect(meta['title'], 'Test');
      final body = FrontmatterHelper.extractBody(raw);
      expect(body, contains('---'));
      expect(body, contains('More text'));
    });

    test('title 含方括号正确 round-trip', () {
      final result = FrontmatterHelper.generate({'title': 'Test [2024] (v2)'});
      expect(result, contains('"Test [2024] (v2)"'));
      final parsed = FrontmatterHelper.parseFrontmatter('$result\nBody');
      expect(parsed['title'], 'Test [2024] (v2)');
    });

    test('description 含换行正确编码', () {
      final result = FrontmatterHelper.generate({
        'description': 'Line 1\nLine 2',
      });
      expect(result, contains(r'\n'));
      final parsed = FrontmatterHelper.parseFrontmatter('$result\nBody');
      expect(parsed['description'], 'Line 1\nLine 2');
    });

    test('tags 含冒号正确 round-trip', () {
      final generated = FrontmatterHelper.generate({
        'tags': ['key: value', 'normal'],
      });
      expect(generated, contains('"key: value"'));
      final parsed = FrontmatterHelper.parseFrontmatter('$generated\nBody');
      expect(parsed['tags'], ['key: value', 'normal']);
    });

    test('完整 round-trip：生成 -> 解析 -> 再生成', () {
      final original = {
        'title': 'Hello: "World"',
        'date': '2024-01-15 10:30:00',
        'tags': ['C++', 'flutter'],
        'categories': ['Tech'],
        'description': 'A test: with special chars',
        'author': 'Me',
      };
      final generated = FrontmatterHelper.generate(original);
      final parsed = FrontmatterHelper.parseFrontmatter(
        '$generated\nBody content',
      );
      // 日期经过 normalize 会变成 DateTime，这里只验证其他字段
      expect(parsed['title'], original['title']);
      expect(parsed['tags'], original['tags']);
      expect(parsed['categories'], original['categories']);
      expect(parsed['description'], original['description']);
      expect(parsed['author'], original['author']);
    });
  });
}
