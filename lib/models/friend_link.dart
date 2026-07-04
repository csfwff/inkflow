/// 友链数据模型
class FriendLink {
  final int? id;
  String name;
  String link;
  String avatar;
  String descr;
  bool isCommented; // 是否被注释（禁用）
  bool isDev; // 是否为开发者友链
  int sortOrder; // 列表排序（按文件中的顺序）
  DateTime createdAt;

  FriendLink({
    this.id,
    required this.name,
    required this.link,
    this.avatar = '',
    this.descr = '',
    this.isCommented = false,
    this.isDev = false,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 Map 创建（用于 YAML 解析）
  factory FriendLink.fromMap(Map<String, dynamic> map) {
    return FriendLink(
      id: map['id'] as int?,
      name: map['name'] ?? '',
      link: map['link'] ?? '',
      avatar: map['avatar'] ?? '',
      descr: map['descr'] ?? '',
      isCommented: map['isCommented'] ?? false,
      isDev: map['isDev'] ?? false,
      sortOrder: map['sortOrder'] ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'link': link,
      'avatar': avatar,
      'descr': descr,
      'isCommented': isCommented,
      'isDev': isDev,
      'sortOrder': sortOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 复制并修改
  FriendLink copyWith({
    int? id,
    String? name,
    String? link,
    String? avatar,
    String? descr,
    bool? isCommented,
    bool? isDev,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return FriendLink(
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
}
