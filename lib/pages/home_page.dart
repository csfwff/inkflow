import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/github_service.dart';
import '../services/sync_service.dart';
import '../widgets/responsive.dart';
import 'editor_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const HomePage({super.key, this.onSettingsChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Article> _articles = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    final articles = await articleService.getAll();
    if (mounted) {
      setState(() {
        _articles = articles;
        _loading = false;
      });
    }
  }

  Future<void> _syncFromGitHub() async {
    final settings = settingsService.settings;
    if (settings.githubToken.isEmpty ||
        settings.githubOwner.isEmpty ||
        settings.githubRepo.isEmpty) {
      return;
    }

    setState(() => _syncing = true);

    final github = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
    );
    final sync = SyncService(github: github, articleService: articleService);
    final result = await sync.syncFromGitHub();

    if (!mounted) return;
    setState(() => _syncing = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.current.syncSuccess}: ${result.count}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.current.syncFailed}: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    await _loadArticles();
  }

  Future<void> _deleteArticle(Article article) async {
    final s = AppStrings.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteArticle),
        content: Text(s.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteArticle, style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await articleService.delete(article.id!);
      await _loadArticles();
    }
  }

  void _openEditor({int? articleId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(articleId: articleId)),
    );
    _loadArticles();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.homeTitle),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: s.syncFromGitHub,
              onPressed: _syncFromGitHub,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    onSettingsChanged: widget.onSettingsChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _articles.isEmpty
              ? _buildEmptyState()
              : _buildArticleList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            AppStrings.current.noArticles,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _syncFromGitHub,
            icon: Icon(Icons.sync),
            label: Text(AppStrings.current.syncFromGitHub),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList() {
    return Responsive.constrain(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _ArticleListItem(
            article: article,
            onTap: () => _openEditor(articleId: article.id),
            onDelete: () => _deleteArticle(article),
          );
        },
      ),
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ArticleListItem({
    required this.article,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;
    final dateStr =
        '${article.date.year}-${article.date.month.toString().padLeft(2, '0')}-${article.date.day.toString().padLeft(2, '0')}';

    final (label, color) = switch (article.status) {
      ArticleStatus.synced => (s.synced, Colors.green),
      ArticleStatus.repoDraft => (s.repoDraft, Colors.orange),
      ArticleStatus.draft when article.githubSha != null =>
        (s.remoteDeleted, Colors.red),
      ArticleStatus.draft => (s.draftStatus, Colors.grey),
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          dateStr,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
        leading: Chip(
          label: Text(label, style: TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: color),
          labelStyle: TextStyle(color: color),
          backgroundColor: Colors.transparent,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
