import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/models/article.dart';

void main() {
  group('Article.buildArticleFilePath', () {
    test('目录格式留空时文件保存到文章根目录', () {
      expect(
        Article.buildArticleFilePath(
          directoryPattern: '',
          date: DateTime(2026, 7, 20),
          slug: 'hello-world',
        ),
        'hello-world.md',
      );
    });

    test('目录格式的首尾和重复斜杠会被规范化', () {
      expect(
        Article.buildArticleFilePath(
          directoryPattern: '/{year}//{month}/',
          date: DateTime(2026, 7, 20),
          slug: 'hello-world',
        ),
        '2026/07/hello-world.md',
      );
    });
  });

  test('远程路径兼容 filePath 中多余的首尾斜杠', () {
    expect(
      Article.buildRemotePath(
        kind: ArticleRemoteKind.post,
        filePath: '/2026//06/hello.md/',
      ),
      'source/_posts/2026/06/hello.md',
    );
  });
}
