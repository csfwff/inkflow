// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ArticleRowsTable extends ArticleRows
    with TableInfo<$ArticleRowsTable, ArticleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
      'slug', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<ArticleStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ArticleStatus>($ArticleRowsTable.$converterstatus);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _githubShaMeta =
      const VerificationMeta('githubSha');
  @override
  late final GeneratedColumn<String> githubSha = GeneratedColumn<String>(
      'github_sha', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _categoriesMeta =
      const VerificationMeta('categories');
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
      'categories', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _permalinkMeta =
      const VerificationMeta('permalink');
  @override
  late final GeneratedColumn<String> permalink = GeneratedColumn<String>(
      'permalink', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _topImgMeta = const VerificationMeta('topImg');
  @override
  late final GeneratedColumn<String> topImg = GeneratedColumn<String>(
      'top_img', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
      'cover', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
      'layout', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _commentsMeta =
      const VerificationMeta('comments');
  @override
  late final GeneratedColumn<int> comments = GeneratedColumn<int>(
      'comments', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _publishedMeta =
      const VerificationMeta('published');
  @override
  late final GeneratedColumn<int> published = GeneratedColumn<int>(
      'published', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _excerptMeta =
      const VerificationMeta('excerpt');
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
      'excerpt', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
      'author', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        content,
        date,
        slug,
        status,
        filePath,
        githubSha,
        createdAt,
        updatedAt,
        tags,
        categories,
        permalink,
        topImg,
        cover,
        layout,
        comments,
        published,
        excerpt,
        description,
        author
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_rows';
  @override
  VerificationContext validateIntegrity(Insertable<ArticleRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
          _slugMeta, slug.isAcceptableOrUnknown(data['slug']!, _slugMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    }
    if (data.containsKey('github_sha')) {
      context.handle(_githubShaMeta,
          githubSha.isAcceptableOrUnknown(data['github_sha']!, _githubShaMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('categories')) {
      context.handle(
          _categoriesMeta,
          categories.isAcceptableOrUnknown(
              data['categories']!, _categoriesMeta));
    }
    if (data.containsKey('permalink')) {
      context.handle(_permalinkMeta,
          permalink.isAcceptableOrUnknown(data['permalink']!, _permalinkMeta));
    }
    if (data.containsKey('top_img')) {
      context.handle(_topImgMeta,
          topImg.isAcceptableOrUnknown(data['top_img']!, _topImgMeta));
    }
    if (data.containsKey('cover')) {
      context.handle(
          _coverMeta, cover.isAcceptableOrUnknown(data['cover']!, _coverMeta));
    }
    if (data.containsKey('layout')) {
      context.handle(_layoutMeta,
          layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta));
    }
    if (data.containsKey('comments')) {
      context.handle(_commentsMeta,
          comments.isAcceptableOrUnknown(data['comments']!, _commentsMeta));
    }
    if (data.containsKey('published')) {
      context.handle(_publishedMeta,
          published.isAcceptableOrUnknown(data['published']!, _publishedMeta));
    }
    if (data.containsKey('excerpt')) {
      context.handle(_excerptMeta,
          excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('author')) {
      context.handle(_authorMeta,
          author.isAcceptableOrUnknown(data['author']!, _authorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      slug: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}slug'])!,
      status: $ArticleRowsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      githubSha: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}github_sha']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      categories: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categories'])!,
      permalink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}permalink']),
      topImg: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}top_img']),
      cover: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover']),
      layout: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}layout']),
      comments: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comments'])!,
      published: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}published'])!,
      excerpt: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}excerpt']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      author: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}author']),
    );
  }

  @override
  $ArticleRowsTable createAlias(String alias) {
    return $ArticleRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ArticleStatus, int, int> $converterstatus =
      const EnumIndexConverter<ArticleStatus>(ArticleStatus.values);
}

