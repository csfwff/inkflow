import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/github_service.dart';
import '../services/image_host/image_host_service.dart';
import '../widgets/responsive.dart';
import 'metadata_page.dart';

/// 窄屏吸顶工具条的固定高度（40 的按钮 + 上下各 8 内边距 + 底部分隔线，留一点余量）。
const double _kEditorToolbarHeight = 58;

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
  bool _uploading = false;
  bool _previewMode = false;
  bool _dirty = false;
  bool _updatingFields = false;
  String _previewText = '';
  String _originalFrontmatter = ''; // 保留原始 frontmatter
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
      final body = article.bodyContent;
      // 保留原始 frontmatter（含不支持的字段）
      final fmMatch = RegExp(r'^---\s*\n(.*?)\n---\s*\n', dotAll: true).firstMatch(article.content);
      _updatingFields = true;
      setState(() {
        _editingArticle = article;
        _originalFrontmatter = fmMatch != null ? fmMatch.group(1)! : '';
        _titleCtrl.text = article.title;
        _contentCtrl.text = body;
        _selectedDate = article.date;
        _previewText = body;
        _dirty = false;
      });
      _updatingFields = false;
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        // 保留 Unicode 字母/数字（含中文），去掉其余符号；空白转连字符。
        // 这一步已滤掉所有跨平台非法字符：\ / : * ? " < > | 及控制符等。
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s-]', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// 由标题生成文件系统安全的 slug：
  /// 非法字符已由 [_slugify] 的白名单滤除；此处再避开 Windows 保留设备名
  /// （CON/NUL/COM1… 用作文件名会报错），并对空结果用时间戳兜底，避免只剩 ".md"。
  String _safeSlug(String title) {
    var slug = _slugify(title);
    const reserved = {
      'con', 'prn', 'aux', 'nul',
      'com1', 'com2', 'com3', 'com4', 'com5', 'com6', 'com7', 'com8', 'com9',
      'lpt1', 'lpt2', 'lpt3', 'lpt4', 'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
    };
    if (reserved.contains(slug)) {
      slug = 'post-$slug';
    }
    if (slug.isEmpty) {
      slug = 'post-${_selectedDate.millisecondsSinceEpoch ~/ 1000}';
    }
    return slug;
  }

  String _resolvePathPattern(String pattern, {
    required String slug,
    String category = '',
    bool appendSlug = true,
  }) {
    final d = _selectedDate;
    final result = pattern
        .replaceAll('{year}', '${d.year}')
        .replaceAll('{month}', d.month.toString().padLeft(2, '0'))
        .replaceAll('{day}', d.day.toString().padLeft(2, '0'))
        .replaceAll('{category}', category)
        .replaceAll('{slug}', slug)
        .replaceAll('{timestamp}', '${d.millisecondsSinceEpoch ~/ 1000}');
    return appendSlug ? '$result/$slug.md' : result;
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
    final slug = _safeSlug(title);
    final category = _editingArticle?.categories.isNotEmpty == true
        ? _editingArticle!.categories.first
        : '';
    final filePath = _resolvePathPattern(
      settingsService.settings.githubPathPattern,
      slug: slug,
      category: category,
    );
    final permalink = _resolvePathPattern(
      settingsService.settings.permalinkPattern,
      slug: slug,
      category: category,
      appendSlug: false,
    );

    // 合并：原始 frontmatter + 编辑后的正文
    final fullContent = _originalFrontmatter.isNotEmpty
        ? '---\n$_originalFrontmatter\n---\n${_contentCtrl.text}'
        : _contentCtrl.text;

    return Article(
      id: _editingArticle?.id,
      title: title,
      content: fullContent,
      date: _selectedDate,
      slug: slug,
      status: _editingArticle?.status ?? ArticleStatus.draft,
      filePath: filePath,
      githubSha: _editingArticle?.githubSha,
      createdAt: _editingArticle?.createdAt,
      tags: _editingArticle?.tags ?? [],
      categories: _editingArticle?.categories ?? [],
      permalink: permalink,
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
      branch: settings.githubBranch,
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

  Future<void> _pickAndUploadImage() async {
    // Check image host config
    final imageHost = ImageHostService(settings: settingsService.settings);
    if (!imageHost.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_label('请先在设置中配置图床', 'Please configure image host in settings'))),
      );
      return;
    }

    // Show source picker (gallery / camera)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_label('从相册选择', 'Gallery')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (Theme.of(ctx).platform == TargetPlatform.android ||
                Theme.of(ctx).platform == TargetPlatform.iOS)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(_label('拍照', 'Camera')),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Pick image
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 2048);
    if (file == null) return;

    if (!mounted) return;
    setState(() => _uploading = true);

    // Upload
    final bytes = await file.readAsBytes();
    final result = await imageHost.upload(bytes, file.name);

    if (!mounted) return;
    setState(() => _uploading = false);

    if (result.success && result.url != null) {
      _insertBlock('![${file.name}](${result.url})');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_label('上传失败', 'Upload failed')}: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // 内容区至少填满「视口 - 吸顶工具条」，保证空文档也有完整的编辑/预览区域，
        // 内容变长后整页可上滑、工具条吸顶。
        final fillHeight =
            (constraints.maxHeight - _kEditorToolbarHeight).clamp(0.0, double.infinity);
        return CustomScrollView(
          slivers: [
            // 标题、编辑/预览切换：随页面一起上滑
            SliverToBoxAdapter(child: _buildTitlePanel()),
            SliverToBoxAdapter(child: _buildModeSwitch()),
            // 工具条：吸顶
            SliverPersistentHeader(
              pinned: true,
              delegate: _ToolbarHeaderDelegate(
                height: _kEditorToolbarHeight,
                child: _buildToolbar(),
              ),
            ),
            SliverToBoxAdapter(
              child: _previewMode
                  ? _buildPreviewBody(minHeight: fillHeight)
                  : _buildEditorBody(minHeight: fillHeight),
            ),
          ],
        );
      },
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
                _HeadingButton(
                  label: _label,
                  contentCtrl: _contentCtrl,
                ),
                _ToolButton(
                  icon: Icons.format_bold,
                  tooltip: _label('加粗', 'Bold'),
                  onPressed: () =>
                      _toggleMarkdown('**', '**', _label('重点', 'bold')),
                ),
                _ToolButton(
                  icon: Icons.format_italic,
                  tooltip: _label('斜体', 'Italic'),
                  onPressed: () =>
                      _toggleMarkdown('*', '*', _label('强调', 'italic')),
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
                  onPressed: () => _toggleLine('> ', _label('引用内容', 'Quote')),
                ),
                _ToolButton(
                  icon: Icons.code,
                  tooltip: _label('代码块', 'Code block'),
                  onPressed: () =>
                      _insertBlock('```\n${_label('代码', 'code')}\n```'),
                ),
                _ToolButton(
                  icon: _uploading
                      ? Icons.hourglass_top
                      : Icons.image_outlined,
                  tooltip: _label('插入图片', 'Insert image'),
                  onPressed: _uploading ? null : () => _pickAndUploadImage(),
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
    return Padding(
      padding: padding,
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
          contentPadding: const EdgeInsets.all(4),
        ),
        style: const TextStyle(fontSize: 16, height: 1.55),
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
            : Markdown(
                data: _previewText,
                padding: const EdgeInsets.all(22),
                selectable: true,
              ),
      ),
    );
  }

  // 窄屏：无边框、随内容增高的编辑区。内容超出视口时整页滚动、工具条吸顶；
  // 内容较短时用 minHeight 撑满，保证有完整的可点按编辑区域。
  Widget _buildEditorBody({required double minHeight}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: TextField(
          controller: _contentCtrl,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: AppStrings.current.editorHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            isCollapsed: true,
          ),
          style: const TextStyle(fontSize: 16, height: 1.55),
        ),
      ),
    );
  }

  // 窄屏预览：随内容增高（MarkdownBody 不自带滚动），与编辑区共用整页滚动。
  Widget _buildPreviewBody({required double minHeight}) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_previewText.trim().isEmpty) {
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: Center(
          child: Text(
            AppStrings.current.editorHint,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: MarkdownBody(
          data: _previewText,
          selectable: true,
        ),
      ),
    );
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

  void _toggleMarkdown(String prefix, String suffix, String placeholder) {
    final value = _contentCtrl.value;
    final text = value.text;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    // Check if the selected text is already wrapped: prefix + content + suffix
    final beforeStart = start - prefix.length;
    final afterEnd = end + suffix.length;
    if (beforeStart >= 0 &&
        afterEnd <= text.length &&
        text.substring(beforeStart, start) == prefix &&
        text.substring(end, afterEnd) == suffix) {
      // Already wrapped → unwrap
      final inner = text.substring(start, end);
      final nextText =
          text.replaceRange(beforeStart, afterEnd, inner);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection(
          baseOffset: beforeStart,
          extentOffset: beforeStart + inner.length,
        ),
        composing: TextRange.empty,
      );
    } else {
      // Not wrapped → wrap (same as _insertMarkdown)
      final selected = start == end ? placeholder : text.substring(start, end);
      final replacement = '$prefix$selected$suffix';
      final nextText = text.replaceRange(start, end, replacement);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: start + prefix.length + selected.length,
        ),
        composing: TextRange.empty,
      );
    }
  }

  void _toggleLine(String prefix, String placeholder) {
    final value = _contentCtrl.value;
    final text = value.text;
    final selection = value.selection;
    final cursor = selection.isValid ? selection.start : text.length;

    // Find current line boundaries
    final lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0) + 1;
    int lineEnd = text.indexOf('\n', cursor);
    if (lineEnd < 0) lineEnd = text.length;

    final line = text.substring(lineStart, lineEnd);

    if (line.startsWith(prefix)) {
      // Already has prefix → remove it
      final newLine = line.substring(prefix.length);
      final nextText = text.replaceRange(lineStart, lineEnd, newLine);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: lineStart + newLine.length),
        composing: TextRange.empty,
      );
    } else {
      // No prefix → add it
      final needsNewLine = lineStart > 0;
      final selected = line.isEmpty ? placeholder : line;
      final replacement =
          '${needsNewLine && lineStart > 0 ? '' : ''}$prefix$selected';
      final nextText = text.replaceRange(lineStart, lineEnd, replacement);
      _contentCtrl.value = value.copyWith(
        text: nextText,
        selection: TextSelection(
          baseOffset: lineStart + prefix.length,
          extentOffset: lineStart + prefix.length + selected.length,
        ),
        composing: TextRange.empty,
      );
    }
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

