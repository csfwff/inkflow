import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/article_url_service.dart';
import '../services/github_service.dart';
import '../services/log_service.dart';
import '../services/sync_service.dart';
import '../widgets/responsive.dart';
import 'article_web_view_page.dart';
import 'editor_page.dart';
import 'friend_link_page.dart';
import 'settings_page.dart';

enum _ArticleFilter { all, draft, synced, repoDraft }

enum _ArticleAction { preview, edit, delete }

class HomePage extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const HomePage({super.key, this.onSettingsChanged});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();

  List<Article> _articles = [];
  bool _loading = true;
  bool _syncing = false;
  _ArticleFilter _filter = _ArticleFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text);
    });
    _loadArticles();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Future<void> _syncFromGitHub({bool incremental = false}) async {
    if (_syncing) return;

    LogService.instance.logAction(
      '同步文章',
      detail: incremental ? '增量同步' : '全量同步',
    );

    final s = AppStrings.current;
    final settings = settingsService.settings;
    if (settings.githubToken.isEmpty ||
        settings.githubOwner.isEmpty ||
        settings.githubRepo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.githubNotConfigured)));
      return;
    }

    setState(() => _syncing = true);

    final github = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
      branch: settings.githubBranch,
    );
    final sync = SyncService(
      github: github,
      articleService: articleService,
      settingsService: settingsService,
    );
    final result = incremental
        ? await sync.syncIncremental()
        : await sync.syncFromGitHub();

    if (!mounted) return;
    setState(() => _syncing = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.syncSuccess}: ${result.count}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.syncFailed}: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    await _loadArticles();
  }

  Future<void> _deleteArticle(Article article) async {
    final s = AppStrings.current;
    final hasRemote =
        article.remotePath != null &&
        article.githubSha != null &&
        article.githubSha!.isNotEmpty &&
        article.status != ArticleStatus.draft &&
        article.status != ArticleStatus.remoteDeleted;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteArticle),
        content: Text(hasRemote ? s.deleteConfirmRemote : s.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              s.deleteArticle,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || article.id == null) return;

    LogService.instance.logAction('删除文章', detail: article.title);

    // 如果有远程文件（synced 或 repoDraft），先删除远程
    final remotePath = article.remotePath;
    if (hasRemote &&
        remotePath != null &&
        article.githubSha != null &&
        article.githubSha!.isNotEmpty &&
        article.status != ArticleStatus.draft &&
        article.status != ArticleStatus.remoteDeleted) {
      final settings = settingsService.settings;
      if (settings.githubToken.isNotEmpty &&
          settings.githubOwner.isNotEmpty &&
          settings.githubRepo.isNotEmpty) {
        final github = GitHubService(
          token: settings.githubToken,
          owner: settings.githubOwner,
          repo: settings.githubRepo,
          branch: settings.githubBranch,
        );
        final result = await github.deleteFile(
          remotePath: remotePath,
          sha: article.githubSha!,
        );
        if (!result.success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${s.syncFailed}: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    await articleService.delete(article.id!);
    await _loadArticles();
  }

  void _openEditor({int? articleId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(articleId: articleId)),
    );
    _loadArticles();
  }

  Future<void> _openArticlePreview(Article article) async {
    final s = AppStrings.current;
    final url = await ArticleUrlService.resolveArticleUrl(
      article,
      settingsService.settings,
    );
    if (!mounted) return;

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _label(
              '无法推测文章链接，请确认 GitHub 仓库设置和文章发布状态',
              'Cannot infer the article URL. Check GitHub settings and publish status.',
            ),
          ),
        ),
      );
      return;
    }

    LogService.instance.logAction('预览文章网页', detail: url.toString());
    if (ArticleWebViewPage.supportsEmbeddedWebView) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleWebViewPage(
            url: url,
            title: article.title.isEmpty ? s.appTitle : article.title,
          ),
        ),
      );
      return;
    }

    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_label('无法打开链接：$url', 'Failed to open URL: $url')),
      ),
    );
  }

  List<Article> get _visibleArticles {
    final query = _query.trim().toLowerCase();
    return _articles.where((article) {
      final matchesFilter = switch (_filter) {
        _ArticleFilter.all => true,
        _ArticleFilter.draft => article.status == ArticleStatus.draft,
        _ArticleFilter.synced => article.status == ArticleStatus.synced,
        _ArticleFilter.repoDraft => article.status == ArticleStatus.repoDraft,
      };

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final searchable = [
        article.title,
        article.content,
        article.tags.join(' '),
        article.categories.join(' '),
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.sync),
              tooltip: s.syncFromGitHub,
              onSelected: (value) {
                switch (value) {
                  case 'incremental':
                    _syncFromGitHub(incremental: true);
                    break;
                  case 'full':
                    _syncFromGitHub(incremental: false);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'incremental',
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: Text(s.incrementalSync),
                    subtitle: Text(s.incrementalSyncDesc),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'full',
                  child: ListTile(
                    leading: const Icon(Icons.sync),
                    title: Text(s.fullSync),
                    subtitle: Text(s.fullSyncDesc),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: s.friendLinks,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendLinkPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: s.settingsTitle,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SettingsPage(onSettingsChanged: widget.onSettingsChanged),
                ),
              );
              _loadArticles();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(s.newArticle),
      ),
    );
  }

  Widget _buildBody() {
    final visibleArticles = _visibleArticles;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxWidth),
          child: CustomScrollView(
            slivers: [
              // 顶部标题与搜索：随页面一起上滑
              SliverToBoxAdapter(child: _buildHeader()),
              // 类型切换：吸顶
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  height: 56,
                  child: _buildFilterBar(),
                ),
              ),
              if (visibleArticles.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(filtered: _articles.isNotEmpty),
                )
              else
                _buildArticleSliver(visibleArticles),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final s = AppStrings.current;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label('写作空间', 'Writing desk'),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _CountBadge(count: _articles.length),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: _label('搜索标题、正文或标签', 'Search title, content, or tags'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: _label('清空搜索', 'Clear search'),
                      onPressed: _searchCtrl.clear,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _ArticleFilter.values.map((filter) {
          final selected = _filter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${_filterLabel(filter)} ${_countFor(filter)}'),
              selected: selected,
              onSelected: (_) => setState(() => _filter = filter),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState({required bool filtered}) {
    final s = AppStrings.current;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              filtered ? Icons.search_off : Icons.article_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? _label('没有匹配的文章', 'No matching articles')
                  : s.noArticles,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              filtered
                  ? _label('调整搜索条件或切换状态筛选。', 'Adjust the search or filter.')
                  : _label(
                      '新建一篇文章，或者从 GitHub 仓库同步现有内容。',
                      'Create a post or sync existing content from GitHub.',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: filtered
                  ? [
                      OutlinedButton.icon(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filter = _ArticleFilter.all);
                        },
                        icon: const Icon(Icons.filter_alt_off),
                        label: Text(_label('清除筛选', 'Clear filters')),
                      ),
                    ]
                  : [
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add),
                        label: Text(s.newArticle),
                      ),
                      OutlinedButton.icon(
                        onPressed: _syncing ? null : _syncFromGitHub,
                        icon: const Icon(Icons.sync),
                        label: Text(s.syncFromGitHub),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleSliver(List<Article> articles) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      sliver: SliverList.separated(
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final article = articles[index];
          return _ArticleListItem(
            article: article,
            excerpt: _excerptFor(article),
            onTap: () => _openEditor(articleId: article.id),
            onPreview:
                ArticleUrlService.canInferUrl(article, settingsService.settings)
                ? () => _openArticlePreview(article)
                : null,
            onDelete: () => _deleteArticle(article),
          );
        },
      ),
    );
  }

  int _countFor(_ArticleFilter filter) {
    return switch (filter) {
      _ArticleFilter.all => _articles.length,
      _ArticleFilter.draft =>
        _articles.where((a) => a.status == ArticleStatus.draft).length,
      _ArticleFilter.synced =>
        _articles.where((a) => a.status == ArticleStatus.synced).length,
      _ArticleFilter.repoDraft =>
        _articles.where((a) => a.status == ArticleStatus.repoDraft).length,
    };
  }

  String _filterLabel(_ArticleFilter filter) {
    final s = AppStrings.current;
    return switch (filter) {
      _ArticleFilter.all => _label('全部', 'All'),
      _ArticleFilter.draft => s.draftStatus,
      _ArticleFilter.synced => s.synced,
      _ArticleFilter.repoDraft => s.repoDraft,
    };
  }

  String _excerptFor(Article article) {
    final text = article.bodyContent.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return _label('还没有正文内容', 'No content yet');
    if (text.length <= 140) return text;
    return '${text.substring(0, 140)}...';
  }

  String _label(String zh, String en) {
    return AppStrings.isZh ? zh : en;
  }
}