class ArticleRow extends DataClass implements Insertable<ArticleRow> {
  final int id;
  final String title;
  final String content;
  final String date;
  final String slug;
  final ArticleStatus status;
  final String filePath;
  final String? githubSha;
  final String createdAt;
  final String updatedAt;
  final String tags;
  final String categories;
  final String? permalink;
  final String? topImg;
  final String? cover;
  final String? layout;
  final int comments;
  final int published;
  final String? excerpt;
  final String? description;
  final String? author;
  const ArticleRow(
      {required this.id,
      required this.title,
      required this.content,
      required this.date,
      required this.slug,
      required this.status,
      required this.filePath,
      this.githubSha,
      required this.createdAt,
      required this.updatedAt,
      required this.tags,
      required this.categories,
      this.permalink,
      this.topImg,
      this.cover,
      this.layout,
      required this.comments,
      required this.published,
      this.excerpt,
      this.description,
      this.author});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['date'] = Variable<String>(date);
    map['slug'] = Variable<String>(slug);
    {
      map['status'] =
          Variable<int>($ArticleRowsTable.$converterstatus.toSql(status));
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || githubSha != null) {
      map['github_sha'] = Variable<String>(githubSha);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['tags'] = Variable<String>(tags);
    map['categories'] = Variable<String>(categories);
    if (!nullToAbsent || permalink != null) {
      map['permalink'] = Variable<String>(permalink);
    }
    if (!nullToAbsent || topImg != null) {
      map['top_img'] = Variable<String>(topImg);
    }
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || layout != null) {
      map['layout'] = Variable<String>(layout);
    }
    map['comments'] = Variable<int>(comments);
    map['published'] = Variable<int>(published);
    if (!nullToAbsent || excerpt != null) {
      map['excerpt'] = Variable<String>(excerpt);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    return map;
  }

  ArticleRowsCompanion toCompanion(bool nullToAbsent) {
    return ArticleRowsCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      date: Value(date),
      slug: Value(slug),
      status: Value(status),
      filePath: Value(filePath),
      githubSha: githubSha == null && nullToAbsent
          ? const Value.absent()
          : Value(githubSha),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      tags: Value(tags),
      categories: Value(categories),
      permalink: permalink == null && nullToAbsent
          ? const Value.absent()
          : Value(permalink),
      topImg:
          topImg == null && nullToAbsent ? const Value.absent() : Value(topImg),
      cover:
          cover == null && nullToAbsent ? const Value.absent() : Value(cover),
      layout:
          layout == null && nullToAbsent ? const Value.absent() : Value(layout),
      comments: Value(comments),
      published: Value(published),
      excerpt: excerpt == null && nullToAbsent
          ? const Value.absent()
          : Value(excerpt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      author:
          author == null && nullToAbsent ? const Value.absent() : Value(author),
    );
  }

  factory ArticleRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      date: serializer.fromJson<String>(json['date']),
      slug: serializer.fromJson<String>(json['slug']),
      status: $ArticleRowsTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      filePath: serializer.fromJson<String>(json['filePath']),
      githubSha: serializer.fromJson<String?>(json['githubSha']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      tags: serializer.fromJson<String>(json['tags']),
      categories: serializer.fromJson<String>(json['categories']),
      permalink: serializer.fromJson<String?>(json['permalink']),
      topImg: serializer.fromJson<String?>(json['topImg']),
      cover: serializer.fromJson<String?>(json['cover']),
      layout: serializer.fromJson<String?>(json['layout']),
      comments: serializer.fromJson<int>(json['comments']),
      published: serializer.fromJson<int>(json['published']),
      excerpt: serializer.fromJson<String?>(json['excerpt']),
      description: serializer.fromJson<String?>(json['description']),
      author: serializer.fromJson<String?>(json['author']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'date': serializer.toJson<String>(date),
      'slug': serializer.toJson<String>(slug),
      'status': serializer
          .toJson<int>($ArticleRowsTable.$converterstatus.toJson(status)),
      'filePath': serializer.toJson<String>(filePath),
      'githubSha': serializer.toJson<String?>(githubSha),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'tags': serializer.toJson<String>(tags),
      'categories': serializer.toJson<String>(categories),
      'permalink': serializer.toJson<String?>(permalink),
      'topImg': serializer.toJson<String?>(topImg),
      'cover': serializer.toJson<String?>(cover),
      'layout': serializer.toJson<String?>(layout),
      'comments': serializer.toJson<int>(comments),
      'published': serializer.toJson<int>(published),
      'excerpt': serializer.toJson<String?>(excerpt),
      'description': serializer.toJson<String?>(description),
      'author': serializer.toJson<String?>(author),
    };
  }

