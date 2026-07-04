import '../models/friend_link.dart';

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
class FriendLinkParser {
  static const _defaultClassName = '友情链接';
  static const _defaultClassDesc = '那些人，那些事';
  static const _defaultEntryIndent = '    ';

  /// 解析 YAML 文本为友链列表
  ///
  /// 支持注释条目（`# - name: xxx` 标记为禁用）
  static List<FriendLink> parseYaml(String content) {
    final links = <FriendLink>[];
    final lines = content.split('\n');

    String? currentName;
    String? currentLink;
    String currentAvatar = '';
    String currentDescr = '';
    bool currentCommented = false;
    bool inEntry = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // 检测新条目开始：- name: 或 # - name:
      final entryMatch = RegExp(r'^#?\s*-\s*name:\s*(.+)$').firstMatch(trimmed);
      if (entryMatch != null) {
        // 保存上一个条目
        if (inEntry && currentName != null) {
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
        // 处理注释前缀（支持 # 和 # 两种格式）
        String fieldLine = trimmed;
        if (fieldLine.startsWith('# ')) {
          fieldLine = fieldLine.substring(2);
        } else if (fieldLine.startsWith('#') && fieldLine.length > 1) {
          fieldLine = fieldLine.substring(1);
        }
        fieldLine = fieldLine.trim();

        final linkMatch = RegExp(r'^link:\s*(.+)$').firstMatch(fieldLine);
        if (linkMatch != null) {
          currentLink = linkMatch.group(1)!.trim();
          continue;
        }

        final avatarMatch = RegExp(r'^avatar:\s*(.+)$').firstMatch(fieldLine);
        if (avatarMatch != null) {
          currentAvatar = avatarMatch.group(1)!.trim();
          continue;
        }

        final descrMatch = RegExp(r'^descr:\s*(.+)$').firstMatch(fieldLine);
        if (descrMatch != null) {
          currentDescr = descrMatch.group(1)!.trim();
          continue;
        }

        // 如果遇到非字段行，结束当前条目
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          // 保存当前条目
          if (currentName != null) {
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
          inEntry = false;
          currentName = null;
        }
      }
    }

    // 保存最后一个条目
    if (inEntry && currentName != null) {
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

    return links;
  }

  /// 生成 YAML 文本
  ///
  /// 根据 isCommented 决定是否添加 `# ` 前缀
  static String generateYaml(
    List<FriendLink> links, {
    String entryIndent = '',
    String lineEnding = '\n',
  }) {
    final buffer = StringBuffer();

    void writeLine(String line) {
      buffer.write(line);
      buffer.write(lineEnding);
    }

    for (final link in links) {
      final prefix = link.isCommented ? '# ' : '';

      writeLine('$entryIndent$prefix- name: ${link.name}');
      writeLine('$entryIndent$prefix  link: ${link.link}');
      if (link.avatar.isNotEmpty) {
        writeLine('$entryIndent$prefix  avatar: ${link.avatar}');
      }
      if (link.descr.isNotEmpty) {
        writeLine('$entryIndent$prefix  descr: ${link.descr}');
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

  /// 生成 YAML 文本，并保留已有文件中友链列表前的定义。
  ///
  /// 典型 Hexo/Butterfly 友链文件会在列表前声明 `class_name`、
  /// `class_desc` 和 `link_list`。推送已有文件时只替换友链条目，
  /// 避免把这些主题需要的结构抹掉。
  static String generateYamlPreservingHeader(
    List<FriendLink> links,
    String existingContent,
  ) {
    final template = _extractTemplate(existingContent);
    if (template == null) {
      return generateYamlWithDefaultHeader(
        links,
        lineEnding: _detectLineEnding(existingContent),
      );
    }

    final yaml = generateYaml(
      links,
      entryIndent: template.entryIndent,
      lineEnding: template.lineEnding,
    );
    final header = template.header.trimRight();

    if (header.isEmpty) return yaml;
    if (yaml.isEmpty) return header;
    return '$header${template.lineEnding}$yaml';
  }

  static _FriendLinkYamlTemplate? _extractTemplate(String content) {
    if (content.trim().isEmpty) return null;

    final lineEnding = _detectLineEnding(content);
    final lines = content.split(RegExp(r'\r?\n'));
    final entryRegExp = RegExp(r'^(\s*)#?\s*-\s*name:\s*.+$');
    final linkListRegExp = RegExp(r'^(\s*)link_list:\s*$');

    for (var i = 0; i < lines.length; i++) {
      final linkListMatch = linkListRegExp.firstMatch(lines[i]);
      if (linkListMatch == null) continue;

      for (var j = i + 1; j < lines.length; j++) {
        final entryMatch = entryRegExp.firstMatch(lines[j]);
        if (entryMatch == null) continue;

        return _FriendLinkYamlTemplate(
          header: lines.take(j).join(lineEnding),
          entryIndent: entryMatch.group(1)!,
          lineEnding: lineEnding,
        );
      }

      return _FriendLinkYamlTemplate(
        header: lines.take(i + 1).join(lineEnding),
        entryIndent: '${linkListMatch.group(1)!}  ',
        lineEnding: lineEnding,
      );
    }

    return null;
  }

  static String _detectLineEnding(String content) {
    return content.contains('\r\n') ? '\r\n' : '\n';
  }
}

class _FriendLinkYamlTemplate {
  final String header;
  final String entryIndent;
  final String lineEnding;

  const _FriendLinkYamlTemplate({
    required this.header,
    required this.entryIndent,
    required this.lineEnding,
  });
}
