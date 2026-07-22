import 'package:yaml/yaml.dart';

/// Hexo frontmatter 解析与生成工具。
///
/// 使用 YAML 库解析，避免手动正则在遇到冒号、引号、方括号等特殊字符时
/// 产生非法输出或解析错误。写回时对字符串做正确的 YAML 编码，同时保留
/// 未知字段和原始字段顺序。
class FrontmatterHelper {
  FrontmatterHelper._();

  // ---------------------------------------------------------------------------
  // 解析
  // ---------------------------------------------------------------------------

  /// 从完整 Markdown 内容中提取 frontmatter 元数据。
  ///
  /// 返回的 Map 保持原始字段顺序。如果没有 frontmatter 则返回空 Map。
  static Map<String, dynamic> parseFrontmatter(String rawContent) {
    final body = _extractFrontmatterBody(rawContent);
    if (body == null) return {};
    return _parseYaml(body);
  }

  /// 提取正文部分（不含 frontmatter）。
  static String extractBody(String rawContent) {
    final regex = RegExp(r'^---\s*\n(.*?)\n---\s*\n(.*)$', dotAll: true);
    final match = regex.firstMatch(rawContent);
    return match != null ? match.group(2)! : rawContent;
  }

  /// 判断内容是否包含 frontmatter。
  static bool hasFrontmatter(String rawContent) {
    return _extractFrontmatterBody(rawContent) != null;
  }

  // ---------------------------------------------------------------------------
  // 生成
  // ---------------------------------------------------------------------------

  /// 从字段 Map 生成 frontmatter 字符串（含 `---` 边界和尾部换行）。
  ///
  /// - null 值和空字符串值会被跳过。
  /// - List 写成 YAML 块状列表。
  /// - 字符串中的特殊字符会正确加引号。
  static String generate(Map<String, dynamic> fields) {
    final buffer = StringBuffer('---\n');
    for (final entry in fields.entries) {
      final encoded = encodeValue(entry.value);
      if (encoded != null) {
        buffer.writeln('${entry.key}: $encoded');
      }
    }
    buffer.writeln('---');
    return buffer.toString();
  }

  /// 更新已有内容的 frontmatter，保留未知字段和原始字段顺序。
  ///
  /// [updates] 中 null 值的字段会被删除（不写入新的 frontmatter）。
  /// 如果原内容没有 frontmatter，则在最前面新建。
  static String updateFrontmatter(
    String rawContent,
    Map<String, dynamic> updates,
  ) {
    final fmBody = _extractFrontmatterBody(rawContent);

    if (fmBody == null) {
      // 没有 frontmatter，新建
      final cleanUpdates = _removeNulls(updates);
      if (cleanUpdates.isEmpty) return rawContent;
      return generate(cleanUpdates) + rawContent;
    }

    final body = extractBody(rawContent);
    final originalLines = fmBody.split('\n');
    final parsed = _parseYaml(fmBody);

    // 记录原始字段顺序
    final order = <String>[];
    for (final line in originalLines) {
      final key = _extractTopLevelKey(line);
      if (key != null && !order.contains(key)) {
        order.add(key);
      }
    }

    // 合并更新：已知字段覆盖，null 表示删除
    for (final entry in updates.entries) {
      parsed[entry.key] = entry.value;
      if (!order.contains(entry.key)) {
        order.add(entry.key);
      }
    }

    // 写回时保持原始顺序
    final buffer = StringBuffer('---\n');
    for (final key in order) {
      if (!parsed.containsKey(key)) continue;
      final value = parsed[key];
      final encoded = encodeValue(value);
      if (encoded != null) {
        buffer.writeln('$key: $encoded');
      }
    }
    buffer.writeln('---');
    return buffer.toString() + body;
  }

  // ---------------------------------------------------------------------------
  // 编码
  // ---------------------------------------------------------------------------

