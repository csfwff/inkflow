enum TextDiffKind { unchanged, added, removed }

class TextDiffLine {
  final TextDiffKind kind;
  final String text;

  const TextDiffLine({required this.kind, required this.text});
}

class TextDiffResult {
  final List<TextDiffLine> lines;
  final int addedCount;
  final int removedCount;
  final bool truncated;

  const TextDiffResult({
    required this.lines,
    required this.addedCount,
    required this.removedCount,
    required this.truncated,
  });
}

/// Small, dependency-free line diff for the conflict dialog.
///
/// The dialog intentionally caps work for very large Markdown files. In that
/// case it still presents the three versions for manual review rather than
/// making the editor unresponsive.
class TextDiffService {
  TextDiffService._();

  static TextDiffResult compare(
    String before,
    String after, {
    int maxLines = 400,
  }) {
    final left = before.split('\n');
    final right = after.split('\n');
    if (left.length > maxLines || right.length > maxLines) {
      return TextDiffResult(
        lines: const [],
        addedCount: 0,
        removedCount: 0,
        truncated: true,
      );
    }

    final table = List.generate(
      left.length + 1,
      (_) => List<int>.filled(right.length + 1, 0),
    );
    for (var i = left.length - 1; i >= 0; i--) {
      for (var j = right.length - 1; j >= 0; j--) {
        table[i][j] = left[i] == right[j]
            ? table[i + 1][j + 1] + 1
            : table[i + 1][j] >= table[i][j + 1]
            ? table[i + 1][j]
            : table[i][j + 1];
      }
    }

    final lines = <TextDiffLine>[];
    var addedCount = 0;
    var removedCount = 0;
    var i = 0;
    var j = 0;
    while (i < left.length && j < right.length) {
      if (left[i] == right[j]) {
        lines.add(TextDiffLine(kind: TextDiffKind.unchanged, text: left[i]));
        i++;
        j++;
      } else if (table[i + 1][j] >= table[i][j + 1]) {
        lines.add(TextDiffLine(kind: TextDiffKind.removed, text: left[i]));
        removedCount++;
        i++;
      } else {
        lines.add(TextDiffLine(kind: TextDiffKind.added, text: right[j]));
        addedCount++;
        j++;
      }
    }
    while (i < left.length) {
      lines.add(TextDiffLine(kind: TextDiffKind.removed, text: left[i++]));
      removedCount++;
    }
    while (j < right.length) {
      lines.add(TextDiffLine(kind: TextDiffKind.added, text: right[j++]));
      addedCount++;
    }

    return TextDiffResult(
      lines: lines,
      addedCount: addedCount,
      removedCount: removedCount,
      truncated: false,
    );
  }
}
