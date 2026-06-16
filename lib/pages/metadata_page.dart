import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import '../services/settings_service.dart';

class MetadataPage extends StatefulWidget {
  final Article article;
  final SettingsService settingsService;
  final ArticleService articleService;

  const MetadataPage({
    super.key,
    required this.article,
    required this.settingsService,
    required this.articleService,
  });

  @override
  State<MetadataPage> createState() => _MetadataPageState();
}

/// 自定义字段条目
class _CustomFieldEntry {
  String key;
  String value;
  late final TextEditingController keyCtrl;
  late final TextEditingController valueCtrl;

  _CustomFieldEntry({required this.key, required this.value}) {
    keyCtrl = TextEditingController(text: key);
    valueCtrl = TextEditingController(text: value);
  }

  void dispose() {
    keyCtrl.dispose();
    valueCtrl.dispose();
  }
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

  /// 自定义字段列表（key, value, keyCtrl, valueCtrl）
  late List<_CustomFieldEntry> _customFields;

  /// 当前文章的标签和分类列表
  late List<String> _selectedTags;
  late List<String> _selectedCategories;

  /// 数据库中已有的标签和分类
  List<String> _allTags = [];
  List<String> _allCategories = [];

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

    _selectedTags = List.from(article.tags);
    _selectedCategories = List.from(article.categories);

    // 初始化自定义字段
    _customFields = article.customFields.entries
        .map((e) => _CustomFieldEntry(
              key: e.key,
              value: e.value,
            ))
        .toList();