  /// 将 Dart 值编码为 YAML 标量或块状列表字符串。
  ///
  /// 返回 null 表示该值应跳过（null 或空字符串）。
  static String? encodeValue(Object? value) {
    if (value == null) return null;
    if (value is String) {
      if (value.isEmpty) return null;
      return _encodeString(value);
    }
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is List) {
      if (value.isEmpty) return null;
      return '[${value.map((e) => encodeValue(e) ?? 'null').join(', ')}]';
    }
    if (value is Map) {
      if (value.isEmpty) return '{}';
      final entries = value.entries.map((entry) {
        final key = _encodeString(entry.key.toString());
        final encodedValue = encodeValue(entry.value) ?? 'null';
        return '$key: $encodedValue';
      });
      return '{${entries.join(', ')}}';
    }
    return _encodeString(value.toString());
  }

  /// 对字符串做 YAML 安全编码。
  ///
  /// 如果字符串包含 YAML 特殊字符（冒号、引号、方括号、# 等）或
  /// 以 YAML 特殊前缀开头，则加双引号并转义内部引号。
  static String _encodeString(String value) {
    // 空字符串、布尔字面量、纯数字不需要引号
    if (value.isEmpty) return '""';
    if (_yamlBoolLiterals.contains(value.toLowerCase())) return '"$value"';
    if (double.tryParse(value) != null) return value;

    // 日期格式不需要引号（如 "2024-01-15 10:30:00"）
    if (_datePattern.hasMatch(value)) return value;

    // 需要引号的场景
    final needsQuote =
        value.contains(':') ||
        value.contains('#') ||
        value.contains('"') ||
        value.contains("'") ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains('{') ||
        value.contains('}') ||
        value.contains(',') ||
        value.contains('&') ||
        value.contains('*') ||
        value.contains('?') ||
        value.contains('|') ||
        value.contains('>') ||
        value.contains('!') ||
        value.contains('%') ||
        value.contains('@') ||
        value.contains('`') ||
        value.contains('\n') ||
        value.startsWith(' ') ||
        value.endsWith(' ') ||
        value.startsWith('-') ||
        value.startsWith('?') ||
        value.startsWith(':') ||
        value.startsWith(',');

    if (needsQuote) {
      final escaped = value
          .replaceAll(r'\', r'\\')
          .replaceAll('"', r'\"')
          .replaceAll('\n', r'\n')
          .replaceAll('\r', r'\r')
          .replaceAll('\t', r'\t');
      return '"$escaped"';
    }
    return value;
  }

  // ---------------------------------------------------------------------------
  // 日期解析
  // ---------------------------------------------------------------------------

  /// 解析 Hexo 常见日期格式。
  ///
  /// 支持：
  /// - ISO 8601: `2024-01-15T10:30:00`
  /// - Hexo 标准: `2024-01-15 10:30:00`
  /// - 带引号: `"2024-01-15 10:30:00"`
  static DateTime? parseDate(String raw) {
    final cleaned = raw.trim().replaceAll('"', '').replaceAll("'", '');
    // "2024-01-15 10:30:00" -> "2024-01-15T10:30:00"
    final normalized = cleaned.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  static const _yamlBoolLiterals = {'true', 'false', 'yes', 'no', 'on', 'off'};
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}');

  /// 提取 `---` 之间的 YAML 文本，不含边界行。
  static String? _extractFrontmatterBody(String rawContent) {
    final regex = RegExp(r'^---\s*\n(.*?)\n---\s*\n', dotAll: true);
    final match = regex.firstMatch(rawContent);
    return match?.group(1);
  }

  /// 使用 yaml 库解析，返回有序 Map。
  static Map<String, dynamic> _parseYaml(String yamlStr) {
    final dynamic doc = loadYaml(yamlStr);
    if (doc is! Map) return {};
    final result = <String, dynamic>{};
    for (final entry in doc.entries) {
      final key = entry.key.toString();
      final value = _convertYamlValue(entry.value);
      result[key] = value;
    }
    return result;
  }

  /// 递归转换 YamlList / YamlMap 为 Dart 原生类型。
  static Object? _convertYamlValue(Object? value) {
    if (value is YamlList) {
      return value.map(_convertYamlValue).toList();
    }
    if (value is YamlMap) {
      final map = <String, dynamic>{};
      for (final entry in value.entries) {
        map[entry.key.toString()] = _convertYamlValue(entry.value);
      }
      return map;
    }
    return value;
  }

  /// 从一行 YAML 文本中提取顶层 key（仅 `key:` 形式）。
  static String? _extractTopLevelKey(String line) {
    // 跳过缩进行（列表子项或嵌套值）
    if (line.startsWith(' ') || line.startsWith('\t')) return null;
    final match = RegExp(r'^([A-Za-z0-9_-]+)\s*:').firstMatch(line.trim());
    return match?.group(1);
  }

  /// 移除 Map 中 null 值的条目。
  static Map<String, dynamic> _removeNulls(Map<String, dynamic> map) {
    return Map.fromEntries(map.entries.where((e) => e.value != null));
  }
}
