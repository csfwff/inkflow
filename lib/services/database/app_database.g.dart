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
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ArticleStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ArticleStatus>($ArticleRowsTable.$converterstatus);
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ArticleRemoteKind?, int>
  remoteKind = GeneratedColumn<int>(
    'remote_kind',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<ArticleRemoteKind?>($ArticleRowsTable.$converterremoteKindn);
  static const VerificationMeta _githubShaMeta = const VerificationMeta(
    'githubSha',
  );
  @override
  late final GeneratedColumn<String> githubSha = GeneratedColumn<String>(
    'github_sha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _permalinkMeta = const VerificationMeta(
    'permalink',
  );
  @override
  late final GeneratedColumn<String> permalink = GeneratedColumn<String>(
    'permalink',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topImgMeta = const VerificationMeta('topImg');
  @override
  late final GeneratedColumn<String> topImg = GeneratedColumn<String>(
    'top_img',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _excerptMeta = const VerificationMeta(
    'excerpt',
  );
  @override
  late final GeneratedColumn<String> excerpt = GeneratedColumn<String>(
    'excerpt',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  @override
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customFieldsMeta = const VerificationMeta(
    'customFields',
  );
  @override
  late final GeneratedColumn<String> customFields = GeneratedColumn<String>(
    'custom_fields',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    date,
    slug,
    status,
    filePath,
    remotePath,
    remoteKind,
    githubSha,
    createdAt,
    updatedAt,
    tags,
    categories,
    permalink,
    topImg,
    cover,
    excerpt,
    description,
    author,
    customFields,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    }
    if (data.containsKey('github_sha')) {
      context.handle(
        _githubShaMeta,
        githubSha.isAcceptableOrUnknown(data['github_sha']!, _githubShaMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    }
    if (data.containsKey('permalink')) {
      context.handle(
        _permalinkMeta,
        permalink.isAcceptableOrUnknown(data['permalink']!, _permalinkMeta),
      );
    }
    if (data.containsKey('top_img')) {
      context.handle(
        _topImgMeta,
        topImg.isAcceptableOrUnknown(data['top_img']!, _topImgMeta),
      );
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('excerpt')) {
      context.handle(
        _excerptMeta,
        excerpt.isAcceptableOrUnknown(data['excerpt']!, _excerptMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('custom_fields')) {
      context.handle(
        _customFieldsMeta,
        customFields.isAcceptableOrUnknown(
          data['custom_fields']!,
          _customFieldsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ArticleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      status: $ArticleRowsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      ),
      remoteKind: $ArticleRowsTable.$converterremoteKindn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}remote_kind'],
        ),
      ),
      githubSha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}github_sha'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      )!,
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      )!,
      permalink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permalink'],
      ),
      topImg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_img'],
      ),
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      excerpt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excerpt'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      customFields: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_fields'],
      )!,
    );
  }

  @override
  $ArticleRowsTable createAlias(String alias) {
    return $ArticleRowsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ArticleStatus, int, int> $converterstatus =
      const EnumIndexConverter<ArticleStatus>(ArticleStatus.values);
  static JsonTypeConverter2<ArticleRemoteKind, int, int> $converterremoteKind =
      const EnumIndexConverter<ArticleRemoteKind>(ArticleRemoteKind.values);
  static JsonTypeConverter2<ArticleRemoteKind?, int?, int?>
  $converterremoteKindn = JsonTypeConverter2.asNullable($converterremoteKind);
}

