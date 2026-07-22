import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/services/editor_tools_service.dart';

void main() {
  group('EditorToolsService.analyze', () {
    test('提取标题并忽略代码块中的伪标题', () {
      const markdown = '''# 标题
正文 hello world
```dart
## 不是标题
```
## 二级标题
''';

      final metrics = EditorToolsService.analyze(markdown);

      expect(metrics.headings.map((heading) => heading.text), ['标题', '二级标题']);
      expect(metrics.headings.map((heading) => heading.level), [1, 2]);
      expect(metrics.wordCount, 2);
      expect(metrics.cjkCount, greaterThanOrEqualTo(5));
      expect(metrics.readingMinutes, 1);
    });
  });

  group('EditorToolsService.findNext', () {
    test('从当前位置查找并在结尾回绕', () {
      const text = 'One two one';

      final first = EditorToolsService.findNext(text, 'one', 0);
      final wrapped = EditorToolsService.findNext(text, 'one', 4);

      expect(first?.start, 0);
      expect(wrapped?.start, 8);
    });

    test('支持区分大小写', () {
      const text = 'One one';

      expect(
        EditorToolsService.findNext(text, 'one', 0, caseSensitive: true),
        isNotNull,
      );
      expect(
        EditorToolsService.findNext(text, 'ONE', 0, caseSensitive: true),
        isNull,
      );
    });
  });

  test('replaceAll 返回替换后文本和数量', () {
    final result = EditorToolsService.replaceAll('one One one', 'one', 'two');

    expect(result.text, 'two two two');
    expect(result.count, 3);
  });
}
