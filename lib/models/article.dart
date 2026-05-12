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
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [],
        categories = categories ?? [];

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
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
      categories: (map['categories'] as String?)?.split(',').where((c) => c.isNotEmpty).toList() ?? [],
      permalink: map['permalink'] as String?,
      topImg: map['topImg'] as String?,
      cover: map['cover'] as String?,
      layout: map['layout'] as String?,
      comments: map['comments'] == 1,
      published: map['published'] == 1,
      excerpt: map['excerpt'] as String?,
      description: map['description'] as String?,
      author: map['author'] as String?,
    );
  }

  String buildFrontmatter() {
    final buffer = StringBuffer('---\n');
    buffer.writeln('title: $title');
    buffer.writeln('date: ${_formatDateTime(date)}');

    if (tags.isNotEmpty) {
      buffer.writeln('tags: [${tags.join(', ')}]');
    }

    if (categories.isNotEmpty) {
      buffer.writeln('categories:');
      for (final cat in categories) {
        buffer.writeln('  - $cat');
      }
    }

    if (permalink != null && permalink!.isNotEmpty) {
      buffer.writeln('permalink: $permalink');
    }

    if (topImg != null && topImg!.isNotEmpty) {
      buffer.writeln('top_img: $topImg');
    }

    if (cover != null && cover!.isNotEmpty) {
      buffer.writeln('cover: $cover');
    }

    if (layout != null && layout!.isNotEmpty) {
      buffer.writeln('layout: $layout');
    }

    if (comments == false) {
      buffer.writeln('comments: false');
    }

    if (published == false) {
      buffer.writeln('published: false');
    }

    if (excerpt != null && excerpt!.isNotEmpty) {
      buffer.writeln('excerpt: $excerpt');
    }

    if (description != null && description!.isNotEmpty) {
      buffer.writeln('description: $description');
    }

    if (author != null && author!.isNotEmpty) {
      buffer.writeln('author: $author');
    }

    buffer.write('---\n');
    return buffer.toString();
  }

  String get fullContent => buildFrontmatter() + content;

  static String _formatDateTime(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }
}