class ArticleRow extends DataClass implements Insertable<ArticleRow> {
  final int id;
  final String title;
  final String content;
  final String date;
  final String slug;
  final ArticleStatus status;
  final String filePath;
  final String? remotePath;
  final ArticleRemoteKind? remoteKind;
  final String? githubSha;
  final String createdAt;
  final String updatedAt;
  final String tags;
  final String categories;
  final String? permalink;
  final String? topImg;
  final String? cover;
  final String? excerpt;
  final String? description;
  final String? author;
  final String customFields;
  const ArticleRow({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.slug,
    required this.status,
    required this.filePath,
    this.remotePath,
    this.remoteKind,
    this.githubSha,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.categories,
    this.permalink,
    this.topImg,
    this.cover,
    this.excerpt,
    this.description,
    this.author,
    required this.customFields,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['content'] = Variable<String>(content);
    map['date'] = Variable<String>(date);
    map['slug'] = Variable<String>(slug);
    {
      map['status'] = Variable<int>(
        $ArticleRowsTable.$converterstatus.toSql(status),
      );
    }
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || remotePath != null) {
      map['remote_path'] = Variable<String>(remotePath);
    }
    if (!nullToAbsent || remoteKind != null) {
      map['remote_kind'] = Variable<int>(
        $ArticleRowsTable.$converterremoteKindn.toSql(remoteKind),
      );
    }
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
    if (!nullToAbsent || excerpt != null) {
      map['excerpt'] = Variable<String>(excerpt);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    map['custom_fields'] = Variable<String>(customFields);
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
      remotePath: remotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePath),
      remoteKind: remoteKind == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteKind),
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
      topImg: topImg == null && nullToAbsent
          ? const Value.absent()
          : Value(topImg),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      excerpt: excerpt == null && nullToAbsent
          ? const Value.absent()
          : Value(excerpt),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      customFields: Value(customFields),
    );
  }

  factory ArticleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      date: serializer.fromJson<String>(json['date']),
      slug: serializer.fromJson<String>(json['slug']),
      status: $ArticleRowsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      filePath: serializer.fromJson<String>(json['filePath']),
      remotePath: serializer.fromJson<String?>(json['remotePath']),
      remoteKind: $ArticleRowsTable.$converterremoteKindn.fromJson(
        serializer.fromJson<int?>(json['remoteKind']),
      ),
      githubSha: serializer.fromJson<String?>(json['githubSha']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      tags: serializer.fromJson<String>(json['tags']),
      categories: serializer.fromJson<String>(json['categories']),
      permalink: serializer.fromJson<String?>(json['permalink']),
      topImg: serializer.fromJson<String?>(json['topImg']),
      cover: serializer.fromJson<String?>(json['cover']),
      excerpt: serializer.fromJson<String?>(json['excerpt']),
      description: serializer.fromJson<String?>(json['description']),
      author: serializer.fromJson<String?>(json['author']),
      customFields: serializer.fromJson<String>(json['customFields']),
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
      'status': serializer.toJson<int>(
        $ArticleRowsTable.$converterstatus.toJson(status),
      ),
      'filePath': serializer.toJson<String>(filePath),
      'remotePath': serializer.toJson<String?>(remotePath),
      'remoteKind': serializer.toJson<int?>(
        $ArticleRowsTable.$converterremoteKindn.toJson(remoteKind),
      ),
      'githubSha': serializer.toJson<String?>(githubSha),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'tags': serializer.toJson<String>(tags),
      'categories': serializer.toJson<String>(categories),
      'permalink': serializer.toJson<String?>(permalink),
      'topImg': serializer.toJson<String?>(topImg),
      'cover': serializer.toJson<String?>(cover),
      'excerpt': serializer.toJson<String?>(excerpt),
      'description': serializer.toJson<String?>(description),
      'author': serializer.toJson<String?>(author),
      'customFields': serializer.toJson<String>(customFields),
    };
  }

  ArticleRow copyWith({
    int? id,
    String? title,
    String? content,
    String? date,
    String? slug,
    ArticleStatus? status,
    String? filePath,
    Value<String?> remotePath = const Value.absent(),
    Value<ArticleRemoteKind?> remoteKind = const Value.absent(),
    Value<String?> githubSha = const Value.absent(),
    String? createdAt,
    String? updatedAt,
    String? tags,
    String? categories,
    Value<String?> permalink = const Value.absent(),
    Value<String?> topImg = const Value.absent(),
    Value<String?> cover = const Value.absent(),
    Value<String?> excerpt = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> author = const Value.absent(),
    String? customFields,
  }) => ArticleRow(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    date: date ?? this.date,
    slug: slug ?? this.slug,
    status: status ?? this.status,
    filePath: filePath ?? this.filePath,
    remotePath: remotePath.present ? remotePath.value : this.remotePath,
    remoteKind: remoteKind.present ? remoteKind.value : this.remoteKind,
    githubSha: githubSha.present ? githubSha.value : this.githubSha,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    tags: tags ?? this.tags,
    categories: categories ?? this.categories,
    permalink: permalink.present ? permalink.value : this.permalink,
    topImg: topImg.present ? topImg.value : this.topImg,
    cover: cover.present ? cover.value : this.cover,
    excerpt: excerpt.present ? excerpt.value : this.excerpt,
    description: description.present ? description.value : this.description,
    author: author.present ? author.value : this.author,
    customFields: customFields ?? this.customFields,
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
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      remoteKind: data.remoteKind.present
          ? data.remoteKind.value
          : this.remoteKind,
      githubSha: data.githubSha.present ? data.githubSha.value : this.githubSha,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      tags: data.tags.present ? data.tags.value : this.tags,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      permalink: data.permalink.present ? data.permalink.value : this.permalink,
      topImg: data.topImg.present ? data.topImg.value : this.topImg,
      cover: data.cover.present ? data.cover.value : this.cover,
      excerpt: data.excerpt.present ? data.excerpt.value : this.excerpt,
      description: data.description.present
          ? data.description.value
          : this.description,
      author: data.author.present ? data.author.value : this.author,
      customFields: data.customFields.present
          ? data.customFields.value
          : this.customFields,
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
          ..write('remotePath: $remotePath, ')
          ..write('remoteKind: $remoteKind, ')
          ..write('githubSha: $githubSha, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('categories: $categories, ')
          ..write('permalink: $permalink, ')
          ..write('topImg: $topImg, ')
          ..write('cover: $cover, ')
          ..write('excerpt: $excerpt, ')
          ..write('description: $description, ')
          ..write('author: $author, ')
          ..write('customFields: $customFields')
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
    remotePath,
    remoteKind,
    githubSha,
    createdAt,
    updatedAt,
    tags,
    categories,
    permalink,
    topImg,
    cover,
    excerpt,
    description,
    author,
    customFields,
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
          other.remotePath == this.remotePath &&
          other.remoteKind == this.remoteKind &&
          other.githubSha == this.githubSha &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.tags == this.tags &&
          other.categories == this.categories &&
          other.permalink == this.permalink &&
          other.topImg == this.topImg &&
          other.cover == this.cover &&
          other.excerpt == this.excerpt &&
          other.description == this.description &&
          other.author == this.author &&
          other.customFields == this.customFields);
}