class _ToolbarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _ToolbarHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // 工具条自带背景与底部分隔线，铺满吸顶高度即可。
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _ToolbarHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
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
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
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

class _HeadingButton extends StatelessWidget {
  final TextEditingController contentCtrl;
  final String Function(String zh, String en) label;

  const _HeadingButton({required this.contentCtrl, required this.label});

  /// Returns (startOffset, currentLevel) for the line under cursor.
  /// currentLevel 0 = no heading, 1-6 = H1-H6.
  (int, int) _detectHeading() {
    final text = contentCtrl.text;
    if (text.isEmpty) return (0, 0);
    final cursor = contentCtrl.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return (text.length, 0);

    // Find line start
    final searchFrom = cursor > 0 ? cursor - 1 : 0;
    int lineStart = text.lastIndexOf('\n', searchFrom) + 1;
    // Find line end
    int lineEnd = text.indexOf('\n', cursor);
    if (lineEnd < 0) lineEnd = text.length;

    if (lineStart < 0 || lineStart > lineEnd) return (0, 0);
    final line = text.substring(lineStart, lineEnd);
    final match = RegExp(r'^(#{1,4})\s').matchAsPrefix(line);
    if (match == null) return (lineStart, 0);
    return (lineStart, match.group(1)!.length);
  }

