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
  String? layout;
  bool? comments;
  bool? published;
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
    this.layout,
    this.comments,
    this.published,
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
      'layout': layout,
      'comments': comments == true ? 1 : 0,
      'published': published == true ? 1 : 0,
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
      layout: map['layout'] as String?,
      comments: map['comments'] == 1,
      published: map['published'] == 1,
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
    return '$dir/$filePath';
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
      if (layout != null && layout!.isNotEmpty) 'layout': layout,
      // comments / published 不主动写入：源数据没有时不应凭空添加。
      // （已有的 comments/published 行由 updateFrontmatter 原样保留）
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
      'layout': layout,
      // comments / published 不主动写入（见 buildFrontmatter 注释）
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
