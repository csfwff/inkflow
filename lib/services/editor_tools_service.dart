/// Pure Markdown editor helpers shared by the editor UI and unit tests.
class EditorToolsService {
  EditorToolsService._();

  static EditorMetrics analyze(String markdown) {
    final headings = <EditorHeading>[];
    var offset = 0;
    var insideFence = false;
    final lines = markdown.split('\n');
    final prose = StringBuffer();

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
        insideFence = !insideFence;
      } else if (!insideFence) {
        prose.writeln(line);
        final match = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$').firstMatch(line);
        if (match != null) {
          final text = match.group(2)!.trim();
          if (text.isNotEmpty) {
            headings.add(
              EditorHeading(
                level: match.group(1)!.length,
                text: text,
                offset: offset,
                line: index + 1,
              ),
            );
          }
        }
      }
      offset += line.length + 1;
    }

    final proseText = prose.toString();
    final cjkCount = RegExp(
      r'[\u3400-\u9FFF\uF900-\uFAFF]',
    ).allMatches(proseText).length;
    final latinText = proseText.replaceAll(
      RegExp(r'[\u3400-\u9FFF\uF900-\uFAFF]'),
      ' ',
    );
    final wordCount = RegExp(
      r"[A-Za-z0-9]+(?:['’-][A-Za-z0-9]+)?",
    ).allMatches(latinText).length;
    final characters = proseText.replaceAll(RegExp(r'\s'), '').runes.length;
    final estimatedMinutes = ((cjkCount / 300) + (wordCount / 200)).ceil();
    final readingMinutes = characters == 0
        ? 0
        : estimatedMinutes < 1
        ? 1
        : estimatedMinutes > 9999
        ? 9999
        : estimatedMinutes;

    return EditorMetrics(
      characters: characters,
      wordCount: wordCount,
      cjkCount: cjkCount,
      readingMinutes: readingMinutes,
      headings: headings,
    );
  }

  static TextMatch? findNext(
    String text,
    String query,
    int startOffset, {
    bool caseSensitive = false,
  }) {
    if (query.isEmpty || text.isEmpty) return null;
    final haystack = caseSensitive ? text : text.toLowerCase();
    final needle = caseSensitive ? query : query.toLowerCase();
    final start = startOffset.clamp(0, text.length);
    var index = haystack.indexOf(needle, start);
    if (index < 0 && start > 0) {
      index = haystack.indexOf(needle);
    }
    if (index < 0) return null;
    return TextMatch(start: index, end: index + query.length);
  }

  static TextReplaceResult replaceAll(
    String text,
    String query,
    String replacement, {
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return TextReplaceResult(text: text, count: 0);
    final pattern = RegExp(RegExp.escape(query), caseSensitive: caseSensitive);
    final count = pattern.allMatches(text).length;
    return TextReplaceResult(
      text: text.replaceAll(pattern, replacement),
      count: count,
    );
  }
}

class EditorMetrics {
  final int characters;
  final int wordCount;
  final int cjkCount;
  final int readingMinutes;
  final List<EditorHeading> headings;

  const EditorMetrics({
    required this.characters,
    required this.wordCount,
    required this.cjkCount,
    required this.readingMinutes,
    required this.headings,
  });
}

class EditorHeading {
  final int level;
  final String text;
  final int offset;
  final int line;

  const EditorHeading({
    required this.level,
    required this.text,
    required this.offset,
    required this.line,
  });
}

class TextMatch {
  final int start;
  final int end;

  const TextMatch({required this.start, required this.end});
}

class TextReplaceResult {
  final String text;
  final int count;

  const TextReplaceResult({required this.text, required this.count});
}
