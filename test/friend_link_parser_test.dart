import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/models/friend_link.dart';
import 'package:inkflow/models/settings.dart';
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

    test('已有根级标准字段列表时保留根级结构和字段名', () {
      const existing = '''
- name: Old
  link: https://old.example
''';

      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(name: 'New', link: 'https://new.example'),
      ], existing);

      expect(result, '''
- name: New
  link: https://new.example''');
    });

    test('根级标准字段缺少可选字段时仍沿用标准字段名', () {
      const existing = '''
- name: Old
  link: https://old.example
''';

      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(
          name: 'New',
          link: 'https://new.example',
          avatar: 'https://new.example/avatar.png',
          descr: 'New description',
        ),
      ], existing);

      expect(result, '''
- name: New
  link: https://new.example
  avatar: https://new.example/avatar.png
  descr: New description''');
    });

    test('保留扁平格式及 url、desc、image 字段名', () {
      const existing = '''
- name: Old
  url: https://old.example
  desc: Old description
  image: https://old.example/avatar.png
''';

      final result = FriendLinkParser.generateYamlPreservingHeader([
        FriendLink(
          name: 'New',
          link: 'https://new.example',
          avatar: 'https://new.example/avatar.png',
          descr: 'New description',
        ),
      ], existing);

      expect(result, '''
- name: New
  url: https://new.example
  desc: New description
  image: https://new.example/avatar.png''');
    });
  });

  group('FriendLinkParser.parseYaml', () {
    test('解析扁平格式的字段别名', () {
      const yaml = '''
- name: 零糖加辣（drda）
  url: https://drda-x.github.io/drda-blog/
  desc: 奶茶少糖，喜欢吃辣
  image: https://drda-x.github.io/drda-blog/avatar/avatar.webp
''';

      final links = FriendLinkParser.parseYaml(yaml);

      expect(links, hasLength(1));
      expect(links.single.name, '零糖加辣（drda）');
      expect(links.single.link, 'https://drda-x.github.io/drda-blog/');
      expect(links.single.descr, '奶茶少糖，喜欢吃辣');
      expect(
        links.single.avatar,
        'https://drda-x.github.io/drda-blog/avatar/avatar.webp',
      );
    });
  });

  group('FriendLinkParser.generateYamlForFormat', () {
    test('新建扁平格式文件使用 url、desc、image 字段', () {
      final result = FriendLinkParser.generateYamlForFormat([
        FriendLink(
          name: 'New',
          link: 'https://new.example',
          avatar: 'https://new.example/avatar.png',
          descr: 'New description',
        ),
      ], FriendLinkFileFormat.flat);

      expect(result, '''
- name: New
  url: https://new.example
  desc: New description
  image: https://new.example/avatar.png''');
    });
  });

  group('FriendLinkParser.validateWritableContent', () {
    test('接受两种受支持的格式', () {
      const butterfly = '''
- class_name: 友情链接
  class_desc: 那些人，那些事
  link_list:
    - name: Old
      link: https://old.example
''';
      const flat = '''
- name: Old
  url: https://old.example
  desc: Old description
  image: https://old.example/avatar.png
''';

      expect(FriendLinkParser.validateWritableContent(butterfly), isNull);
      expect(FriendLinkParser.validateWritableContent(flat), isNull);
    });

    test('拒绝多个 link_list 分组，避免推送时覆盖其他分组', () {
      const yaml = '''
- class_name: Group A
  link_list:
    - name: A
      link: https://a.example
- class_name: Group B
  link_list:
    - name: B
      link: https://b.example
''';

      expect(
        FriendLinkParser.validateWritableContent(yaml),
        contains('多个 link_list'),
      );
    });

    test('拒绝条目中的自定义字段，避免推送时丢失', () {
      const yaml = '''
- name: Old
  url: https://old.example
  color: blue
''';

      expect(FriendLinkParser.validateWritableContent(yaml), contains('color'));
    });
  });
}