  ArticleRow copyWith(
          {int? id,
          String? title,
          String? content,
          String? date,
          String? slug,
          ArticleStatus? status,
          String? filePath,
          Value<String?> githubSha = const Value.absent(),
          String? createdAt,
          String? updatedAt,
          String? tags,
          String? categories,
          Value<String?> permalink = const Value.absent(),
          Value<String?> topImg = const Value.absent(),
          Value<String?> cover = const Value.absent(),
          Value<String?> layout = const Value.absent(),
          int? comments,
          int? published,
          Value<String?> excerpt = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> author = const Value.absent()}) =>
      ArticleRow(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        date: date ?? this.date,
        slug: slug ?? this.slug,
        status: status ?? this.status,
        filePath: filePath ?? this.filePath,
        githubSha: githubSha.present ? githubSha.value : this.githubSha,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        tags: tags ?? this.tags,
        categories: categories ?? this.categories,
        permalink: permalink.present ? permalink.value : this.permalink,
        topImg: topImg.present ? topImg.value : this.topImg,
        cover: cover.present ? cover.value : this.cover,
        layout: layout.present ? layout.value : this.layout,
        comments: comments ?? this.comments,
        published: published ?? this.published,
        excerpt: excerpt.present ? excerpt.value : this.excerpt,
        description: description.present ? description.value : this.description,
        author: author.present ? author.value : this.author,
      );
  ArticleRow copyWithCompanion(ArticleRowsCompanion data) {
    return ArticleRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      date: data.date.present ? data.date.value : this.date,
      slug: data.slug.present ? data.slug.value : this.slug,
      status: data.status.present ? data.status.value : this.status,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      githubSha: data.githubSha.present ? data.githubSha.value : this.githubSha,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      categories:
          data.categories.present ? data.categories.value : this.categories,
      permalink: data.permalink.present ? data.permalink.value : this.permalink,
      topImg: data.topImg.present ? data.topImg.value : this.topImg,
      cover: data.cover.present ? data.cover.value : this.cover,
      layout: data.layout.present ? data.layout.value : this.layout,
      comments: data.comments.present ? data.comments.value : this.comments,
      published: data.published.present ? data.published.value : this.published,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      description:
          data.description.present ? data.description.value : this.description,
      author: data.author.present ? data.author.value : this.author,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('date: $date, ')
          ..write('slug: $slug, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('githubSha: $githubSha, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('categories: $categories, ')
          ..write('permalink: $permalink, ')
          ..write('topImg: $topImg, ')
          ..write('cover: $cover, ')
          ..write('layout: $layout, ')
          ..write('comments: $comments, ')
          ..write('published: $published, ')
          ..write('excerpt: $excerpt, ')
          ..write('description: $description, ')
          ..write('author: $author')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        content,
        date,
        slug,
        status,
        filePath,
        githubSha,
        createdAt,
        updatedAt,
        tags,
        categories,
        permalink,
        topImg,
        cover,
        layout,
        comments,
        published,
        excerpt,
        description,
        author
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.date == this.date &&
          other.slug == this.slug &&
          other.status == this.status &&
          other.filePath == this.filePath &&
          other.githubSha == this.githubSha &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tags == this.tags &&
          other.categories == this.categories &&
          other.permalink == this.permalink &&
          other.topImg == this.topImg &&
          other.cover == this.cover &&
          other.layout == this.layout &&
          other.comments == this.comments &&
          other.published == this.published &&
          other.excerpt == this.excerpt &&
          other.description == this.description &&
          other.author == this.author);
}

class ArticleRowsCompanion extends UpdateCompanion<ArticleRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> date;
  final Value<String> slug;
  final Value<ArticleStatus> status;
  final Value<String> filePath;
  final Value<String?> githubSha;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> tags;
  final Value<String> categories;
  final Value<String?> permalink;
  final Value<String?> topImg;
  final Value<String?> cover;
  final Value<String?> layout;
  final Value<int> comments;
  final Value<int> published;
  final Value<String?> excerpt;
  final Value<String?> description;
  final Value<String?> author;
  const ArticleRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.date = const Value.absent(),
    this.slug = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.githubSha = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.categories = const Value.absent(),
    this.permalink = const Value.absent(),
    this.topImg = const Value.absent(),
    this.cover = const Value.absent(),
    this.layout = const Value.absent(),
    this.comments = const Value.absent(),
    this.published = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
  });
  ArticleRowsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    required String date,
    this.slug = const Value.absent(),
    required ArticleStatus status,
    this.filePath = const Value.absent(),
    this.githubSha = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.tags = const Value.absent(),
    this.categories = const Value.absent(),
    this.permalink = const Value.absent(),
    this.topImg = const Value.absent(),
    this.cover = const Value.absent(),
    this.layout = const Value.absent(),
    this.comments = const Value.absent(),
    this.published = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
  })  : date = Value(date),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ArticleRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? date,
    Expression<String>? slug,
    Expression<int>? status,
    Expression<String>? filePath,
    Expression<String>? githubSha,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? tags,
    Expression<String>? categories,
    Expression<String>? permalink,
    Expression<String>? topImg,
    Expression<String>? cover,
    Expression<String>? layout,
    Expression<int>? comments,
    Expression<int>? published,
    Expression<String>? excerpt,
    Expression<String>? description,
    Expression<String>? author,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (date != null) 'date': date,
      if (slug != null) 'slug': slug,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (githubSha != null) 'github_sha': githubSha,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tags != null) 'tags': tags,
      if (categories != null) 'categories': categories,
      if (permalink != null) 'permalink': permalink,
      if (topImg != null) 'top_img': topImg,
      if (cover != null) 'cover': cover,
      if (layout != null) 'layout': layout,
      if (comments != null) 'comments': comments,
      if (published != null) 'published': published,
      if (excerpt != null) 'excerpt': excerpt,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
    });
  }

  ArticleRowsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? content,
      Value<String>? date,
      Value<String>? slug,
      Value<ArticleStatus>? status,
      Value<String>? filePath,
      Value<String?>? githubSha,
      Value<String>? createdAt,
      Value<String>? updatedAt,
      Value<String>? tags,
      Value<String>? categories,
      Value<String?>? permalink,
      Value<String?>? topImg,
      Value<String?>? cover,
      Value<String?>? layout,
      Value<int>? comments,
      Value<int>? published,
      Value<String?>? excerpt,
      Value<String?>? description,
      Value<String?>? author}) {
    return ArticleRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      githubSha: githubSha ?? this.githubSha,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      permalink: permalink ?? this.permalink,
      topImg: topImg ?? this.topImg,
      cover: cover ?? this.cover,
      layout: layout ?? this.layout,
      comments: comments ?? this.comments,
      published: published ?? this.published,
      excerpt: excerpt ?? this.excerpt,
      description: description ?? this.description,
      author: author ?? this.author,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (status.present) {
      map['status'] =
          Variable<int>($ArticleRowsTable.$converterstatus.toSql(status.value));
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (githubSha.present) {
      map['github_sha'] = Variable<String>(githubSha.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (permalink.present) {
      map['permalink'] = Variable<String>(permalink.value);
    }
    if (topImg.present) {
      map['top_img'] = Variable<String>(topImg.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (comments.present) {
      map['comments'] = Variable<int>(comments.value);
    }
    if (published.present) {
      map['published'] = Variable<int>(published.value);
    }
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticleRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('date: $date, ')
          ..write('slug: $slug, ')
          ..write('status: $status, ')
          ..write('filePath: $filePath, ')
          ..write('githubSha: $githubSha, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('categories: $categories, ')
          ..write('permalink: $permalink, ')
          ..write('topImg: $topImg, ')
          ..write('cover: $cover, ')
          ..write('layout: $layout, ')
          ..write('comments: $comments, ')
          ..write('published: $published, ')
          ..write('excerpt: $excerpt, ')
          ..write('description: $description, ')
          ..write('author: $author')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArticleRowsTable articleRows = $ArticleRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [articleRows];
}

typedef $$ArticleRowsTableCreateCompanionBuilder = ArticleRowsCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  required String date,
  Value<String> slug,
  required ArticleStatus status,
  Value<String> filePath,
  Value<String?> githubSha,
  required String createdAt,
  required String updatedAt,
  Value<String> tags,
  Value<String> categories,
  Value<String?> permalink,
  Value<String?> topImg,
  Value<String?> cover,
  Value<String?> layout,
  Value<int> comments,
  Value<int> published,
  Value<String?> excerpt,
  Value<String?> description,
  Value<String?> author,
});
typedef $$ArticleRowsTableUpdateCompanionBuilder = ArticleRowsCompanion
    Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  Value<String> date,
  Value<String> slug,
  Value<ArticleStatus> status,
  Value<String> filePath,
  Value<String?> githubSha,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String> tags,
  Value<String> categories,
  Value<String?> permalink,
  Value<String?> topImg,
  Value<String?> cover,
  Value<String?> layout,
  Value<int> comments,
  Value<int> published,
  Value<String?> excerpt,
  Value<String?> description,
  Value<String?> author,
});

class $$ArticleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ArticleRowsTable> {
  $$ArticleRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ArticleStatus, ArticleStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get githubSha => $composableBuilder(
      column: $table.githubSha, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categories => $composableBuilder(
      column: $table.categories, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permalink => $composableBuilder(
      column: $table.permalink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get topImg => $composableBuilder(
      column: $table.topImg, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cover => $composableBuilder(
      column: $table.cover, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get layout => $composableBuilder(
      column: $table.layout, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get comments => $composableBuilder(
      column: $table.comments, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get published => $composableBuilder(
      column: $table.published, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get excerpt => $composableBuilder(
      column: $table.excerpt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnFilters(column));
}

class $$ArticleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticleRowsTable> {
  $$ArticleRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get slug => $composableBuilder(
      column: $table.slug, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get githubSha => $composableBuilder(
      column: $table.githubSha, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categories => $composableBuilder(
      column: $table.categories, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permalink => $composableBuilder(
      column: $table.permalink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get topImg => $composableBuilder(
      column: $table.topImg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cover => $composableBuilder(
      column: $table.cover, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get layout => $composableBuilder(
      column: $table.layout, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get comments => $composableBuilder(
      column: $table.comments, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get published => $composableBuilder(
      column: $table.published, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get excerpt => $composableBuilder(
      column: $table.excerpt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get author => $composableBuilder(
      column: $table.author, builder: (column) => ColumnOrderings(column));
}

class $$ArticleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticleRowsTable> {
  $$ArticleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ArticleStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get githubSha =>
      $composableBuilder(column: $table.githubSha, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
      column: $table.categories, builder: (column) => column);

  GeneratedColumn<String> get permalink =>
      $composableBuilder(column: $table.permalink, builder: (column) => column);

  GeneratedColumn<String> get topImg =>
      $composableBuilder(column: $table.topImg, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<int> get comments =>
      $composableBuilder(column: $table.comments, builder: (column) => column);

  GeneratedColumn<int> get published =>
      $composableBuilder(column: $table.published, builder: (column) => column);

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);
}

class $$ArticleRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ArticleRowsTable,
    ArticleRow,
    $$ArticleRowsTableFilterComposer,
    $$ArticleRowsTableOrderingComposer,
    $$ArticleRowsTableAnnotationComposer,
    $$ArticleRowsTableCreateCompanionBuilder,
    $$ArticleRowsTableUpdateCompanionBuilder,
    (ArticleRow, BaseReferences<_$AppDatabase, $ArticleRowsTable, ArticleRow>),
    ArticleRow,
    PrefetchHooks Function()> {
  $$ArticleRowsTableTableManager(_$AppDatabase db, $ArticleRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticleRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticleRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticleRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String> slug = const Value.absent(),
            Value<ArticleStatus> status = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String?> githubSha = const Value.absent(),
            Value<String> createdAt = const Value.absent(),
            Value<String> updatedAt = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> categories = const Value.absent(),
            Value<String?> permalink = const Value.absent(),
            Value<String?> topImg = const Value.absent(),
            Value<String?> cover = const Value.absent(),
            Value<String?> layout = const Value.absent(),
            Value<int> comments = const Value.absent(),
            Value<int> published = const Value.absent(),
            Value<String?> excerpt = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> author = const Value.absent(),
          }) =>
              ArticleRowsCompanion(
            id: id,
            title: title,
            content: content,
            date: date,
            slug: slug,
            status: status,
            filePath: filePath,
            githubSha: githubSha,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            categories: categories,
            permalink: permalink,
            topImg: topImg,
            cover: cover,
            layout: layout,
            comments: comments,
            published: published,
            excerpt: excerpt,
            description: description,
            author: author,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> content = const Value.absent(),
            required String date,
            Value<String> slug = const Value.absent(),
            required ArticleStatus status,
            Value<String> filePath = const Value.absent(),
            Value<String?> githubSha = const Value.absent(),
            required String createdAt,
            required String updatedAt,
            Value<String> tags = const Value.absent(),
            Value<String> categories = const Value.absent(),
            Value<String?> permalink = const Value.absent(),
            Value<String?> topImg = const Value.absent(),
            Value<String?> cover = const Value.absent(),
            Value<String?> layout = const Value.absent(),
            Value<int> comments = const Value.absent(),
            Value<int> published = const Value.absent(),
            Value<String?> excerpt = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> author = const Value.absent(),
          }) =>
              ArticleRowsCompanion.insert(
            id: id,
            title: title,
            content: content,
            date: date,
            slug: slug,
            status: status,
            filePath: filePath,
            githubSha: githubSha,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags,
            categories: categories,
            permalink: permalink,
            topImg: topImg,
            cover: cover,
            layout: layout,
            comments: comments,
            published: published,
            excerpt: excerpt,
            description: description,
            author: author,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ArticleRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ArticleRowsTable,
    ArticleRow,
    $$ArticleRowsTableFilterComposer,
    $$ArticleRowsTableOrderingComposer,
    $$ArticleRowsTableAnnotationComposer,
    $$ArticleRowsTableCreateCompanionBuilder,
    $$ArticleRowsTableUpdateCompanionBuilder,
    (ArticleRow, BaseReferences<_$AppDatabase, $ArticleRowsTable, ArticleRow>),
    ArticleRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArticleRowsTableTableManager get articleRows =>
      $$ArticleRowsTableTableManager(_db, _db.articleRows);
}
