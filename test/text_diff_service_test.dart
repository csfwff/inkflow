import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/services/text_diff_service.dart';

void main() {
  test('生成按行的新增和删除差异', () {
    final result = TextDiffService.compare(
      'title\nlocal\nshared',
      'title\nremote\nshared',
    );

    expect(result.truncated, isFalse);
    expect(result.addedCount, 1);
    expect(result.removedCount, 1);
    expect(result.lines.map((line) => (line.kind, line.text)), [
      (TextDiffKind.unchanged, 'title'),
      (TextDiffKind.removed, 'local'),
      (TextDiffKind.added, 'remote'),
      (TextDiffKind.unchanged, 'shared'),
    ]);
  });

  test('大文档超出上限时不计算矩阵', () {
    final longText = List.filled(5, 'line').join('\n');

    final result = TextDiffService.compare(longText, longText, maxLines: 4);

    expect(result.truncated, isTrue);
    expect(result.lines, isEmpty);
  });
}
