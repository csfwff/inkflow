import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/models/friend_link.dart';
import 'package:inkflow/services/friend_link_parser.dart';

void main() {
  group('FriendLinkParser.generateYamlWithDefaultHeader', () {
    test('新建友链文件时生成 Hexo 可解析的默认分组', () {
      final result = FriendLinkParser.generateYamlWithDefaultHeader([
        FriendLink(
          name: 'New',
          link: 'https://new.example',
          avatar: 'https://new.example/avatar.png',
          descr: '新的友链',
        ),
      ]);

      expect(result, '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
    - name: New
      link: https://new.example
      avatar: https://new.example/avatar.png
      descr: 新的友链''');
    });
  });

  group('FriendLinkParser.generateYamlPreservingHeader', () {
    test('保留 Butterfly 友链文件顶部定义和列表缩进', () {
      const existing = '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
    - name: Old
      link: https://old.example
''';

      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(
          name: 'New',
          link: 'https://new.example',
          avatar: 'https://new.example/avatar.png',
          descr: '新的友链',
        ),
        FriendLink(
          name: 'Disabled',
          link: 'https://disabled.example',
          isCommented: true,
        ),
      ], existing);

      expect(result, startsWith('- class_name: 友情链接\n'));
      expect(result, contains('  class_desc: 那些人，那些事\n'));
      expect(result, contains('  link_list:\n'));
      expect(result, contains('    - name: New\n'));
      expect(result, contains('      link: https://new.example\n'));
      expect(
        result,
        contains('      avatar: https://new.example/avatar.png\n'),
      );
      expect(result, contains('      descr: 新的友链\n'));
      expect(result, contains('    # - name: Disabled\n'));
      expect(result, contains('    #   link: https://disabled.example'));
      expect(result, isNot(contains('Old')));
    });

    test('已有 link_list 但还没有条目时仍保留顶部定义', () {
      const existing = '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
''';

      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(name: 'New', link: 'https://new.example'),
      ], existing);

      expect(result, '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
    - name: New
      link: https://new.example''');
    });

    test('没有可复用模板时回退为默认分组', () {
      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(name: 'New', link: 'https://new.example'),
      ], 'not a friend link file');

      expect(result, '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
    - name: New
      link: https://new.example''');
    });

    test('已有纯列表时包回默认分组', () {
      const existing = '''
- name: Old
  link: https://old.example
''';

      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(name: 'New', link: 'https://new.example'),
      ], existing);

      expect(result, '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
    - name: New
      link: https://new.example''');
    });
  });
}