/// 吸顶的类型切换栏：固定高度，滚动时背景不透明并加底部分隔线。
class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _FilterBarDelegate({required this.child, required this.height});

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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: overlapsContent
            ? Border(bottom: BorderSide(color: colorScheme.outlineVariant))
            : null,
      ),
      child: Center(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ArticleListItem extends StatelessWidget {
  final Article article;
  final String excerpt;
  final VoidCallback onTap;
  final VoidCallback? onPreview;
  final VoidCallback onDelete;

  const _ArticleListItem({
    required this.article,
    required this.excerpt,
    required this.onTap,
    required this.onPreview,
    required this.onDelete,
  });

  bool get _hasCover => article.cover != null && article.cover!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // 窄屏(<600)图片缩小，宽屏保持原尺寸
    final narrow = screenWidth < 600;
    final imgWidth = screenWidth < 400
        ? 80.0
        : (narrow ? 110.0 : 180.0);
    final imgHeight = screenWidth < 400
        ? 56.0
        : (narrow ? 70.0 : 100.0);
    // 窄屏时把预览按钮挪出标题行，放到封面图下方（无图则单独成列），
    // 避免它挤占标题的横向空间。
    final previewInLeading = narrow && onPreview != null;
    final hasLeading = _hasCover || previewInLeading;
    final contentLeftPadding = hasLeading ? 8.0 : 84.0;
    final dateStr =
        '${article.date.year}-${article.date.month.toString().padLeft(2, '0')}-${article.date.day.toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: screenWidth < 600
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.stretch,
                children: [
                  if (hasLeading)
                    _buildLeading(
                      screenWidth: screenWidth,
                      imgWidth: imgWidth,
                      imgHeight: imgHeight,
                      previewInLeading: previewInLeading,
                      colorScheme: colorScheme,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        contentLeftPadding,
                        14,
                        8,
                        14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  article.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (onPreview != null && !previewInLeading)
                                IconButton(
                                  onPressed: onPreview,
                                  icon: const Icon(
                                    Icons.travel_explore_outlined,
                                  ),
                                  tooltip: AppStrings.isZh
                                      ? '查看已部署网页'
                                      : 'View deployed page',
                                ),
                              PopupMenuButton<_ArticleAction>(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).showMenuTooltip,
                                onSelected: (action) {
                                  switch (action) {
                                    case _ArticleAction.preview:
                                      onPreview?.call();
                                    case _ArticleAction.edit:
                                      onTap();
                                    case _ArticleAction.delete:
                                      onDelete();
                                  }
                                },
                                itemBuilder: (context) {
                                  final s = AppStrings.current;
                                  return [
                                    if (onPreview != null)
                                      PopupMenuItem(
                                        value: _ArticleAction.preview,
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.travel_explore_outlined,
                                          ),
                                          title: Text(
                                            AppStrings.isZh
                                                ? '查看已部署网页'
                                                : 'View deployed page',
                                          ),
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                    PopupMenuItem(
                                      value: _ArticleAction.edit,
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.edit_outlined,
                                        ),
                                        title: Text(s.editorTitle),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: _ArticleAction.delete,
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.delete_outline,
                                        ),
                                        title: Text(s.deleteArticle),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              excerpt,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _MetaPill(
                                icon: Icons.calendar_today,
                                text: dateStr,
                              ),
                              if (article.tags.isNotEmpty)
                                ...article.tags
                                    .take(3)
                                    .map(
                                      (tag) => _MetaPill(
                                        icon: Icons.tag,
                                        text: tag,
                                        dense: true,
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(child: _StatusCornerBadge(article: article)),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(
    double imgWidth,
    double imgHeight,
    ColorScheme colorScheme,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        article.cover!,
        width: imgWidth,
        height: imgHeight,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: imgWidth,
          height: imgHeight,
          color: colorScheme.surfaceContainerLow,
          child: Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  /// 左侧引导列：宽屏只放封面图；窄屏把预览按钮放到封面图下方，
  /// 没有封面图时单独显示按钮，从而不再挤占标题空间。
  Widget _buildLeading({
    required double screenWidth,
    required double imgWidth,
    required double imgHeight,
    required bool previewInLeading,
    required ColorScheme colorScheme,
  }) {
    final padAll = screenWidth < 400 ? 8.0 : 12.0;
    if (!previewInLeading) {
      return Padding(
        padding: EdgeInsets.all(padAll),
        child: _buildCoverImage(imgWidth, imgHeight, colorScheme),
      );
    }
    return Padding(
      padding: EdgeInsets.all(padAll),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasCover) ...[
            _buildCoverImage(imgWidth, imgHeight, colorScheme),
            const SizedBox(height: 2),
          ],
          IconButton(
            onPressed: onPreview,
            icon: const Icon(Icons.travel_explore_outlined),
            tooltip: AppStrings.isZh ? '查看已部署网页' : 'View deployed page',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _StatusCornerBadge extends StatelessWidget {
  final Article article;

  const _StatusCornerBadge({required this.article});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;
    final (label, color, icon) = switch (article.status) {
      ArticleStatus.synced => (
        s.synced,
        const Color(0xFF2F7D57),
        Icons.cloud_done,
      ),
      ArticleStatus.repoDraft => (
        AppStrings.isZh ? s.repoDraft : 'Repo',
        const Color(0xFF9A6A1F),
        Icons.drafts_outlined,
      ),
      ArticleStatus.pendingPublish => (
        AppStrings.isZh ? s.pendingPublish : 'Pending',
        const Color(0xFF7A5CDB),
        Icons.cloud_upload_outlined,
      ),
      ArticleStatus.remoteDeleted => (
        AppStrings.isZh ? s.remoteDeleted : 'Deleted',
        const Color(0xFFB64B45),
        Icons.cloud_off_outlined,
      ),
      ArticleStatus.draft => (
        s.draftStatus,
        const Color(0xFF6F7672),
        Icons.edit_note,
      ),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 84),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dense;

  const _MetaPill({required this.icon, required this.text, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
