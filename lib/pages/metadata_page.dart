import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../models/article.dart';
import '../services/article_service.dart';
import '../services/image_host/image_host_service.dart';
import '../services/log_service.dart';
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

  /// 上传中状态
  bool _uploading = false;

  /// 初始状态快照，用于检测是否有改动
  late final List<String> _initialTags;
  late final List<String> _initialCategories;
  late final String _initialPermalink;
  late final String _initialTopImg;
  late final String _initialCover;
  late final String _initialExcerpt;
  late final String _initialDescription;
  late final String _initialAuthor;
  late final Map<String, String> _initialCustomFields;

  @override
  void initState() {
    super.initState();
    final article = widget.article;
    _tagsCtrl = TextEditingController();
    _categoriesCtrl = TextEditingController();
    _permalinkCtrl = TextEditingController(text: article.permalink ?? '');
    _topImgCtrl = TextEditingController(text: article.topImg ?? '');
    _coverCtrl = TextEditingController(text: article.cover ?? '');
    _excerptCtrl = TextEditingController(text: article.excerpt ?? '');
    _descriptionCtrl = TextEditingController(text: article.description ?? '');
    _authorCtrl = TextEditingController(text: article.author ?? '');

    _selectedTags = List.from(article.tags);
    _selectedCategories = List.from(article.categories);

    // 记录初始状态快照
    _initialTags = List.from(article.tags);
    _initialCategories = List.from(article.categories);
    _initialPermalink = article.permalink ?? '';
    _initialTopImg = article.topImg ?? '';
    _initialCover = article.cover ?? '';
    _initialExcerpt = article.excerpt ?? '';
    _initialDescription = article.description ?? '';
    _initialAuthor = article.author ?? '';

    // 初始化自定义字段
    _customFields = article.customFields.entries
        .map((e) => _CustomFieldEntry(key: e.key, value: e.value))
        .toList();
    _initialCustomFields = Map.from(article.customFields);

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

  String _resolvePathPattern(
    String pattern, {
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
    final category = article.categories.isNotEmpty
        ? article.categories.first
        : '';
    final pattern = widget.settingsService.settings.permalinkPattern;
    final permalink = _resolvePathPattern(
      pattern,
      slug: slug,
      category: category,
    );
    _permalinkCtrl.text = permalink;
  }

  bool _hasChanges() {
    if (!listEquals(_selectedTags, _initialTags)) return true;
    if (!listEquals(_selectedCategories, _initialCategories)) return true;
    if (_permalinkCtrl.text.trim() != _initialPermalink) return true;
    if (_topImgCtrl.text.trim() != _initialTopImg) return true;
    if (_coverCtrl.text.trim() != _initialCover) return true;
    if (_excerptCtrl.text.trim() != _initialExcerpt) return true;
    if (_descriptionCtrl.text.trim() != _initialDescription) return true;
    if (_authorCtrl.text.trim() != _initialAuthor) return true;

    // 检测自定义字段改动
    final currentCustom = <String, String>{};
    for (final field in _customFields) {
      final k = field.keyCtrl.text.trim();
      final v = field.valueCtrl.text.trim();
      if (k.isNotEmpty) currentCustom[k] = v;
    }
    if (!mapEquals(currentCustom, _initialCustomFields)) return true;

    return false;
  }

  Future<bool> _showDiscardDialog() async {
    final s = AppStrings.current;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.unsavedChanges),
        content: Text(s.unsavedChangesDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.discard),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _save() {
    LogService.instance.logAction('保存元数据', detail: widget.article.title);
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasChanges()) {
          final discard = await _showDiscardDialog();
          if (discard && context.mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
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
                controller: _tagsCtrl,
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
                controller: _categoriesCtrl,
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
              _buildImageField(controller: _topImgCtrl, hint: s.topImgHint),
              const SizedBox(height: 16),

              _buildSectionTitle(s.cover, Icons.image_outlined),
              const SizedBox(height: 8),
              _buildImageField(controller: _coverCtrl, hint: s.coverHint),
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
              _buildTextField(controller: _authorCtrl, hint: s.authorHint),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildImageField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(controller: controller, hint: hint),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _uploading ? null : () => _showImagePicker(controller),
          icon: Icon(
            _uploading ? Icons.hourglass_top : Icons.image_outlined,
            size: 20,
          ),
          tooltip: AppStrings.current.selectImage,
        ),
      ],
    );
  }

  Future<void> _showImagePicker(TextEditingController controller) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _ImagePickerSheet(articleBody: widget.article.bodyContent);
      },
    );
    if (result == null || result.isEmpty) return;

    if (result == 'gallery' || result == 'camera') {
      final source = result == 'gallery'
          ? ImageSource.gallery
          : ImageSource.camera;
      await _pickAndUploadImage(controller, source);
    } else {
      // 从文章选择的图片 URL
      controller.text = result;
    }
  }

  Future<void> _pickAndUploadImage(
    TextEditingController controller,
    ImageSource source,
  ) async {
    final s = AppStrings.current;
    final imageHost = ImageHostService(
      settings: widget.settingsService.settings,
    );
    if (!imageHost.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.imageHostNotConfigured)));
      }
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 2048);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final result = await imageHost.uploadWithCompress(bytes, file.name);
      if (result.success && result.url != null) {
        controller.text = result.url!;

        // Show compression effect if compressed
        if (result.wasCompressed && mounted) {
          final compressResult = result.compressResult!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${s.imageCompressResult}: ${compressResult.originalSizeFormatted} → ${compressResult.compressedSizeFormatted} '
                '(-${compressResult.ratio.toStringAsFixed(0)}%)',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? s.imageUploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Metadata',
        context: '上传元数据图片失败',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.imageUploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLowest,
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLowest,
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
    required TextEditingController controller,
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
            ...selected.map(
              (tag) => Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => onRemove(tag),
                visualDensity: VisualDensity.compact,
              ),
            ),
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
          controller: controller,
          decoration: InputDecoration(
            hintText: s.addNewHint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
            suffixIcon: const Icon(Icons.add, size: 18),
          ),
          style: const TextStyle(fontSize: 14),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              onAdd(trimmed);
              controller.clear();
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
                  : SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.allOptions.map((option) {
                          final isSelected = _tempSelected.contains(option);
                          return FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _tempSelected.add(option);
                                } else {
                                  _tempSelected.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// 图片选择底部面板
class _ImagePickerSheet extends StatefulWidget {
  final String articleBody;

  const _ImagePickerSheet({required this.articleBody});

  @override
  State<_ImagePickerSheet> createState() => _ImagePickerSheetState();
}

class _ImagePickerSheetState extends State<_ImagePickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<String> _articleImages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _extractArticleImages();
  }

  void _extractArticleImages() {
    final regex = RegExp(r'!\[.*?\]\((https?://[^\)]+)\)');
    _articleImages = regex
        .allMatches(widget.articleBody)
        .map((m) => m.group(1)!)
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    s.selectImage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(icon: const Icon(Icons.cloud_upload), text: s.uploadImage),
                Tab(icon: const Icon(Icons.photo_library), text: s.fromArticle),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUploadTab(scrollController),
                  _buildArticleTab(scrollController),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUploadTab(ScrollController scrollController) {
    final s = AppStrings.current;
    final canUseCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library),
          title: Text(s.uploadImage),
          subtitle: const Text('Gallery'),
          onTap: () => Navigator.pop(context, 'gallery'),
        ),
        if (canUseCamera)
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text(s.uploadImage),
            subtitle: const Text('Camera'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
      ],
    );
  }

  Widget _buildArticleTab(ScrollController scrollController) {
    final s = AppStrings.current;
    if (_articleImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              s.noImagesInArticle,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _articleImages.length,
      itemBuilder: (ctx, index) {
        final url = _articleImages[index];
        return GestureDetector(
          onTap: () => Navigator.pop(context, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }
}
