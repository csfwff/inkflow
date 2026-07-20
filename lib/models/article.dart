import '../services/frontmatter_helper.dart';

enum ArticleStatus { draft, synced, repoDraft, pendingPublish, remoteDeleted }

enum ArticleRemoteKind { post, repoDraft }

class Article {
  final int? id;
  String title;
  String content;
  DateTime date;
  String slug;
  ArticleStatus status;
  String filePath;
  String? remotePath;
  ArticleRemoteKind? remoteKind;
  String? githubSha;
  DateTime createdAt;
  DateTime updatedAt;

  // Hexo 元数据
  List<String> tags;
  List<String> categories;
  String? permalink;
  String? topImg;
  String? cover;
  String? excerpt;
  String? description;
  String? author;

  /// 自定义元数据字段（非内置字段）
  Map<String, String> customFields;

  Article({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.slug,
    this.status = ArticleStatus.draft,
    this.filePath = '',
    this.remotePath,
    this.remoteKind,
    this.githubSha,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    List<String>? categories,
    this.permalink,
    this.topImg,
    this.cover,
    this.excerpt,
    this.description,
    this.author,
    Map<String, String>? customFields,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [],
        categories = categories ?? [],
        customFields = customFields ?? {};

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'slug': slug,
      'status': status.index,
      'filePath': filePath,
      'remotePath': remotePath,
      'remoteKind': remoteKind?.index,
      'githubSha': githubSha,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags.join(','),
      'categories': categories.join(','),
      'permalink': permalink,
      'topImg': topImg,
      'cover': cover,
      'excerpt': excerpt,
      'description': description,
      'author': author,
      'customFields': customFields,
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
      remotePath: map['remotePath'] as String?,
      remoteKind: map['remoteKind'] == null
          ? null
          : ArticleRemoteKind.values[map['remoteKind'] as int],
      githubSha: map['githubSha'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      tags: (map['tags'] as String?)
              ?.split(',')
              .where((t) => t.isNotEmpty)
              .toList() ??
          [],
      categories: (map['categories'] as String?)
              ?.split(',')
              .where((c) => c.isNotEmpty)
              .toList() ??
          [],
      permalink: map['permalink'] as String?,
      topImg: map['topImg'] as String?,
      cover: map['cover'] as String?,
      excerpt: map['excerpt'] as String?,
      description: map['description'] as String?,
      author: map['author'] as String?,
      customFields: map['customFields'] is Map
          ? (map['customFields'] as Map).map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : {},
    );
  }

  static String buildRemotePath({
    required ArticleRemoteKind kind,
    required String filePath,
  }) {
    final dir = switch (kind) {
      ArticleRemoteKind.post => 'source/_posts',
      ArticleRemoteKind.repoDraft => 'source/_drafts',
    };
    final cleanFilePath = normalizeRelativeFilePath(filePath);
    return cleanFilePath.isEmpty ? dir : '$dir/$cleanFilePath';
  }

  /// 根据“文章目录格式”生成相对于 `source/_posts` 或 `source/_drafts`
  /// 的文章路径。目录格式可留空，此时文章直接保存在目录根部。
  static String buildArticleFilePath({
    required String directoryPattern,
    required DateTime date,
    required String slug,
    String category = '',
  }) {
    final directory = directoryPattern
        .replaceAll('{year}', '${date.year}')
        .replaceAll('{month}', date.month.toString().padLeft(2, '0'))
        .replaceAll('{day}', date.day.toString().padLeft(2, '0'))
        .replaceAll('{category}', category)
        .replaceAll('{slug}', slug)
        .replaceAll('{timestamp}', '${date.millisecondsSinceEpoch ~/ 1000}');
    final cleanDirectory = normalizeRelativeFilePath(directory);
    final filename = '${slug.trim()}.md';
    return cleanDirectory.isEmpty ? filename : '$cleanDirectory/$filename';
  }

  /// GitHub 文件路径始终使用相对路径；兼容旧数据和用户输入中的多余斜杠。
  static String normalizeRelativeFilePath(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .replaceAll(RegExp(r'/+'), '/');
  }

  String buildFrontmatter() {
    return FrontmatterHelper.generate({
      'title': title,
      'date': _formatDateTime(date),
      if (tags.isNotEmpty) 'tags': tags,
      if (categories.isNotEmpty) 'categories': categories,
      if (permalink != null && permalink!.isNotEmpty) 'permalink': permalink,
      if (topImg != null && topImg!.isNotEmpty) 'top_img': topImg,
      if (cover != null && cover!.isNotEmpty) 'cover': cover,
      if (excerpt != null && excerpt!.isNotEmpty) 'excerpt': excerpt,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (author != null && author!.isNotEmpty) 'author': author,
      ...customFields,
    });
  }

  String get fullContent => updateFrontmatter();

  /// 去掉 frontmatter，只返回正文
  String get bodyContent => FrontmatterHelper.extractBody(content);

  /// 更新已有 frontmatter 中支持的字段，保留不支持的字段。
  /// 如果没有 frontmatter，则新建。
  String updateFrontmatter() {
    return FrontmatterHelper.updateFrontmatter(content, {
      'title': title,
      'date': _formatDateTime(date),
      'tags': tags,
      'categories': categories,
      'permalink': permalink,
      'top_img': topImg,
      'cover': cover,
      'excerpt': excerpt,
      'description': description,
      'author': author,
      ...customFields,
    });
  }

  static String _formatDateTime(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }
}
