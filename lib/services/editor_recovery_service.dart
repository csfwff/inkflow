import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';

class EditorRecovery {
  final String title;
  final String body;
  final DateTime date;
  final DateTime savedAt;

  const EditorRecovery({
    required this.title,
    required this.body,
    required this.date,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'date': date.toIso8601String(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory EditorRecovery.fromJson(Map<String, dynamic> json) {
    return EditorRecovery(
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ArticleRevision {
  final Article article;
  final DateTime savedAt;

  const ArticleRevision({required this.article, required this.savedAt});
}

/// Persists crash recovery drafts and a compact local version history.
///
/// This deliberately uses SharedPreferences rather than altering the article
/// schema: it works on every supported platform and does not require a data
/// migration for the current single-user app.
class EditorRecoveryService {
  static const _recoveryPrefix = 'editor_recovery_v1_';
  static const _historyPrefix = 'article_history_v1_';
  static const maxRevisions = 20;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  String recoveryKeyForArticle(int? articleId) => articleId == null
      ? '${_recoveryPrefix}new'
      : '$_recoveryPrefix$articleId';

  Future<void> saveRecovery(String key, EditorRecovery recovery) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(recovery.toJson()));
  }

  Future<EditorRecovery?> loadRecovery(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return EditorRecovery.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // A malformed recovery entry should never block opening an article.
    }
    return null;
  }

  Future<void> clearRecovery(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  Future<List<ArticleRevision>> listRevisions(int articleId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_historyPrefix$articleId');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final revisions = <ArticleRevision>[];
      for (final item in decoded) {
        if (item is! Map || item['article'] is! Map) continue;
        final savedAt = DateTime.tryParse(item['savedAt']?.toString() ?? '');
        if (savedAt == null) continue;
        revisions.add(
          ArticleRevision(
            article: Article.fromMap(
              Map<String, dynamic>.from(item['article'] as Map),
            ),
            savedAt: savedAt,
          ),
        );
      }
      return revisions;
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRevision(Article article) async {
    final id = article.id;
    if (id == null) return;

    final revisions = await listRevisions(id);
    if (revisions.isNotEmpty &&
        _sameDocument(revisions.first.article, article)) {
      return;
    }

    final next = [
      ArticleRevision(article: article, savedAt: DateTime.now()),
      ...revisions,
    ].take(maxRevisions).toList();
    final encoded = next
        .map(
          (revision) => {
            'savedAt': revision.savedAt.toIso8601String(),
            'article': revision.article.toMap(),
          },
        )
        .toList();
    final prefs = await _prefs;
    await prefs.setString('$_historyPrefix$id', jsonEncode(encoded));
  }

  bool _sameDocument(Article left, Article right) {
    return left.title == right.title &&
        left.content == right.content &&
        left.date == right.date &&
        left.tags.join(',') == right.tags.join(',') &&
        left.categories.join(',') == right.categories.join(',') &&
        jsonEncode(left.customFields) == jsonEncode(right.customFields);
  }
}
