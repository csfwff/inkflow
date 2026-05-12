import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/github_service.dart';
import '../widgets/responsive.dart';
import 'metadata_page.dart';

class EditorPage extends StatefulWidget {
  final int? articleId;

  const EditorPage({super.key, this.articleId});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _publishing = false;
  String _previewText = '';
  Article? _editingArticle;

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() {
      setState(() => _previewText = _contentCtrl.text);
    });
    if (widget.articleId != null) {
      _loadArticle(widget.articleId!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadArticle(int id) async {
    final article = await articleService.getById(id);
    if (article != null && mounted) {
      setState(() {
        _editingArticle = article;
        _titleCtrl.text = article.title;
        _contentCtrl.text = article.content;
        _selectedDate = article.date;
        _previewText = article.content;
      });
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Article _buildArticle() {
    final title = _titleCtrl.text.trim();
    final slug = _slugify(title);
    final filePath =
        '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/$slug.md';

    return Article(
      id: _editingArticle?.id,
      title: title,
      content: _contentCtrl.text,
      date: _selectedDate,
      slug: slug,
      status: _editingArticle?.status ?? ArticleStatus.draft,
      filePath: filePath,
      githubSha: _editingArticle?.githubSha,
      createdAt: _editingArticle?.createdAt,
      tags: _editingArticle?.tags ?? [],
      categories: _editingArticle?.categories ?? [],
      permalink: _editingArticle?.permalink,
      topImg: _editingArticle?.topImg,
      cover: _editingArticle?.cover,
      layout: _editingArticle?.layout,
      comments: _editingArticle?.comments,
      published: _editingArticle?.published,
      excerpt: _editingArticle?.excerpt,
      description: _editingArticle?.description,
      author: _editingArticle?.author,
    );
  }

  Future<void> _openMetadata() async {
    if (_editingArticle == null) {
      final article = _buildArticle();
      final id = await articleService.insert(article);
      _editingArticle = await articleService.getById(id);
    }

    if (!mounted) return;

    final result = await Navigator.push<Article>(
      context,
      MaterialPageRoute(
        builder: (_) => MetadataPage(article: _editingArticle!),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _editingArticle = result;
      });
    }
  }

  Future<void> _saveDraft() async {
    final s = AppStrings.current;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.titleHint)),
      );
      return;
    }

    final article = _buildArticle();
    if (_editingArticle != null) {
      article.updatedAt = DateTime.now();
      await articleService.update(article);
    } else {
      final id = await articleService.insert(article);
      _editingArticle = await articleService.getById(id);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.articleSaved)),
    );
  }

  Future<void> _publish({bool drafts = false}) async {
    final s = AppStrings.current;
    final settings = settingsService.settings;

    if (settings.githubToken.isEmpty ||
        settings.githubOwner.isEmpty ||
        settings.githubRepo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.githubNotConfigured)),
      );
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.titleHint)),
      );
      return;
    }

    setState(() => _publishing = true);

    final article = _buildArticle();
    final fileName = article.filePath;
    final fullContent = article.fullContent;

    final service = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
    );

    final targetStatus = drafts ? ArticleStatus.repoDraft : ArticleStatus.synced;
    final commitPrefix = drafts ? 'draft' : 'post';

    GitHubResult result;

    if (_editingArticle?.githubSha != null &&
        _editingArticle!.githubSha!.isNotEmpty) {
      result = await service.updatePost(
        filePath: fileName,
        content: fullContent,
        sha: _editingArticle!.githubSha!,
        commitMessage: '$commitPrefix: update $title',
        drafts: drafts,
      );
    } else {
      result = await service.createPost(
        fileName: fileName,
        content: fullContent,
        commitMessage: '$commitPrefix: $title',
        drafts: drafts,
      );
    }

    if (!mounted) return;
    setState(() => _publishing = false);

    if (result.success) {
      article.status = targetStatus;
      article.githubSha = result.sha;

      if (_editingArticle != null) {
        article.updatedAt = DateTime.now();
        await articleService.update(article);
      } else {
        final id = await articleService.insert(article);
        _editingArticle = await articleService.getById(id);
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);
    final s = AppStrings.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.editorTitle),
        actions: [
          if (_publishing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              onPressed: _openMetadata,
              icon: const Icon(Icons.tune),
              tooltip: s.metadata,
            ),
            TextButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.save),
              label: Text(s.saveDraft),
            ),
            TextButton.icon(
              onPressed: () => _publish(drafts: true),
              icon: const Icon(Icons.edit_note),
              label: Text(s.pushToDraft),
            ),
            TextButton.icon(
              onPressed: () => _publish(),
              icon: const Icon(Icons.cloud_upload),
              label: Text(s.publish),
            ),
          ],
        ],
      ),
      body: wide ? _buildWide() : _buildNarrow(),
    );
  }

  Widget _buildNarrow() {
    return Column(
      children: [
        _buildMetaBar(),
        Divider(height: 1),
        Expanded(child: _buildEditorArea()),
      ],
    );
  }

  Widget _buildWide() {
    return Column(
      children: [
        _buildMetaBar(),
        Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildEditorField(),
                ),
              ),
              VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildPreview(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaBar() {
    final s = AppStrings.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: s.titleHint,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: const OutlineInputBorder(),
                  labelText: s.date,
                ),
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorArea() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildEditorField(),
    );
  }

  Widget _buildEditorField() {
    return TextField(
      controller: _contentCtrl,
      maxLines: null,
      expands: true,
      decoration: InputDecoration(
        hintText: AppStrings.current.editorHint,
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 16, height: 1.5),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      child: SelectableText(
        _previewText.isEmpty ? AppStrings.current.editorHint : _previewText,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }
}