    // 加载已有的标签和分类
    _loadTagsAndCategories();
  }

  Future<void> _loadTagsAndCategories() async {
    final tags = await widget.articleService.getAllTagNames();
    final categories = await widget.articleService.getAllCategoryNames();
    if (mounted) {
      setState(() {
        _allTags = tags;
        _allCategories = categories;
      });
    }
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
    for (final field in _customFields) {
      field.dispose();
    }
    super.dispose();
  }

  String? _emptyToNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _resolvePathPattern(String pattern, {
    required String slug,
    String category = '',
  }) {
    final d = widget.article.date;
    return pattern
        .replaceAll('{year}', '${d.year}')
        .replaceAll('{month}', d.month.toString().padLeft(2, '0'))
        .replaceAll('{day}', d.day.toString().padLeft(2, '0'))
        .replaceAll('{category}', category)
        .replaceAll('{slug}', slug)
        .replaceAll('{timestamp}', '${d.millisecondsSinceEpoch ~/ 1000}');
  }

  void _generatePermalink() {
    final article = widget.article;
    final slug = article.slug.isNotEmpty ? article.slug : 'post';
    final category = article.categories.isNotEmpty ? article.categories.first : '';
    final pattern = widget.settingsService.settings.permalinkPattern;
    final permalink = _resolvePathPattern(pattern, slug: slug, category: category);
    _permalinkCtrl.text = permalink;
  }

  void _save() {
    final article = widget.article;
    article.tags = List.from(_selectedTags);
    article.categories = List.from(_selectedCategories);
    article.permalink = _emptyToNull(_permalinkCtrl.text);
    article.topImg = _emptyToNull(_topImgCtrl.text);
    article.cover = _emptyToNull(_coverCtrl.text);
    article.excerpt = _emptyToNull(_excerptCtrl.text);
    article.description = _emptyToNull(_descriptionCtrl.text);
    article.author = _emptyToNull(_authorCtrl.text);

    // 保存自定义字段
    final customFields = <String, String>{};
    for (final field in _customFields) {
      final k = field.keyCtrl.text.trim();
      final v = field.valueCtrl.text.trim();
      if (k.isNotEmpty) {
        customFields[k] = v;
      }
    }
    article.customFields = customFields;

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
            // Tags
            _buildSectionTitle(s.tags, Icons.tag),
            const SizedBox(height: 8),
            _buildChipSelector(
              selected: _selectedTags,
              allOptions: _allTags,
              onAdd: (value) {
                setState(() {
                  if (!_selectedTags.contains(value)) {
                    _selectedTags.add(value);
                  }
                });
              },
              onRemove: (value) {
                setState(() {
                  _selectedTags.remove(value);
                });
              },
              onShowAll: () => _showTagSelector(),
            ),
            const SizedBox(height: 16),

            // Categories
            _buildSectionTitle(s.categories, Icons.folder_outlined),
            const SizedBox(height: 8),
            _buildChipSelector(
              selected: _selectedCategories,
              allOptions: _allCategories,
              onAdd: (value) {
                setState(() {
                  if (!_selectedCategories.contains(value)) {
                    _selectedCategories.add(value);
                  }
                });
              },
              onRemove: (value) {
                setState(() {
                  _selectedCategories.remove(value);
                });
              },
              onShowAll: () => _showCategorySelector(),
            ),
            const SizedBox(height: 16),

            // Permalink
            _buildSectionTitle(s.permalink, Icons.link),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _permalinkCtrl,
                    hint: s.permalinkHint,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _generatePermalink,
                  icon: const Icon(Icons.auto_fix_high, size: 20),
                  tooltip: s.generatePermalink,
                ),
              ],
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
            const SizedBox(height: 24),

            // 自定义字段
            _buildSectionTitle(s.customFields, Icons.tune),
            const SizedBox(height: 8),
            ..._buildCustomFieldRows(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addCustomField,
              icon: const Icon(Icons.add, size: 18),
              label: Text(s.addCustomField),
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

  void _addCustomField() {
    setState(() {
      _customFields.add(_CustomFieldEntry(key: '', value: ''));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index].dispose();
      _customFields.removeAt(index);
    });
  }

  List<Widget> _buildCustomFieldRows() {
    final s = AppStrings.current;
    return List.generate(_customFields.length, (index) {
      final field = _customFields[index];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: field.keyCtrl,
                decoration: InputDecoration(
                  hintText: s.customFieldKeyHint,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextField(
                controller: field.valueCtrl,
                decoration: InputDecoration(
                  hintText: s.customFieldValueHint,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _removeCustomField(index),
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChipSelector({
    required List<String> selected,
    required List<String> allOptions,
    required ValueChanged<String> onAdd,
    required ValueChanged<String> onRemove,
    required VoidCallback onShowAll,
  }) {
    final s = AppStrings.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ...selected.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onRemove(tag),
                  visualDensity: VisualDensity.compact,
                )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: Text(s.selectFromExisting),
              onPressed: onShowAll,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          decoration: InputDecoration(
            hintText: s.addNewHint,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerLowest,
            suffixIcon: const Icon(Icons.add, size: 18),
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              onAdd(trimmed);
            }
          },
        ),
      ],
    );
  }

  void _showTagSelector() {
    final s = AppStrings.current;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _SelectorSheet(
          title: s.selectTags,
          allOptions: _allTags,
          selected: _selectedTags,
          onChanged: (newSelected) {
            setState(() {
              _selectedTags = newSelected;
            });
          },
        );
      },
    );
  }

  void _showCategorySelector() {
    final s = AppStrings.current;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _SelectorSheet(
          title: s.selectCategories,
          allOptions: _allCategories,
          selected: _selectedCategories,
          onChanged: (newSelected) {
            setState(() {
              _selectedCategories = newSelected;
            });
          },
        );
      },
    );
  }
}

class _SelectorSheet extends StatefulWidget {
  final String title;
  final List<String> allOptions;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _SelectorSheet({
    required this.title,
    required this.allOptions,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_SelectorSheet> createState() => _SelectorSheetState();
}

class _SelectorSheetState extends State<_SelectorSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onChanged(_tempSelected);
                      Navigator.pop(context);
                    },
                    child: Text(AppStrings.current.done),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.allOptions.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.current.noItemsAvailable,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: widget.allOptions.length,
                      itemBuilder: (ctx, index) {
                        final option = widget.allOptions[index];
                        final isSelected = _tempSelected.contains(option);
                        return CheckboxListTile(
                          title: Text(option),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _tempSelected.add(option);
                              } else {
                                _tempSelected.remove(option);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
