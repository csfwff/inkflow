enum PublishIssueSeverity { error, warning }

enum PublishIssueCode {
  emptyTitle,
  emptyBody,
  emptyLinkTarget,
  malformedLink,
  unclosedCodeFence,
}

class PublishIssue {
  final PublishIssueSeverity severity;
  final PublishIssueCode code;
  final String? detail;

  const PublishIssue({required this.severity, required this.code, this.detail});
}

/// Fast local checks before a network publish request.
class PublishPreflightService {
  PublishPreflightService._();

  static List<PublishIssue> check({
    required String title,
    required String body,
  }) {
    final issues = <PublishIssue>[];
    if (title.trim().isEmpty) {
      issues.add(
        const PublishIssue(
          severity: PublishIssueSeverity.error,
          code: PublishIssueCode.emptyTitle,
        ),
      );
    }
    if (body.trim().isEmpty) {
      issues.add(
        const PublishIssue(
          severity: PublishIssueSeverity.error,
          code: PublishIssueCode.emptyBody,
        ),
      );
    }

    final linkPattern = RegExp(r'!?\[[^\]]*\]\(([^\n)]*)\)');
    for (final match in linkPattern.allMatches(body)) {
      final target = match.group(1)?.trim() ?? '';
      if (target.isEmpty) {
        issues.add(
          const PublishIssue(
            severity: PublishIssueSeverity.warning,
            code: PublishIssueCode.emptyLinkTarget,
          ),
        );
      } else if (target.contains(RegExp(r'\s')) ||
          Uri.tryParse(target) == null) {
        issues.add(
          PublishIssue(
            severity: PublishIssueSeverity.warning,
            code: PublishIssueCode.malformedLink,
            detail: target,
          ),
        );
      }
    }

    final fences = RegExp(r'(^|\n)\s*(```|~~~)').allMatches(body).length;
    if (fences.isOdd) {
      issues.add(
        const PublishIssue(
          severity: PublishIssueSeverity.warning,
          code: PublishIssueCode.unclosedCodeFence,
        ),
      );
    }
    return issues;
  }
}
