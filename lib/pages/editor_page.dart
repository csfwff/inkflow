import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../services/github_service.dart';
import '../widgets/responsive.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _publishing = false;
  String _previewText = '';

  @override
  void initState() {
    super.initState();
    _contentCtrl.addListener(() {
      setState(() => _previewText = _contentCtrl.text);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _buildFrontmatter() {
    final title = _titleCtrl.text;
    final date = _formatDateTime(_selectedDate);
    return '---\ntitle: $title\ndate: $date\n---\n';
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime d) {
    return '${_formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
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

  Future<void> _publish() async {
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

    final slug = _slugify(title);
    final year = _selectedDate.year.toString();
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final fileName = '$year/$month/$slug.md';

    final frontmatter = _buildFrontmatter();
    final fullContent = frontmatter + _contentCtrl.text;

    final service = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
    );

    final result = await service.createPost(
      fileName: fileName,
      content: fullContent,
      commitMessage: 'post: $title',
    );

    if (!mounted) return;
    setState(() => _publishing = false);

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
          else
            TextButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.cloud_upload),
              label: Text(s.publish),
            ),
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
