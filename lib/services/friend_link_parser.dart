import '../models/friend_link.dart';
import '../models/settings.dart' show FriendLinkFileFormat;

/// 友链 YAML 解析器
///
/// 支持解析保留注释的友链 YAML 格式：
/// ```yaml
/// - name: 鼠鼠在碎觉
///   link: https://sszsj.com
///   avatar: https://tmx.fishpi.cn/image/head.jpg
///   descr: 我是不慎落入世界的一滴水墨
///
/// # - name: 暂时禁用的友链
/// #   link: https://example.com
/// ```
///
/// 同时支持根级列表的 `url`、`image`、`desc` 字段。解析后两种格式都会
/// 映射为 [FriendLink] 的 `link`、`avatar`、`descr` 字段。
class FriendLinkParser {
  static const _defaultClassName = '友情链接';
  static const _defaultClassDesc = '那些人，那些事';
  static const _defaultEntryIndent = '    ';
  static final _entryRegExp = RegExp(r'^#?\s*-\s*name:\s*(.+)$');
  static final _entryLineRegExp = RegExp(r'^(\s*)#?\s*-\s*name:\s*.+$');
  static final _linkListRegExp = RegExp(r'^(\s*)link_list:\s*$');
  static final _fieldRegExp = RegExp(
    r'^(link|url|avatar|image|descr|desc):\s*(.*)$',
  );

  static const _standardFieldNames = _FriendLinkFieldNames(
    link: 'link',
    avatar: 'avatar',
    descr: 'descr',
    descriptionBeforeAvatar: false,
  );
  static const _flatFieldNames = _FriendLinkFieldNames(
    link: 'url',
    avatar: 'image',
    descr: 'desc',
    descriptionBeforeAvatar: true,
  );

  /// 解析 YAML 文本为友链列表
  ///
  /// 支持注释条目（`# - name: xxx` 标记为禁用）
  static List<FriendLink> parseYaml(String content) {
    final links = <FriendLink>[];
    final lines = content.split(RegExp(r'\r?\n'));

    String? currentName;
    String? currentLink;
    String currentAvatar = '';
    String currentDescr = '';
    bool currentCommented = false;
    bool inEntry = false;

    void saveCurrent() {
      if (!inEntry || currentName == null) return;
      links.add(
        FriendLink(
          name: currentName,
          link: currentLink ?? '',
          avatar: currentAvatar,
          descr: currentDescr,
          isCommented: currentCommented,
        ),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // 检测新条目开始：- name: 或 # - name:
      final entryMatch = _entryRegExp.firstMatch(trimmed);
      if (entryMatch != null) {
        // 保存上一个条目
        saveCurrent();

        // 开始新条目
        currentName = entryMatch.group(1)!.trim();
        currentLink = null;
        currentAvatar = '';
        currentDescr = '';
        currentCommented = trimmed.startsWith('#');
        inEntry = true;
        continue;
      }

      // 检测条目内的字段
      if (inEntry) {
        final fieldLine = _stripCommentPrefix(trimmed);
        final fieldMatch = _fieldRegExp.firstMatch(fieldLine);
        if (fieldMatch != null) {
          final value = fieldMatch.group(2)!.trim();
          switch (fieldMatch.group(1)!) {
            case 'link':
            case 'url':
              currentLink = value;
              break;
            case 'avatar':
            case 'image':
              currentAvatar = value;
              break;
            case 'descr':
            case 'desc':
              currentDescr = value;
              break;
          }
          continue;
        }

        // 如果遇到非字段行，结束当前条目
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          // 保存当前条目
          saveCurrent();
          inEntry = false;
          currentName = null;
        }
      }
    }

    // 保存最后一个条目
    saveCurrent();

    return links;
  }

  /// 生成 YAML 文本
  ///
  /// 根据 isCommented 决定是否添加 `# ` 前缀
  static String generateYaml(
    List<FriendLink> links, {
    String entryIndent = '',
    String lineEnding = '\n',
  }) => _generateYaml(
    links,
    entryIndent: entryIndent,
    lineEnding: lineEnding,
    fieldNames: _standardFieldNames,
  );

  static String _generateYaml(
    List<FriendLink> links, {
    required String entryIndent,
    required String lineEnding,
    required _FriendLinkFieldNames fieldNames,
  }) {
    final buffer = StringBuffer();

    void writeLine(String line) {
      buffer.write(line);
      buffer.write(lineEnding);
    }

    for (final link in links) {
      final prefix = link.isCommented ? '# ' : '';

      writeLine('$entryIndent$prefix- name: ${link.name}');
      writeLine('$entryIndent$prefix  ${fieldNames.link}: ${link.link}');
      if (fieldNames.descriptionBeforeAvatar) {
        if (link.descr.isNotEmpty) {
          writeLine('$entryIndent$prefix  ${fieldNames.descr}: ${link.descr}');
        }
        if (link.avatar.isNotEmpty) {
          writeLine(
            '$entryIndent$prefix  ${fieldNames.avatar}: ${link.avatar}',
          );
        }
      } else {
        if (link.avatar.isNotEmpty) {
          writeLine(
            '$entryIndent$prefix  ${fieldNames.avatar}: ${link.avatar}',
          );
        }
        if (link.descr.isNotEmpty) {
          writeLine('$entryIndent$prefix  ${fieldNames.descr}: ${link.descr}');
        }
      }
      writeLine('');
    }

    return buffer.toString().trimRight();
  }

