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
  bool _previewMode = false;
  bool _dirty = false;
  bool _updatingFields = false;
  String _previewText = '';
  Article? _editingArticle;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_handleTitleChanged);
    _contentCtrl.addListener(_handleContentChanged);
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

  void _handleTitleChanged() {
    if (_updatingFields) return;
    if (!_dirty) setState(() => _dirty = true);
  }

  void _handleContentChanged() {
    if (_updatingFields) return;
    setState(() {
      _previewText = _contentCtrl.text;
      _dirty = true;
    });
  }

  Future<void> _loadArticle(int id) async {
    final article = await articleService.getById(id);
    if (article != null && mounted) {
      _updatingFields = true;
      setState(() {
        _editingArticle = article;
        _titleCtrl.text = article.title;
        _contentCtrl.text = article.content;
        _selectedDate = article.date;
        _previewText = article.content;
        _dirty = false;
      });
      _updatingFields = false;
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
      setState(() {
        _selectedDate = picked;
        _dirty = true;
      });
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
    final saved = await _saveDraft(showMessage: false);
    if (!saved || !mounted || _editingArticle == null) return;

    final result = await Navigator.push<Article>(
      context,
      MaterialPageRoute(
        builder: (_) => MetadataPage(article: _editingArticle!),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _editingArticle = result;
        _dirty = true;
      });
    }
  }

  Future<bool> _saveDraft({bool showMessage = true}) async {
    final s = AppStrings.current;
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.titleHint)),
      );
      return false;
    }

    final article = _buildArticle();
    if (_editingArticle != null) {
      article.updatedAt = DateTime.now();
      await articleService.update(article);
      _editingArticle = article;
    } else {
      final id = await articleService.insert(article);
      _editingArticle = await articleService.getById(id);
    }

    if (!mounted) return false;
    setState(() => _dirty = false);

    if (showMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.articleSaved)),
      );
    }
    return true;
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

    final targetStatus =
        drafts ? ArticleStatus.repoDraft : ArticleStatus.synced;
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
        _editingArticle = article;
      } else {
        final id = await articleService.insert(article);
        _editingArticle = await articleService.getById(id);
      }

      if (mounted) setState(() => _dirty = false);
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
        title: Text(_editingArticle == null ? s.newArticle : s.editorTitle),
        actions: _buildAppBarActions(wide),
      ),
      body: SafeArea(child: wide ? _buildWide() : _buildNarrow()),
    );
  }

  List<Widget> _buildAppBarActions(bool wide) {
    final s = AppStrings.current;
    if (_publishing) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    return [
      IconButton(
        onPressed: _openMetadata,
        icon: const Icon(Icons.tune),
        tooltip: s.metadata,
      ),
      _ActionButton(
        wide: wide,
        icon: Icons.save_outlined,
        label: s.saveDraft,
        onPressed: () => _saveDraft(),
      ),
      _ActionButton(
        wide: wide,
        icon: Icons.drafts_outlined,
        label: s.pushToDraft,
        onPressed: () => _publish(drafts: true),
      ),
      _ActionButton(
        wide: wide,
        icon: Icons.cloud_upload_outlined,
        label: s.publish,
        onPressed: () => _publish(),
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildNarrow() {
    return Column(
      children: [
        _buildTitlePanel(),
        _buildToolbar(),
        _buildModeSwitch(),
        Expanded(
          child: _previewMode
              ? _buildPreviewSurface(padding: const EdgeInsets.all(16))
              : _buildEditorSurface(padding: const EdgeInsets.all(16)),
        ),
      ],
    );
  }

  Widget _buildWide() {
    return Column(
      children: [
        _buildTitlePanel(),
        _buildToolbar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildEditorSurface(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                ),
              ),
              VerticalDivider(width: 1),
              Expanded(
                child: _buildPreviewSurface(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitlePanel() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: AppStrings.current.titleHint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _DatePill(
                    label: _formatDate(_selectedDate),
                    onTap: _pickDate,
                  ),
                  _EditorPill(
                    icon: _statusIcon,
                    label: _statusLabel,
                    color: _statusColor,
                  ),
                  _EditorPill(
                    icon: _dirty ? Icons.circle : Icons.check_circle_outline,
                    label: _dirty
                        ? _label('未保存', 'Unsaved')
                        : _label('已保存', 'Saved'),
                    color: _dirty
                        ? const Color(0xFF9A6A1F)
                        : const Color(0xFF2F7D57),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom:
              BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxWidth),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _ToolButton(
                  icon: Icons.title,
                  tooltip: _label('插入标题', 'Insert heading'),
                  onPressed: () => _insertLine('## ', _label('小标题', 'Heading')),
                ),
                _ToolButton(
                  icon: Icons.format_bold,
                  tooltip: _label('加粗', 'Bold'),
                  onPressed: () =>
                      _insertMarkdown('**', '**', _label('重点', 'bold')),
                ),
                _ToolButton(
                  icon: Icons.format_italic,
                  tooltip: _label('斜体', 'Italic'),
                  onPressed: () =>
                      _insertMarkdown('*', '*', _label('强调', 'italic')),
                ),
                _ToolButton(
                  icon: Icons.link,
                  tooltip: _label('插入链接', 'Insert link'),
                  onPressed: () => _insertMarkdown(
                    '[',
                    '](https://example.com)',
                    _label('链接文字', 'link text'),
                  ),
                ),
                _ToolButton(
                  icon: Icons.format_quote,
                  tooltip: _label('引用', 'Quote'),
                  onPressed: () => _insertLine('> ', _label('引用内容', 'Quote')),
                ),
                _ToolButton(
                  icon: Icons.code,
                  tooltip: _label('代码块', 'Code block'),
                  onPressed: () =>
                      _insertBlock('```\n${_label('代码', 'code')}\n```'),
                ),
                _ToolButton(
                  icon: Icons.image_outlined,
                  tooltip: _label('插入图片', 'Insert image'),
                  onPressed: () => _insertBlock(
                    '![${_label('图片描述', 'alt text')}](https://example.com/image.png)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.edit_outlined),
            label: Text(_label('编辑', 'Edit')),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.visibility_outlined),
            label: Text(_label('预览', 'Preview')),
          ),
        ],
        selected: {_previewMode},
        onSelectionChanged: (value) {
          setState(() => _previewMode = value.first);
        },
      ),
    );
  }

  Widget _buildEditorSurface({required EdgeInsets padding}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: TextField(
          controller: _contentCtrl,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: AppStrings.current.editorHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.all(18),
          ),
          style: const TextStyle(fontSize: 16, height: 1.55),
        ),
      ),
    );
  }

  Widget _buildPreviewSurface({required EdgeInsets padding}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: _previewText.trim().isEmpty
            ? Center(
                child: Text(
                  AppStrings.current.editorHint,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: _buildPreviewContent(_previewText),
              ),
      ),
    );
  }

  Widget _buildPreviewContent(String text) {
    final children = <Widget>[];
    final codeLines = <String>[];
    var inCode = false;

    for (final line in text.split('\n')) {
      if (line.trim().startsWith('```')) {
        if (inCode) {
          children.add(_PreviewCodeBlock(code: codeLines.join('\n')));
          codeLines.clear();
          inCode = false;
        } else {
          inCode = true;
        }
        continue;
      }

      if (inCode) {
        codeLines.add(line);
        continue;
      }

      children.add(_renderPreviewLine(line));
    }

    if (codeLines.isNotEmpty) {
      children.add(_PreviewCodeBlock(code: codeLines.join('\n')));
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _renderPreviewLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return const SizedBox(height: 12);

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (trimmed.startsWith('### ')) {
      return _PreviewText(
        text: trimmed.substring(4),
        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      );
    }
    if (trimmed.startsWith('## ')) {
      return _PreviewText(
        text: trimmed.substring(3),
        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      );
    }
    if (trimmed.startsWith('# ')) {
      return _PreviewText(
        text: trimmed.substring(2),
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      );
    }
    if (trimmed.startsWith('>')) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border:
              Border(left: BorderSide(color: colorScheme.primary, width: 3)),
        ),
        child: Text(
          trimmed.substring(1).trim(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    }
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: colorScheme.primary)),
            Expanded(
              child: Text(
                trimmed.substring(2),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return _PreviewText(text: line);
  }

  void _insertMarkdown(String prefix, String suffix, String placeholder) {
    final value = _contentCtrl.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selected =
        start == end ? placeholder : value.text.substring(start, end);
    final replacement = '$prefix$selected$suffix';
    final nextText = value.text.replaceRange(start, end, replacement);
    final selectionStart = start + prefix.length;
    final selectionEnd = selectionStart + selected.length;

    _contentCtrl.value = value.copyWith(
      text: nextText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
      composing: TextRange.empty,
    );
  }

  void _insertLine(String prefix, String placeholder) {
    final value = _contentCtrl.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selected =
        start == end ? placeholder : value.text.substring(start, end);
    final needsNewLine = start > 0 && value.text[start - 1] != '\n';
    final replacement = '${needsNewLine ? '\n' : ''}$prefix$selected';
    final nextText = value.text.replaceRange(start, end, replacement);
    final selectionStart = start + (needsNewLine ? 1 : 0) + prefix.length;
    final selectionEnd = selectionStart + selected.length;

    _contentCtrl.value = value.copyWith(
      text: nextText,
      selection: TextSelection(
        baseOffset: selectionStart,
        extentOffset: selectionEnd,
      ),
      composing: TextRange.empty,
    );
  }

  void _insertBlock(String block) {
    final value = _contentCtrl.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final needsLeadingNewLine = start > 0 && value.text[start - 1] != '\n';
    final needsTrailingNewLine =
        end < value.text.length && value.text[end] != '\n';
    final replacement =
        '${needsLeadingNewLine ? '\n' : ''}$block${needsTrailingNewLine ? '\n' : ''}';
    final nextText = value.text.replaceRange(start, end, replacement);
    final cursor = start + replacement.length;

    _contentCtrl.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  String get _statusLabel {
    final s = AppStrings.current;
    final article = _editingArticle;
    if (article == null) return s.draftStatus;

    return switch (article.status) {
      ArticleStatus.synced => s.synced,
      ArticleStatus.repoDraft => s.repoDraft,
      ArticleStatus.draft when article.githubSha != null => s.remoteDeleted,
      ArticleStatus.draft => s.draftStatus,
    };
  }

  IconData get _statusIcon {
    final article = _editingArticle;
    if (article == null) return Icons.edit_note;

    return switch (article.status) {
      ArticleStatus.synced => Icons.cloud_done,
      ArticleStatus.repoDraft => Icons.drafts_outlined,
      ArticleStatus.draft when article.githubSha != null =>
        Icons.cloud_off_outlined,
      ArticleStatus.draft => Icons.edit_note,
    };
  }

  Color get _statusColor {
    final article = _editingArticle;
    if (article == null) return const Color(0xFF6F7672);

    return switch (article.status) {
      ArticleStatus.synced => const Color(0xFF2F7D57),
      ArticleStatus.repoDraft => const Color(0xFF9A6A1F),
      ArticleStatus.draft when article.githubSha != null =>
        const Color(0xFFB64B45),
      ArticleStatus.draft => const Color(0xFF6F7672),
    };
  }

  String _label(String zh, String en) {
    return identical(AppStrings.current, AppStrings.zh) ? zh : en;
  }
}

class _ActionButton extends StatelessWidget {
  final bool wide;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.wide,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: label,
      );
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DatePill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _EditorPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _EditorPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _PreviewText({required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SelectableText(
        text,
        style: style ?? const TextStyle(fontSize: 16, height: 1.55),
      ),
    );
  }
}

class _PreviewCodeBlock extends StatelessWidget {
  final String code;

  const _PreviewCodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}
