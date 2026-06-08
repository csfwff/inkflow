import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/article.dart';

class MetadataPage extends StatefulWidget {
  final Article article;

  const MetadataPage({super.key, required this.article});

  @override
  State<MetadataPage> createState() => _MetadataPageState();
}

class _MetadataPageState extends State<MetadataPage> {
  late final TextEditingController _tagsCtrl;
  late final TextEditingController _categoriesCtrl;
  late final TextEditingController _permalinkCtrl;
  late final TextEditingController _topImgCtrl;
  late final TextEditingController _coverCtrl;
  late final TextEditingController _excerptCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _authorCtrl;

  late String? _selectedLayout;
  late bool _commentsEnabled;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    final article = widget.article;
    _tagsCtrl = TextEditingController(text: article.tags.join(', '));
    _categoriesCtrl =
        TextEditingController(text: article.categories.join('\n'));
    _permalinkCtrl = TextEditingController(text: article.permalink ?? '');
    _topImgCtrl = TextEditingController(text: article.topImg ?? '');
    _coverCtrl = TextEditingController(text: article.cover ?? '');
    _excerptCtrl = TextEditingController(text: article.excerpt ?? '');
    _descriptionCtrl = TextEditingController(text: article.description ?? '');
    _authorCtrl = TextEditingController(text: article.author ?? '');
    _selectedLayout = article.layout;
    _commentsEnabled = article.comments ?? true;
    _isPublished = article.published ?? true;
  }

  @override
  void dispose() {
    _tagsCtrl.dispose();
    _categoriesCtrl.dispose();
    _permalinkCtrl.dispose();
    _topImgCtrl.dispose();
    _coverCtrl.dispose();
    _excerptCtrl.dispose();
    _descriptionCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  List<String> _parseTags(String text) {
    return text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  List<String> _parseCategories(String text) {
    return text
        .split('\n')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
  }

  String? _emptyToNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _save() {
    final article = widget.article;
    article.tags = _parseTags(_tagsCtrl.text);
    article.categories = _parseCategories(_categoriesCtrl.text);
    article.permalink = _emptyToNull(_permalinkCtrl.text);
    article.topImg = _emptyToNull(_topImgCtrl.text);
    article.cover = _emptyToNull(_coverCtrl.text);
    article.layout = _selectedLayout;
    article.comments = _commentsEnabled;
    article.published = _isPublished;
    article.excerpt = _emptyToNull(_excerptCtrl.text);
    article.description = _emptyToNull(_descriptionCtrl.text);
    article.author = _emptyToNull(_authorCtrl.text);

    Navigator.pop(context, article);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.metadata),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(s.done),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tags & Categories
            _buildSectionTitle(s.tags, Icons.tag),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _tagsCtrl,
              hint: s.tagsHint,
            ),
            const SizedBox(height: 16),

            _buildSectionTitle(s.categories, Icons.folder_outlined),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _categoriesCtrl,
              hint: s.categoriesHint,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Permalink
            _buildSectionTitle(s.permalink, Icons.link),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _permalinkCtrl,
              hint: s.permalinkHint,
            ),
            const SizedBox(height: 16),

            // Images
            _buildSectionTitle(s.topImg, Icons.image),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _topImgCtrl,
              hint: s.topImgHint,
            ),
            const SizedBox(height: 16),

            _buildSectionTitle(s.cover, Icons.image_outlined),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _coverCtrl,
              hint: s.coverHint,
            ),
            const SizedBox(height: 16),

            // Layout
            _buildSectionTitle(s.layout, Icons.dashboard_outlined),
            const SizedBox(height: 8),
            _buildLayoutDropdown(s),
            const SizedBox(height: 16),

            // Switches
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: s.comments,
                      subtitle: 'Allow comments on this post',
                      value: _commentsEnabled,
                      onChanged: (v) => setState(() => _commentsEnabled = v),
                      icon: Icons.comment_outlined,
                    ),
                    const Divider(),
                    _buildSwitchTile(
                      title: s.published,
                      subtitle: 'Make this post publicly visible',
                      value: _isPublished,
                      onChanged: (v) => setState(() => _isPublished = v),
                      icon: Icons.public,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Excerpt & Description
            _buildSectionTitle(s.excerpt, Icons.short_text),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _excerptCtrl,
              hint: s.excerptHint,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildSectionTitle(s.description, Icons.description),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionCtrl,
              hint: s.descriptionHint,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Author
            _buildSectionTitle(s.author, Icons.person_outline),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _authorCtrl,
              hint: s.authorHint,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildLayoutDropdown(AppStrings s) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      initialValue: _selectedLayout,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
      ),
      dropdownColor: colorScheme.surfaceContainerLowest,
      iconEnabledColor: colorScheme.primary,
      iconDisabledColor: colorScheme.onSurfaceVariant,
      items: [
        DropdownMenuItem(value: null, child: Text('Default')),
        DropdownMenuItem(value: 'post', child: Text(s.layoutPost)),
        DropdownMenuItem(value: 'draft', child: Text(s.layoutDraft)),
        DropdownMenuItem(value: 'page', child: Text(s.layoutPage)),
      ],
      onChanged: (v) => setState(() => _selectedLayout = v),
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