  /// 生成带默认分组定义的友链文件 YAML。
  static String generateYamlWithDefaultHeader(
    List<FriendLink> links, {
    String lineEnding = '\n',
  }) {
    final header = [
      '- class_name: $_defaultClassName',
      '  class_desc: $_defaultClassDesc',
      '  link_list:',
    ].join(lineEnding);
    final yaml = generateYaml(
      links,
      entryIndent: _defaultEntryIndent,
      lineEnding: lineEnding,
    );

    if (yaml.isEmpty) return header;
    return '$header$lineEnding$yaml';
  }

  /// 按指定格式创建新的友链文件。
  ///
  /// 仅在远端文件不存在或为空时使用。已有文件的格式应由
  /// [generateYamlPreservingHeader] 从远端内容自动识别。
  static String generateYamlForFormat(
    List<FriendLink> links,
    FriendLinkFileFormat format, {
    String lineEnding = '\n',
  }) {
    switch (format) {
      case FriendLinkFileFormat.butterfly:
        return generateYamlWithDefaultHeader(links, lineEnding: lineEnding);
      case FriendLinkFileFormat.flat:
        return _generateYaml(
          links,
          entryIndent: '',
          lineEnding: lineEnding,
          fieldNames: _flatFieldNames,
        );
    }
  }

  /// 生成 YAML 文本，并保留已有文件中友链列表前的定义。
  ///
  /// 典型 Hexo/Butterfly 友链文件会在列表前声明 `class_name`、
  /// `class_desc` 和 `link_list`。推送已有文件时只替换友链条目，
  /// 避免把这些主题需要的结构抹掉。
  static String generateYamlPreservingHeader(
    List<FriendLink> links,
    String existingContent, {
    FriendLinkFileFormat fallbackFormat = FriendLinkFileFormat.butterfly,
  }
  ) {
    final template = _extractTemplate(existingContent);
    if (template == null) {
      return generateYamlForFormat(
        links,
        fallbackFormat,
        lineEnding: _detectLineEnding(existingContent),
      );
    }

    final yaml = _generateYaml(
      links,
      entryIndent: template.entryIndent,
      lineEnding: template.lineEnding,
      fieldNames: template.fieldNames,
    );
    final header = template.header.trimRight();

    if (header.isEmpty) return yaml;
    if (yaml.isEmpty) return header;
    return '$header${template.lineEnding}$yaml';
  }

  /// 根据已有内容判断布局；空文件或无法识别的内容使用 [fallbackFormat]。
  static FriendLinkFileFormat detectFormat(
    String content, {
    FriendLinkFileFormat fallbackFormat = FriendLinkFileFormat.butterfly,
  }) => _extractTemplate(content)?.format ?? fallbackFormat;

  /// 返回推送前应当阻止写入的原因；`null` 表示可以安全重写。
  ///
  /// 目前本地模型只表示单个列表的四个标准字段。多个 `link_list` 分组或
  /// 条目内的自定义字段会在重写时丢失，因此主动拒绝推送而不是静默覆盖。
  static String? validateWritableContent(String content) {
    if (content.trim().isEmpty) return null;

    final lines = content.split(RegExp(r'\r?\n'));
    final linkListCount = lines
        .where((line) => _linkListRegExp.hasMatch(line))
        .length;
    if (linkListCount > 1) {
      return '友链文件包含多个 link_list 分组，暂不支持推送以避免覆盖内容';
    }

    if (_extractTemplate(content) == null) {
      return '无法识别友链文件格式，已取消推送以避免覆盖内容';
    }

    const knownFields = {'link', 'url', 'avatar', 'image', 'descr', 'desc'};
    var inEntry = false;
    var entryIsCommented = false;

    for (final line in lines) {
      final trimmed = line.trim();
      final entryMatch = _entryRegExp.firstMatch(trimmed);
      if (entryMatch != null) {
        inEntry = true;
        entryIsCommented = trimmed.startsWith('#');
        continue;
      }
      if (!inEntry || trimmed.isEmpty) continue;

      // 普通注释不会被生成器保留，但也不属于条目字段，不应阻塞推送。
      if (trimmed.startsWith('#') && !entryIsCommented) continue;

      final fieldLine = _stripCommentPrefix(trimmed);
      final fieldMatch = _fieldRegExp.firstMatch(fieldLine);
      if (fieldMatch != null) continue;

      final keyMatch = RegExp(r'^([A-Za-z_][A-Za-z0-9_-]*):').firstMatch(
        fieldLine,
      );
      if (keyMatch != null) {
        final key = keyMatch.group(1)!;
        if (!knownFields.contains(key)) {
          return '友链条目包含暂不支持的字段 "$key"，已取消推送以避免丢失内容';
        }
        continue;
      }

      if (!trimmed.startsWith('#')) {
        return '友链条目包含暂不支持的 YAML 结构，已取消推送以避免丢失内容';
      }
    }

    return null;
  }

