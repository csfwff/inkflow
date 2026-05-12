enum ArticleStatus { draft, synced, repoDraft }

class Article {
  final int? id;
  String title;
  String content;
  DateTime date;
  String slug;
  ArticleStatus status;
  String filePath;
  String? githubSha;
  DateTime createdAt;
  DateTime updatedAt;

  Article({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.slug,
    this.status = ArticleStatus.draft,
    this.filePath = '',
    this.githubSha,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'slug': slug,
      'status': status.index,
      'filePath': filePath,
      'githubSha': githubSha,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      date: DateTime.parse(map['date'] as String),
      slug: map['slug'] as String,
      status: ArticleStatus.values[map['status'] as int],
      filePath: map['filePath'] as String? ?? '',
      githubSha: map['githubSha'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String buildFrontmatter() {
    return '---\ntitle: $title\ndate: ${_formatDateTime(date)}\n---\n';
  }

  String get fullContent => buildFrontmatter() + content;

  static String _formatDateTime(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }
}
