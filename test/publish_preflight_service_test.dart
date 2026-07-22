import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/services/publish_preflight_service.dart';

void main() {
  test('空标题和正文会阻止发布', () {
    final issues = PublishPreflightService.check(title: ' ', body: ' ');

    expect(
      issues.where((issue) => issue.severity == PublishIssueSeverity.error),
      hasLength(2),
    );
    expect(
      issues.map((issue) => issue.code),
      containsAll([PublishIssueCode.emptyTitle, PublishIssueCode.emptyBody]),
    );
  });

  test('识别空链接、异常链接和未闭合代码块', () {
    const body = '''[empty]()
[bad](https://example .com)
```
code
''';

    final issues = PublishPreflightService.check(title: 'Post', body: body);

    expect(
      issues.map((issue) => issue.code),
      containsAll([
        PublishIssueCode.emptyLinkTarget,
        PublishIssueCode.malformedLink,
        PublishIssueCode.unclosedCodeFence,
      ]),
    );
  });

  test('正常 Markdown 无问题', () {
    final issues = PublishPreflightService.check(
      title: 'Post',
      body: '# Hello\n\n[Link](https://example.com)',
    );

    expect(issues, isEmpty);
  });
}