  static _FriendLinkYamlTemplate? _extractTemplate(String content) {
    if (content.trim().isEmpty) return null;

    final lineEnding = _detectLineEnding(content);
    final lines = content.split(RegExp(r'\r?\n'));

    for (var i = 0; i < lines.length; i++) {
      final linkListMatch = _linkListRegExp.firstMatch(lines[i]);
      if (linkListMatch == null) continue;

      for (var j = i + 1; j < lines.length; j++) {
        final entryMatch = _entryLineRegExp.firstMatch(lines[j]);
        if (entryMatch == null) continue;

        return _FriendLinkYamlTemplate(
          format: FriendLinkFileFormat.butterfly,
          header: lines.take(j).join(lineEnding),
          entryIndent: entryMatch.group(1)!,
          lineEnding: lineEnding,
          fieldNames: _detectFieldNames(
            lines,
            j,
            defaultFieldNames: _standardFieldNames,
          ),
        );
      }

      return _FriendLinkYamlTemplate(
        format: FriendLinkFileFormat.butterfly,
        header: lines.take(i + 1).join(lineEnding),
        entryIndent: '${linkListMatch.group(1)!}  ',
        lineEnding: lineEnding,
        fieldNames: _standardFieldNames,
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final entryMatch = _entryLineRegExp.firstMatch(lines[i]);
      if (entryMatch == null) continue;

      return _FriendLinkYamlTemplate(
        format: FriendLinkFileFormat.flat,
        header: lines.take(i).join(lineEnding),
        entryIndent: entryMatch.group(1)!,
        lineEnding: lineEnding,
        fieldNames: _detectFieldNames(
          lines,
          i,
          defaultFieldNames: _flatFieldNames,
        ),
      );
    }

    return null;
  }

  static _FriendLinkFieldNames _detectFieldNames(
    List<String> lines,
    int entryIndex, {
    required _FriendLinkFieldNames defaultFieldNames,
  }) {
    final fieldKeys = <String>[];

    for (var i = entryIndex + 1; i < lines.length; i++) {
      final match = _fieldRegExp.firstMatch(_stripCommentPrefix(lines[i].trim()));
      if (match == null) continue;
      fieldKeys.add(match.group(1)!);
    }

    final usesFlatFields = fieldKeys.any(
      (key) => key == 'url' || key == 'image' || key == 'desc',
    );
    final usesStandardFields = fieldKeys.any(
      (key) => key == 'link' || key == 'avatar' || key == 'descr',
    );
    final resolvedDefaults =
        defaultFieldNames.descriptionBeforeAvatar &&
            usesStandardFields &&
            !usesFlatFields
        ? _standardFieldNames
        : defaultFieldNames;

    var link = resolvedDefaults.link;
    var avatar = resolvedDefaults.avatar;
    var descr = resolvedDefaults.descr;

    for (final key in fieldKeys) {
      switch (key) {
        case 'link':
        case 'url':
          link = key;
          break;
        case 'avatar':
        case 'image':
          avatar = key;
          break;
        case 'descr':
        case 'desc':
          descr = key;
          break;
      }
    }

    return _FriendLinkFieldNames(
      link: link,
      avatar: avatar,
      descr: descr,
      descriptionBeforeAvatar: resolvedDefaults.descriptionBeforeAvatar,
    );
  }

  static String _stripCommentPrefix(String line) {
    if (line.startsWith('# ')) return line.substring(2).trim();
    if (line.startsWith('#') && line.length > 1) {
      return line.substring(1).trim();
    }
    return line.trim();
  }

  static String _detectLineEnding(String content) {
    return content.contains('\r\n') ? '\r\n' : '\n';
  }
}

class _FriendLinkYamlTemplate {
  final FriendLinkFileFormat format;
  final String header;
  final String entryIndent;
  final String lineEnding;
  final _FriendLinkFieldNames fieldNames;

  const _FriendLinkYamlTemplate({
    required this.format,
    required this.header,
    required this.entryIndent,
    required this.lineEnding,
    required this.fieldNames,
  });
}

class _FriendLinkFieldNames {
  final String link;
  final String avatar;
  final String descr;
  final bool descriptionBeforeAvatar;

  const _FriendLinkFieldNames({
    required this.link,
    required this.avatar,
    required this.descr,
    required this.descriptionBeforeAvatar,
  });
}
