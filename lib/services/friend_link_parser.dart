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
          links.add(FriendLink(
            name: currentName,
            link: currentLink ?? '',
            avatar: currentAvatar,
            descr: currentDescr,
            isCommented: currentCommented,
          ));
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
            links.add(FriendLink(
              name: currentName,
              link: currentLink ?? '',
              avatar: currentAvatar,
              descr: currentDescr,
              isCommented: currentCommented,
            ));
          }
          inEntry = false;
          currentName = null;
        }
      }
    }

    // 保存最后一个条目
    if (inEntry && currentName != null) {
      links.add(FriendLink(
        name: currentName,
        link: currentLink ?? '',
        avatar: currentAvatar,
        descr: currentDescr,
        isCommented: currentCommented,
      ));
    }

    return links;
  }

  /// 生成 YAML 文本
  ///
  /// 根据 isCommented 决定是否添加 `# ` 前缀
  static String generateYaml(List<FriendLink> links) {
    final buffer = StringBuffer();

    for (final link in links) {
      final prefix = link.isCommented ? '# ' : '';

      buffer.writeln('$prefix- name: ${link.name}');
      buffer.writeln('$prefix  link: ${link.link}');
      if (link.avatar.isNotEmpty) {
        buffer.writeln('$prefix  avatar: ${link.avatar}');
      }
      if (link.descr.isNotEmpty) {
        buffer.writeln('$prefix  descr: ${link.descr}');
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }
}