  void _toggleHeading() {
    final (lineStart, level) = _detectHeading();
    final text = contentCtrl.text;

    String newLine;
    int newCursorOffset;

    if (level == 0) {
      // No heading → insert H1
      final lineEnd = text.indexOf('\n', lineStart);
      final end = lineEnd < 0 ? text.length : lineEnd;
      final line = text.substring(lineStart, end);
      newLine = '# $line';
      newCursorOffset = lineStart + 2; // after "# "
    } else if (level < 4) {
      // H1-H3 → bump up one level
      final lineEnd = text.indexOf('\n', lineStart);
      final end = lineEnd < 0 ? text.length : lineEnd;
      final line = text.substring(lineStart, end);
      final oldPrefix = '${'#' * level} ';
      final newPrefix = '${'#' * (level + 1)} ';
      newLine = newPrefix + line.substring(oldPrefix.length);
      newCursorOffset = lineStart + newPrefix.length;
    } else {
      // H4 → clear heading
      final lineEnd = text.indexOf('\n', lineStart);
      final end = lineEnd < 0 ? text.length : lineEnd;
      final line = text.substring(lineStart, end);
      newLine = line.substring(5); // remove "#### "
      newCursorOffset = lineStart;
    }

    final nextText = text.replaceRange(lineStart, text.indexOf('\n', lineStart) < 0 ? text.length : text.indexOf('\n', lineStart), newLine);
    contentCtrl.value = contentCtrl.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (_, level) = _detectHeading();
    final displayLevel = level == 0 ? '' : '$level';

    return SizedBox(
      width: 40,
      height: 40,
      child: TextButton(
        onPressed: _toggleHeading,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Transform.translate(
              offset: const Offset(0, -2),
              child: Text('H',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).iconTheme.color,
                  )),
            ),
            if (displayLevel.isNotEmpty)
              Text(displayLevel,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).iconTheme.color,
                  )),
          ],
        ),
      ),
    );
  }
}