class ArticleRowsCompanion extends UpdateCompanion<ArticleRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> date;
  final Value<String> slug;
  final Value<ArticleStatus> status;
  final Value<String> filePath;
  final Value<String?> remotePath;
  final Value<ArticleRemoteKind?> remoteKind;
  final Value<String?> githubSha;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String> tags;
  final Value<String> categories;
  final Value<String?> permalink;
  final Value<String?> topImg;
  final Value<String?> cover;
  final Value<String?> excerpt;
  final Value<String?> description;
  final Value<String?> author;
  final Value<String> customFields;
  const ArticleRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.date = const Value.absent(),
    this.slug = const Value.absent(),
    this.status = const Value.absent(),
    this.filePath = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.remoteKind = const Value.absent(),
    this.githubSha = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.tags = const Value.absent(),
    this.categories = const Value.absent(),
    this.permalink = const Value.absent(),
    this.topImg = const Value.absent(),
    this.cover = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
    this.customFields = const Value.absent(),
  });
  ArticleRowsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    required String date,
    this.slug = const Value.absent(),
    required ArticleStatus status,
    this.filePath = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.remoteKind = const Value.absent(),
    this.githubSha = const Value.absent(),
    required String createdAt,
    required String updatedAt,
    this.tags = const Value.absent(),
    this.categories = const Value.absent(),
    this.permalink = const Value.absent(),
    this.topImg = const Value.absent(),
    this.cover = const Value.absent(),
    this.excerpt = const Value.absent(),
    this.description = const Value.absent(),
    this.author = const Value.absent(),
    this.customFields = const Value.absent(),
  }) : date = Value(date),
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
    Expression<String>? remotePath,
    Expression<int>? remoteKind,
    Expression<String>? githubSha,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? tags,
    Expression<String>? categories,
    Expression<String>? permalink,
    Expression<String>? topImg,
    Expression<String>? cover,
    Expression<String>? excerpt,
    Expression<String>? description,
    Expression<String>? author,
    Expression<String>? customFields,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (date != null) 'date': date,
      if (slug != null) 'slug': slug,
      if (status != null) 'status': status,
      if (filePath != null) 'file_path': filePath,
      if (remotePath != null) 'remote_path': remotePath,
      if (remoteKind != null) 'remote_kind': remoteKind,
      if (githubSha != null) 'github_sha': githubSha,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (tags != null) 'tags': tags,
      if (categories != null) 'categories': categories,
      if (permalink != null) 'permalink': permalink,
      if (topImg != null) 'top_img': topImg,
      if (cover != null) 'cover': cover,
      if (excerpt != null) 'excerpt': excerpt,
      if (description != null) 'description': description,
      if (author != null) 'author': author,
      if (customFields != null) 'custom_fields': customFields,
    });
  }

  ArticleRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String>? date,
    Value<String>? slug,
    Value<ArticleStatus>? status,
    Value<String>? filePath,
    Value<String?>? remotePath,
    Value<ArticleRemoteKind?>? remoteKind,
    Value<String?>? githubSha,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String>? tags,
    Value<String>? categories,
    Value<String?>? permalink,
    Value<String?>? topImg,
    Value<String?>? cover,
    Value<String?>? excerpt,
    Value<String?>? description,
    Value<String?>? author,
    Value<String>? customFields,
  }) {
    return ArticleRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      filePath: filePath ?? this.filePath,
      remotePath: remotePath ?? this.remotePath,
      remoteKind: remoteKind ?? this.remoteKind,
      githubSha: githubSha ?? this.githubSha,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      categories: categories ?? this.categories,
      permalink: permalink ?? this.permalink,
      topImg: topImg ?? this.topImg,
      cover: cover ?? this.cover,
      excerpt: excerpt ?? this.excerpt,
      description: description ?? this.description,
      author: author ?? this.author,
      customFields: customFields ?? this.customFields,
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
      map['status'] = Variable<int>(
        $ArticleRowsTable.$converterstatus.toSql(status.value),
      );
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (remoteKind.present) {
      map['remote_kind'] = Variable<int>(
        $ArticleRowsTable.$converterremoteKindn.toSql(remoteKind.value),
      );
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
    if (excerpt.present) {
      map['excerpt'] = Variable<String>(excerpt.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (customFields.present) {
      map['custom_fields'] = Variable<String>(customFields.value);
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
          ..write('remotePath: $remotePath, ')
          ..write('remoteKind: $remoteKind, ')
          ..write('githubSha: $githubSha, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('tags: $tags, ')
          ..write('categories: $categories, ')
          ..write('permalink: $permalink, ')
          ..write('topImg: $topImg, ')
          ..write('cover: $cover, ')
          ..write('excerpt: $excerpt, ')
          ..write('description: $description, ')
          ..write('author: $author, ')
          ..write('customFields: $customFields')
          ..write(')'))
        .toString();
  }
}

class $TagRowsTable extends TagRows with TableInfo<$TagRowsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tag_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagRowsTable createAlias(String alias) {
    return $TagRowsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final int id;
  final String name;
  final String createdAt;
  const TagRow({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  TagRowsCompanion toCompanion(bool nullToAbsent) {
    return TagRowsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  TagRow copyWith({int? id, String? name, String? createdAt}) => TagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  TagRow copyWithCompanion(TagRowsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class TagRowsCompanion extends UpdateCompanion<TagRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> createdAt;
  const TagRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TagRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TagRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TagRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? createdAt,
  }) {
    return TagRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CategoryRowsTable extends CategoryRows
    with TableInfo<$CategoryRowsTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoryRowsTable createAlias(String alias) {
    return $CategoryRowsTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final String createdAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  CategoryRowsCompanion toCompanion(bool nullToAbsent) {
    return CategoryRowsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  CategoryRow copyWith({int? id, String? name, String? createdAt}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  CategoryRow copyWithCompanion(CategoryRowsCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class CategoryRowsCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> createdAt;
  const CategoryRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoryRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoryRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? createdAt,
  }) {
    return CategoryRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FriendLinkRowsTable extends FriendLinkRows
    with TableInfo<$FriendLinkRowsTable, FriendLinkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendLinkRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descrMeta = const VerificationMeta('descr');
  @override
  late final GeneratedColumn<String> descr = GeneratedColumn<String>(
    'descr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isCommentedMeta = const VerificationMeta(
    'isCommented',
  );
  @override
  late final GeneratedColumn<bool> isCommented = GeneratedColumn<bool>(
    'is_commented',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_commented" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDevMeta = const VerificationMeta('isDev');
  @override
  late final GeneratedColumn<bool> isDev = GeneratedColumn<bool>(
    'is_dev',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dev" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    link,
    avatar,
    descr,
    isCommented,
    isDev,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friend_link_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<FriendLinkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('descr')) {
      context.handle(
        _descrMeta,
        descr.isAcceptableOrUnknown(data['descr']!, _descrMeta),
      );
    }
    if (data.containsKey('is_commented')) {
      context.handle(
        _isCommentedMeta,
        isCommented.isAcceptableOrUnknown(
          data['is_commented']!,
          _isCommentedMeta,
        ),
      );
    }
    if (data.containsKey('is_dev')) {
      context.handle(
        _isDevMeta,
        isDev.isAcceptableOrUnknown(data['is_dev']!, _isDevMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  FriendLinkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FriendLinkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      )!,
      descr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descr'],
      )!,
      isCommented: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_commented'],
      )!,
      isDev: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dev'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FriendLinkRowsTable createAlias(String alias) {
    return $FriendLinkRowsTable(attachedDatabase, alias);
  }
}

class FriendLinkRow extends DataClass implements Insertable<FriendLinkRow> {
  final int id;
  final String name;
  final String link;
  final String avatar;
  final String descr;
  final bool isCommented;
  final bool isDev;
  final int sortOrder;
  final String createdAt;
  const FriendLinkRow({
    required this.id,
    required this.name,
    required this.link,
    required this.avatar,
    required this.descr,
    required this.isCommented,
    required this.isDev,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['link'] = Variable<String>(link);
    map['avatar'] = Variable<String>(avatar);
    map['descr'] = Variable<String>(descr);
    map['is_commented'] = Variable<bool>(isCommented);
    map['is_dev'] = Variable<bool>(isDev);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  FriendLinkRowsCompanion toCompanion(bool nullToAbsent) {
    return FriendLinkRowsCompanion(
      id: Value(id),
      name: Value(name),
      link: Value(link),
      avatar: Value(avatar),
      descr: Value(descr),
      isCommented: Value(isCommented),
      isDev: Value(isDev),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory FriendLinkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FriendLinkRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      link: serializer.fromJson<String>(json['link']),
      avatar: serializer.fromJson<String>(json['avatar']),
      descr: serializer.fromJson<String>(json['descr']),
      isCommented: serializer.fromJson<bool>(json['isCommented']),
      isDev: serializer.fromJson<bool>(json['isDev']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'link': serializer.toJson<String>(link),
      'avatar': serializer.toJson<String>(avatar),
      'descr': serializer.toJson<String>(descr),
      'isCommented': serializer.toJson<bool>(isCommented),
      'isDev': serializer.toJson<bool>(isDev),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  FriendLinkRow copyWith({
    int? id,
    String? name,
    String? link,
    String? avatar,
    String? descr,
    bool? isCommented,
    bool? isDev,
    int? sortOrder,
    String? createdAt,
  }) => FriendLinkRow(
    id: id ?? this.id,
    name: name ?? this.name,
    link: link ?? this.link,
    avatar: avatar ?? this.avatar,
    descr: descr ?? this.descr,
    isCommented: isCommented ?? this.isCommented,
    isDev: isDev ?? this.isDev,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  FriendLinkRow copyWithCompanion(FriendLinkRowsCompanion data) {
    return FriendLinkRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      link: data.link.present ? data.link.value : this.link,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      descr: data.descr.present ? data.descr.value : this.descr,
      isCommented: data.isCommented.present
          ? data.isCommented.value
          : this.isCommented,
      isDev: data.isDev.present ? data.isDev.value : this.isDev,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FriendLinkRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('link: $link, ')
          ..write('avatar: $avatar, ')
          ..write('descr: $descr, ')
          ..write('isCommented: $isCommented, ')
          ..write('isDev: $isDev, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    link,
    avatar,
    descr,
    isCommented,
    isDev,
    sortOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FriendLinkRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.link == this.link &&
          other.avatar == this.avatar &&
          other.descr == this.descr &&
          other.isCommented == this.isCommented &&
          other.isDev == this.isDev &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class FriendLinkRowsCompanion extends UpdateCompanion<FriendLinkRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> link;
  final Value<String> avatar;
  final Value<String> descr;
  final Value<bool> isCommented;
  final Value<bool> isDev;
  final Value<int> sortOrder;
  final Value<String> createdAt;
  const FriendLinkRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.link = const Value.absent(),
    this.avatar = const Value.absent(),
    this.descr = const Value.absent(),
    this.isCommented = const Value.absent(),
    this.isDev = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  FriendLinkRowsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.link = const Value.absent(),
    this.avatar = const Value.absent(),
    this.descr = const Value.absent(),
    this.isCommented = const Value.absent(),
    this.isDev = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required String createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<FriendLinkRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? link,
    Expression<String>? avatar,
    Expression<String>? descr,
    Expression<bool>? isCommented,
    Expression<bool>? isDev,
    Expression<int>? sortOrder,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (link != null) 'link': link,
      if (avatar != null) 'avatar': avatar,
      if (descr != null) 'descr': descr,
      if (isCommented != null) 'is_commented': isCommented,
      if (isDev != null) 'is_dev': isDev,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  FriendLinkRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? link,
    Value<String>? avatar,
    Value<String>? descr,
    Value<bool>? isCommented,
    Value<bool>? isDev,
    Value<int>? sortOrder,
    Value<String>? createdAt,
  }) {
    return FriendLinkRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      link: link ?? this.link,
      avatar: avatar ?? this.avatar,
      descr: descr ?? this.descr,
      isCommented: isCommented ?? this.isCommented,
      isDev: isDev ?? this.isDev,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (descr.present) {
      map['descr'] = Variable<String>(descr.value);
    }
    if (isCommented.present) {
      map['is_commented'] = Variable<bool>(isCommented.value);
    }
    if (isDev.present) {
      map['is_dev'] = Variable<bool>(isDev.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendLinkRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('link: $link, ')
          ..write('avatar: $avatar, ')
          ..write('descr: $descr, ')
          ..write('isCommented: $isCommented, ')
          ..write('isDev: $isDev, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArticleRowsTable articleRows = $ArticleRowsTable(this);
  late final $TagRowsTable tagRows = $TagRowsTable(this);
  late final $CategoryRowsTable categoryRows = $CategoryRowsTable(this);
  late final $FriendLinkRowsTable friendLinkRows = $FriendLinkRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    articleRows,
    tagRows,
    categoryRows,
    friendLinkRows,
  ];
}

typedef $$ArticleRowsTableCreateCompanionBuilder =
    ArticleRowsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      required String date,
      Value<String> slug,
      required ArticleStatus status,
      Value<String> filePath,
      Value<String?> remotePath,
      Value<ArticleRemoteKind?> remoteKind,
      Value<String?> githubSha,
      required String createdAt,
      required String updatedAt,
      Value<String> tags,
      Value<String> categories,
      Value<String?> permalink,
      Value<String?> topImg,
      Value<String?> cover,
      Value<String?> excerpt,
      Value<String?> description,
      Value<String?> author,
      Value<String> customFields,
    });
typedef $$ArticleRowsTableUpdateCompanionBuilder =
    ArticleRowsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> content,
      Value<String> date,
      Value<String> slug,
      Value<ArticleStatus> status,
      Value<String> filePath,
      Value<String?> remotePath,
      Value<ArticleRemoteKind?> remoteKind,
      Value<String?> githubSha,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<String> tags,
      Value<String> categories,
      Value<String?> permalink,
      Value<String?> topImg,
      Value<String?> cover,
      Value<String?> excerpt,
      Value<String?> description,
      Value<String?> author,
      Value<String> customFields,
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
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ArticleStatus, ArticleStatus, int>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ArticleRemoteKind?, ArticleRemoteKind, int>
  get remoteKind => $composableBuilder(
    column: $table.remoteKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get githubSha => $composableBuilder(
    column: $table.githubSha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permalink => $composableBuilder(
    column: $table.permalink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topImg => $composableBuilder(
    column: $table.topImg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteKind => $composableBuilder(
    column: $table.remoteKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get githubSha => $composableBuilder(
    column: $table.githubSha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permalink => $composableBuilder(
    column: $table.permalink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topImg => $composableBuilder(
    column: $table.topImg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excerpt => $composableBuilder(
    column: $table.excerpt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ArticleRemoteKind?, int> get remoteKind =>
      $composableBuilder(
        column: $table.remoteKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get githubSha =>
      $composableBuilder(column: $table.githubSha, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get permalink =>
      $composableBuilder(column: $table.permalink, builder: (column) => column);

  GeneratedColumn<String> get topImg =>
      $composableBuilder(column: $table.topImg, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get excerpt =>
      $composableBuilder(column: $table.excerpt, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  GeneratedColumn<String> get customFields => $composableBuilder(
    column: $table.customFields,
    builder: (column) => column,
  );
}

class $$ArticleRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticleRowsTable,
          ArticleRow,
          $$ArticleRowsTableFilterComposer,
          $$ArticleRowsTableOrderingComposer,
          $$ArticleRowsTableAnnotationComposer,
          $$ArticleRowsTableCreateCompanionBuilder,
          $$ArticleRowsTableUpdateCompanionBuilder,
          (
            ArticleRow,
            BaseReferences<_$AppDatabase, $ArticleRowsTable, ArticleRow>,
          ),
          ArticleRow,
          PrefetchHooks Function()
        > {
  $$ArticleRowsTableTableManager(_$AppDatabase db, $ArticleRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticleRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticleRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticleRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<ArticleStatus> status = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> remotePath = const Value.absent(),
                Value<ArticleRemoteKind?> remoteKind = const Value.absent(),
                Value<String?> githubSha = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String> tags = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String?> permalink = const Value.absent(),
                Value<String?> topImg = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> excerpt = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String> customFields = const Value.absent(),
              }) => ArticleRowsCompanion(
                id: id,
                title: title,
                content: content,
                date: date,
                slug: slug,
                status: status,
                filePath: filePath,
                remotePath: remotePath,
                remoteKind: remoteKind,
                githubSha: githubSha,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: tags,
                categories: categories,
                permalink: permalink,
                topImg: topImg,
                cover: cover,
                excerpt: excerpt,
                description: description,
                author: author,
                customFields: customFields,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                required String date,
                Value<String> slug = const Value.absent(),
                required ArticleStatus status,
                Value<String> filePath = const Value.absent(),
                Value<String?> remotePath = const Value.absent(),
                Value<ArticleRemoteKind?> remoteKind = const Value.absent(),
                Value<String?> githubSha = const Value.absent(),
                required String createdAt,
                required String updatedAt,
                Value<String> tags = const Value.absent(),
                Value<String> categories = const Value.absent(),
                Value<String?> permalink = const Value.absent(),
                Value<String?> topImg = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> excerpt = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> author = const Value.absent(),
                Value<String> customFields = const Value.absent(),
              }) => ArticleRowsCompanion.insert(
                id: id,
                title: title,
                content: content,
                date: date,
                slug: slug,
                status: status,
                filePath: filePath,
                remotePath: remotePath,
                remoteKind: remoteKind,
                githubSha: githubSha,
                createdAt: createdAt,
                updatedAt: updatedAt,
                tags: tags,
                categories: categories,
                permalink: permalink,
                topImg: topImg,
                cover: cover,
                excerpt: excerpt,
                description: description,
                author: author,
                customFields: customFields,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticleRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticleRowsTable,
      ArticleRow,
      $$ArticleRowsTableFilterComposer,
      $$ArticleRowsTableOrderingComposer,
      $$ArticleRowsTableAnnotationComposer,
      $$ArticleRowsTableCreateCompanionBuilder,
      $$ArticleRowsTableUpdateCompanionBuilder,
      (
        ArticleRow,
        BaseReferences<_$AppDatabase, $ArticleRowsTable, ArticleRow>,
      ),
      ArticleRow,
      PrefetchHooks Function()
    >;
typedef $$TagRowsTableCreateCompanionBuilder =
    TagRowsCompanion Function({
      Value<int> id,
      required String name,
      required String createdAt,
    });
typedef $$TagRowsTableUpdateCompanionBuilder =
    TagRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> createdAt,
    });

class $$TagRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TagRowsTable> {
  $$TagRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TagRowsTable> {
  $$TagRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagRowsTable> {
  $$TagRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TagRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagRowsTable,
          TagRow,
          $$TagRowsTableFilterComposer,
          $$TagRowsTableOrderingComposer,
          $$TagRowsTableAnnotationComposer,
          $$TagRowsTableCreateCompanionBuilder,
          $$TagRowsTableUpdateCompanionBuilder,
          (TagRow, BaseReferences<_$AppDatabase, $TagRowsTable, TagRow>),
          TagRow,
          PrefetchHooks Function()
        > {
  $$TagRowsTableTableManager(_$AppDatabase db, $TagRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => TagRowsCompanion(id: id, name: name, createdAt: createdAt),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String createdAt,
              }) => TagRowsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagRowsTable,
      TagRow,
      $$TagRowsTableFilterComposer,
      $$TagRowsTableOrderingComposer,
      $$TagRowsTableAnnotationComposer,
      $$TagRowsTableCreateCompanionBuilder,
      $$TagRowsTableUpdateCompanionBuilder,
      (TagRow, BaseReferences<_$AppDatabase, $TagRowsTable, TagRow>),
      TagRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryRowsTableCreateCompanionBuilder =
    CategoryRowsCompanion Function({
      Value<int> id,
      required String name,
      required String createdAt,
    });
typedef $$CategoryRowsTableUpdateCompanionBuilder =
    CategoryRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> createdAt,
    });

class $$CategoryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryRowsTable> {
  $$CategoryRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryRowsTable> {
  $$CategoryRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryRowsTable> {
  $$CategoryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryRowsTable,
          CategoryRow,
          $$CategoryRowsTableFilterComposer,
          $$CategoryRowsTableOrderingComposer,
          $$CategoryRowsTableAnnotationComposer,
          $$CategoryRowsTableCreateCompanionBuilder,
          $$CategoryRowsTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoryRowsTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoryRowsTableTableManager(_$AppDatabase db, $CategoryRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => CategoryRowsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String createdAt,
              }) => CategoryRowsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryRowsTable,
      CategoryRow,
      $$CategoryRowsTableFilterComposer,
      $$CategoryRowsTableOrderingComposer,
      $$CategoryRowsTableAnnotationComposer,
      $$CategoryRowsTableCreateCompanionBuilder,
      $$CategoryRowsTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoryRowsTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$FriendLinkRowsTableCreateCompanionBuilder =
    FriendLinkRowsCompanion Function({
      Value<int> id,
      required String name,
      Value<String> link,
      Value<String> avatar,
      Value<String> descr,
      Value<bool> isCommented,
      Value<bool> isDev,
      Value<int> sortOrder,
      required String createdAt,
    });
typedef $$FriendLinkRowsTableUpdateCompanionBuilder =
    FriendLinkRowsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> link,
      Value<String> avatar,
      Value<String> descr,
      Value<bool> isCommented,
      Value<bool> isDev,
      Value<int> sortOrder,
      Value<String> createdAt,
    });

class $$FriendLinkRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FriendLinkRowsTable> {
  $$FriendLinkRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descr => $composableBuilder(
    column: $table.descr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCommented => $composableBuilder(
    column: $table.isCommented,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDev => $composableBuilder(
    column: $table.isDev,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendLinkRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FriendLinkRowsTable> {
  $$FriendLinkRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descr => $composableBuilder(
    column: $table.descr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCommented => $composableBuilder(
    column: $table.isCommented,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDev => $composableBuilder(
    column: $table.isDev,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendLinkRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FriendLinkRowsTable> {
  $$FriendLinkRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get descr =>
      $composableBuilder(column: $table.descr, builder: (column) => column);

  GeneratedColumn<bool> get isCommented => $composableBuilder(
    column: $table.isCommented,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDev =>
      $composableBuilder(column: $table.isDev, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FriendLinkRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FriendLinkRowsTable,
          FriendLinkRow,
          $$FriendLinkRowsTableFilterComposer,
          $$FriendLinkRowsTableOrderingComposer,
          $$FriendLinkRowsTableAnnotationComposer,
          $$FriendLinkRowsTableCreateCompanionBuilder,
          $$FriendLinkRowsTableUpdateCompanionBuilder,
          (
            FriendLinkRow,
            BaseReferences<_$AppDatabase, $FriendLinkRowsTable, FriendLinkRow>,
          ),
          FriendLinkRow,
          PrefetchHooks Function()
        > {
  $$FriendLinkRowsTableTableManager(
    _$AppDatabase db,
    $FriendLinkRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendLinkRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendLinkRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendLinkRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> link = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<String> descr = const Value.absent(),
                Value<bool> isCommented = const Value.absent(),
                Value<bool> isDev = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => FriendLinkRowsCompanion(
                id: id,
                name: name,
                link: link,
                avatar: avatar,
                descr: descr,
                isCommented: isCommented,
                isDev: isDev,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> link = const Value.absent(),
                Value<String> avatar = const Value.absent(),
                Value<String> descr = const Value.absent(),
                Value<bool> isCommented = const Value.absent(),
                Value<bool> isDev = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required String createdAt,
              }) => FriendLinkRowsCompanion.insert(
                id: id,
                name: name,
                link: link,
                avatar: avatar,
                descr: descr,
                isCommented: isCommented,
                isDev: isDev,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendLinkRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FriendLinkRowsTable,
      FriendLinkRow,
      $$FriendLinkRowsTableFilterComposer,
      $$FriendLinkRowsTableOrderingComposer,
      $$FriendLinkRowsTableAnnotationComposer,
      $$FriendLinkRowsTableCreateCompanionBuilder,
      $$FriendLinkRowsTableUpdateCompanionBuilder,
      (
        FriendLinkRow,
        BaseReferences<_$AppDatabase, $FriendLinkRowsTable, FriendLinkRow>,
      ),
      FriendLinkRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArticleRowsTableTableManager get articleRows =>
      $$ArticleRowsTableTableManager(_db, _db.articleRows);
  $$TagRowsTableTableManager get tagRows =>
      $$TagRowsTableTableManager(_db, _db.tagRows);
  $$CategoryRowsTableTableManager get categoryRows =>
      $$CategoryRowsTableTableManager(_db, _db.categoryRows);
  $$FriendLinkRowsTableTableManager get friendLinkRows =>
      $$FriendLinkRowsTableTableManager(_db, _db.friendLinkRows);
}
