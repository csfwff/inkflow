import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_tree/super_tree.dart';

import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../services/github_service.dart';
import '../services/log_service.dart';
import '../services/sync_service.dart';
import '../widgets/responsive.dart';
import 'editor_page.dart';

enum _TreeNodeType { dir, file }

class _TreeNode {
  final String name;
  final String path;
  final _TreeNodeType type;
  final ArticleRemoteKind remoteKind;
  final String? sha;

  _TreeNode({
    required this.name,
    required this.path,
    required this.type,
    required this.remoteKind,
    this.sha,
  });

  bool get isDir => type == _TreeNodeType.dir;
}

class FileTreePage extends StatefulWidget {
  const FileTreePage({super.key});

  @override
  State<FileTreePage> createState() => _FileTreePageState();
}

class _FileTreePageState extends State<FileTreePage> {
  late TreeController<_TreeNode> _treeController;
  late TreeNode<_TreeNode> _selectedDirectoryNode;
  final ScrollController _treeScrollController = ScrollController();
  final GlobalKey _treeViewportKey = GlobalKey();
  final Map<String, GlobalKey> _treeNodeContentKeys = {};
  List<TreeNode<_TreeNode>> _stickyDirectoryNodes = const [];
  bool _stickyUpdateScheduled = false;
  String? _openingPath;

  @override
  void initState() {
    super.initState();
    _initTreeController();
    _treeScrollController.addListener(_handleTreeScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_selectDirectoryNode(_selectedDirectoryNode, expand: true));
      }
    });
  }

  @override
  void dispose() {
    _treeScrollController.removeListener(_handleTreeScroll);
    _treeScrollController.dispose();
    _treeController.removeListener(_handleTreeControllerChanged);
    _treeController.dispose();
    super.dispose();
  }

  bool get _isGitHubConfigured {
    final settings = settingsService.settings;
    return settings.githubToken.isNotEmpty &&
        settings.githubOwner.isNotEmpty &&
        settings.githubRepo.isNotEmpty;
  }

  GitHubService? _githubService() {
    final settings = settingsService.settings;
    if (!_isGitHubConfigured) return null;
    return GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
      branch: settings.githubBranch,
    );
  }

  void _initTreeController() {
    final roots = _createRootNodes();
    _treeController = _createTreeController(roots);
    _treeController.addListener(_handleTreeControllerChanged);
    _selectedDirectoryNode = roots.first;
    _treeController.setSelectedNodeId(_selectedDirectoryNode.id);
  }

  TreeController<_TreeNode> _createTreeController(
    List<TreeNode<_TreeNode>> roots,
  ) {
    return TreeController<_TreeNode>(
      roots: roots,
      loadChildren: _loadTreeChildren,
      sortComparator: _compareTreeNodes,
    );
  }

  List<TreeNode<_TreeNode>> _createRootNodes() {
    return [
      _createTreeNode(
        _TreeNode(
          name: '_posts',
          path: 'source/_posts',
          type: _TreeNodeType.dir,
          remoteKind: ArticleRemoteKind.post,
        ),
      ),
      _createTreeNode(
        _TreeNode(
          name: '_drafts',
          path: 'source/_drafts',
          type: _TreeNodeType.dir,
          remoteKind: ArticleRemoteKind.repoDraft,
        ),
      ),
    ];
  }

  TreeNode<_TreeNode> _createTreeNode(_TreeNode data) {
    return TreeNode<_TreeNode>(
      id: data.path,
      data: data,
      canLoadChildren: data.isDir,
    );
  }

  Future<List<TreeNode<_TreeNode>>> _loadTreeChildren(
    TreeNode<_TreeNode> node,
  ) async {
    final data = node.data;
    if (!data.isDir) return const [];
    final github = _githubService();
    if (github == null) {
      throw StateError(AppStrings.current.githubNotConfigured);
    }

    final result = await github.listDirectoryContents(data.path);
    if (!result.success) {
      throw StateError(result.error ?? _label('目录加载失败', 'Failed to load'));
    }

    final entries =
        result.entries.where((entry) {
          return entry.type == 'dir' ||
              entry.name.toLowerCase().endsWith('.md');
        }).toList()..sort((a, b) {
          if (a.type != b.type) return a.type == 'dir' ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

    return entries
        .map(
          (entry) => _createTreeNode(
            _TreeNode(
              name: entry.name,
              path: entry.path,
              type: entry.type == 'dir'
                  ? _TreeNodeType.dir
                  : _TreeNodeType.file,
              remoteKind: data.remoteKind,
              sha: entry.sha,
            ),
          ),
        )
        .toList();
  }

  int _compareTreeNodes(TreeNode<_TreeNode> a, TreeNode<_TreeNode> b) {
    if (a.data.type != b.data.type) return a.data.isDir ? -1 : 1;
    return a.data.name.toLowerCase().compareTo(b.data.name.toLowerCase());
  }

  Future<void> _selectDirectoryNode(
    TreeNode<_TreeNode> node, {
    bool expand = false,
  }) async {
    if (!node.data.isDir) return;
    setState(() => _selectedDirectoryNode = node);
    _treeController.setSelectedNodeId(node.id);
    await _treeController.ensureNodeChildrenLoaded(node);
    if (expand && node.hasChildren && !node.isExpanded) {
      _treeController.expandNode(node);
    }
    if (mounted) setState(() {});
  }

  void _handleTreeNodeTap(String id) {
    final node = _treeController.findNodeById(id);
    if (node == null) return;
    if (node.data.isDir) {
      unawaited(_selectDirectoryNode(node));
    } else {
      _treeController.setSelectedNodeId(_selectedDirectoryNode.id);
      unawaited(_openRemoteFile(node.data));
    }
  }

  Future<void> _toggleDirectoryExpansion(TreeNode<_TreeNode> node) async {
    if (!node.data.isDir) return;
    await _treeController.toggleNodeExpansion(node);
    if (mounted) {
      setState(() {});
      _scheduleStickyUpdate();
    }
  }

  Future<void> _openRemoteFile(_TreeNode node) async {
    if (node.isDir || _openingPath != null) return;

    final github = _githubService();
    if (github == null) {
      _showSnack(AppStrings.current.githubNotConfigured);
      return;
    }

    final existing = await articleService.getByRemotePath(node.path);
    if (!mounted) return;
    if (existing != null &&
        existing.id != null &&
        existing.status != ArticleStatus.remoteDeleted) {
      await _openEditor(existing.id!);
      return;
    }

    setState(() => _openingPath = node.path);
    LogService.instance.logAction('打开 GitHub 文件', detail: node.path);

    final sync = SyncService(
      github: github,
      articleService: articleService,
      settingsService: settingsService,
    );
    final remoteArticle = await sync.fetchRemoteArticle(
      Article(
        title: _titleFromFileName(node.name),
        content: '',
        date: DateTime.now(),
        slug: _slugFromFileName(node.name),
        status: _statusForKind(node.remoteKind),
        filePath: _relativePath(node.path, node.remoteKind),
        remotePath: node.path,
        remoteKind: node.remoteKind,
        githubSha: node.sha,
      ),
    );

    if (!mounted) return;
    setState(() => _openingPath = null);

    if (remoteArticle == null) {
      _showSnack(
        '${_label('无法读取远程文件', 'Could not read remote file')}: ${node.path}',
        isError: true,
      );
      return;
    }

    await articleService.replaceWithRemote(remoteArticle);
    await articleService.ensureTags(remoteArticle.tags);
    await articleService.ensureCategories(remoteArticle.categories);
    final saved = await articleService.getByRemotePath(node.path);

    if (!mounted) return;
    if (saved?.id == null) {
      _showSnack(
        _label(
          '远程文件已读取，但本地记录打开失败',
          'File loaded, but local record could not be opened',
        ),
        isError: true,
      );
      return;
    }
    await _openEditor(saved!.id!);
  }

  Future<void> _openEditor(int articleId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(articleId: articleId)),
    );
  }

  void _refreshTree() {
    _treeController.removeListener(_handleTreeControllerChanged);
    _treeController.dispose();
    final roots = _createRootNodes();
    setState(() {
      _treeController = _createTreeController(roots);
      _selectedDirectoryNode = roots.first;
      _stickyDirectoryNodes = const [];
      _openingPath = null;
    });
    _treeNodeContentKeys.clear();
    _treeController.addListener(_handleTreeControllerChanged);
    _treeController.setSelectedNodeId(_selectedDirectoryNode.id);
    if (_treeScrollController.hasClients) {
      _treeScrollController.jumpTo(0);
    }
    unawaited(_selectDirectoryNode(_selectedDirectoryNode, expand: true));
  }

  void _handleTreeScroll() {
    _scheduleStickyUpdate();
  }

  void _handleTreeControllerChanged() {
    _scheduleStickyUpdate();
  }

  void _scheduleStickyUpdate() {
    if (!mounted || _stickyUpdateScheduled) return;
    _stickyUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stickyUpdateScheduled = false;
      if (mounted) _updateStickyDirectories();
    });
  }

  void _updateStickyDirectories() {
    if (!_treeScrollController.hasClients ||
        _treeScrollController.position.pixels <= 1) {
      _setStickyDirectoryNodes(const []);
      return;
    }

    final viewportContext = _treeViewportKey.currentContext;
    if (viewportContext == null) {
      _setStickyDirectoryNodes(const []);
      return;
    }

    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      _setStickyDirectoryNodes(const []);
      return;
    }

    final viewportTop = viewportRenderObject.localToGlobal(Offset.zero).dy;
    final nodes = _treeController.flatVisibleNodes;
    TreeNode<_TreeNode>? anchorNode;
    TreeNode<_TreeNode>? firstNodeBelowTop;
    var closestPastTop = double.negativeInfinity;
    var closestBelowTop = double.infinity;

    for (final node in nodes) {
      final rowContext = _treeNodeContentKeys[node.id]?.currentContext;
      final rowRenderObject = rowContext?.findRenderObject();
      if (rowRenderObject is! RenderBox || !rowRenderObject.hasSize) {
        continue;
      }

      final rowTop = rowRenderObject.localToGlobal(Offset.zero).dy;
      if (rowTop <= viewportTop + 1 && rowTop > closestPastTop) {
        closestPastTop = rowTop;
        anchorNode = node;
      } else if (rowTop > viewportTop + 1 && rowTop < closestBelowTop) {
        closestBelowTop = rowTop;
        firstNodeBelowTop = node;
      }
    }

    if (anchorNode == null && firstNodeBelowTop != null) {
      final firstVisibleIndex = nodes.indexWhere(
        (node) => node.id == firstNodeBelowTop!.id,
      );
      if (firstVisibleIndex > 0) {
        anchorNode = nodes[firstVisibleIndex - 1];
      }
    }

    if (anchorNode == null) {
      _setStickyDirectoryNodes(const []);
      return;
    }

    _setStickyDirectoryNodes(_directoryTrailFor(anchorNode));
  }

  List<TreeNode<_TreeNode>> _directoryTrailFor(TreeNode<_TreeNode> node) {
    final trail = <TreeNode<_TreeNode>>[];
    TreeNode<_TreeNode>? cursor = node.data.isDir ? node : node.parent;
    while (cursor != null) {
      if (cursor.data.isDir) trail.add(cursor);
      cursor = cursor.parent;
    }
    return trail.reversed.toList(growable: false);
  }

  void _setStickyDirectoryNodes(List<TreeNode<_TreeNode>> nodes) {
    if (_sameStickyDirectoryNodes(_stickyDirectoryNodes, nodes)) return;
    setState(() => _stickyDirectoryNodes = List.unmodifiable(nodes));
  }

  bool _sameStickyDirectoryNodes(
    List<TreeNode<_TreeNode>> a,
    List<TreeNode<_TreeNode>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_label('GitHub 文件', 'GitHub files')),
        actions: [
          IconButton(
            onPressed: _refreshTree,
            icon: const Icon(Icons.refresh),
            tooltip: _label('刷新', 'Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.maxWidth),
            child: _isGitHubConfigured
                ? _buildConfiguredBody()
                : _buildNotConfigured(),
          ),
        ),
      ),
    );
  }

  Widget _buildConfiguredBody() {
    if (!Responsive.isWide(context)) {
      return _buildNarrowDirectoryPane();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildDirectoryPane(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildDirectoryContentPane(_selectedDirectoryNode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowDirectoryPane() {
    return SizedBox.expand(
      child: Column(
        children: [
          _buildTreeHeader(),
          Expanded(child: _buildSuperTreeView(compact: false)),
        ],
      ),
    );
  }

  Widget _buildDirectoryPane() {
    return SizedBox.expand(
      child: Column(
        children: [
          _buildTreeHeader(compact: true),
          Expanded(child: _buildSuperTreeView(compact: true)),
        ],
      ),
    );
  }

  Widget _buildSuperTreeView({required bool compact}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        KeyedSubtree(
          key: _treeViewportKey,
          child: SuperTreeView<_TreeNode>(
            controller: _treeController,
            scrollController: _treeScrollController,
            style: TreeViewStyle(
              indentAmount: _treeIndentAmount(compact),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 4 : 6,
              ),
              hoverColor: colorScheme.surfaceContainer,
              selectedColor: colorScheme.primaryContainer.withValues(
                alpha: 0.42,
              ),
              expandAnimationDuration: const Duration(milliseconds: 140),
            ),
            logic: TreeViewConfig<_TreeNode>(
              expansionTrigger: ExpansionTrigger.iconTap,
              enableDragAndDrop: false,
              selectionMode: SelectionMode.single,
              namingStrategy: TreeNamingStrategy.none,
              onNodeTap: _handleTreeNodeTap,
            ),
            expansionSlotSize: _treeExpansionSlotSize,
            loadingExpansionBuilder: (_, __) => const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            prefixBuilder: _buildTreePrefix,
            contentBuilder: _buildTreeContent,
            trailingBuilder: _buildTreeTrailing,
          ),
        ),
        _buildStickyDirectoryOverlay(compact: compact),
      ],
    );
  }

  static const double _treeExpansionSlotSize = 22;

  double _treeIndentAmount(bool compact) => compact ? 18 : 22;

  Widget _buildTreePrefix(BuildContext context, TreeNode<_TreeNode> node) {
    final data = node.data;
    final selected = _treeController.selectedNodeIds.contains(node.id);
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Icon(
      data.isDir
          ? (node.isExpanded ? Icons.folder_open : Icons.folder_outlined)
          : (data.remoteKind == ArticleRemoteKind.repoDraft
                ? Icons.drafts_outlined
                : Icons.article_outlined),
      size: 20,
      color: color,
    );
  }

  Widget _buildTreeContent(
    BuildContext context,
    TreeNode<_TreeNode> node,
    Widget? renameField,
  ) {
    final data = node.data;
    final selected = _treeController.selectedNodeIds.contains(node.id);
    final colorScheme = Theme.of(context).colorScheme;

    return KeyedSubtree(
      key: _treeNodeContentKeyFor(node.id),
      child: Text(
        data.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: data.isDir || selected
              ? FontWeight.w600
              : FontWeight.w400,
          color: selected ? colorScheme.primary : null,
        ),
      ),
    );
  }

  GlobalKey _treeNodeContentKeyFor(String id) {
    return _treeNodeContentKeys.putIfAbsent(id, GlobalKey.new);
  }

  Widget _buildTreeTrailing(BuildContext context, TreeNode<_TreeNode> node) {
    if (node.nodeState != TreeNodeState.error) {
      return const SizedBox.shrink();
    }
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.refresh, size: 18),
      tooltip: _label('重试', 'Retry'),
      onPressed: () => unawaited(_retryLoadNode(node)),
    );
  }

  Widget _buildTreeHeader({bool compact = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _selectedDirectoryNode.data;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        compact ? 10 : 12,
        12,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  selected.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyDirectoryOverlay({required bool compact}) {
    if (_stickyDirectoryNodes.isEmpty) return const SizedBox.shrink();

    final maxRows = compact ? 3 : 2;
    final visibleNodes = _stickyDirectoryNodes.length <= maxRows
        ? _stickyDirectoryNodes
        : _stickyDirectoryNodes.sublist(_stickyDirectoryNodes.length - maxRows);
    final baseDepth = visibleNodes.first.depth;
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.97),
        elevation: 2,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final node in visibleNodes)
              _buildStickyDirectoryRow(
                node,
                compact: compact,
                baseDepth: baseDepth,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyDirectoryRow(
    TreeNode<_TreeNode> node, {
    required bool compact,
    required int baseDepth,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _treeController.selectedNodeIds.contains(node.id);
    final relativeDepth = node.depth - baseDepth;
    final leftPadding =
        (compact ? 10.0 : 12.0) + relativeDepth * _treeIndentAmount(compact);
    final rowHeight = compact ? 30.0 : 38.0;
    final canToggle =
        node.hasChildren || _treeController.canNodeLoadChildren(node);
    final iconColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return SizedBox(
      height: rowHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: leftPadding, right: 10),
          child: Row(
            children: [
              SizedBox(
                width: _treeExpansionSlotSize,
                height: rowHeight,
                child: canToggle
                    ? InkResponse(
                        radius: 16,
                        onTap: () => unawaited(_toggleDirectoryExpansion(node)),
                        child: Icon(
                          node.isExpanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => unawaited(_selectDirectoryNode(node)),
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, size: 20, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.data.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected ? colorScheme.primary : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _retryLoadNode(TreeNode<_TreeNode> node) async {
    _treeController.clearNodeLoadError(node.id);
    await _treeController.ensureNodeChildrenLoaded(node);
    if (mounted) setState(() {});
  }

  Widget _buildDirectoryContentPane(TreeNode<_TreeNode> node) {
    final colorScheme = Theme.of(context).colorScheme;
    final data = node.data;
    final children = node.children;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.folder_open_outlined, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshTree,
                icon: const Icon(Icons.refresh),
                tooltip: _label('刷新文件树', 'Refresh tree'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (node.nodeState == TreeNodeState.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (node.nodeState == TreeNodeState.error) {
                return _buildDirectoryError(node);
              }
              if (node.nodeState == TreeNodeState.idle &&
                  node.canLoadChildren) {
                return const Center(child: CircularProgressIndicator());
              }
              if (children.isEmpty) {
                return _buildDirectoryEmpty();
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: children.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant,
                ),
                itemBuilder: (context, index) {
                  return _buildDirectoryContentTile(children[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDirectoryContentTile(TreeNode<_TreeNode> node) {
    final data = node.data;
    if (data.isDir) {
      return ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(data.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(data.path, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => unawaited(_selectDirectoryNode(node, expand: true)),
      );
    }
    return _buildFileTile(data, depth: 0);
  }

  Widget _buildDirectoryError(TreeNode<_TreeNode> node) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              node.loadError?.toString() ?? _label('目录加载失败', 'Failed to load'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                unawaited(_retryLoadNode(node));
              },
              icon: const Icon(Icons.refresh),
              label: Text(_label('重试', 'Retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectoryEmpty() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              _label('没有子目录或 Markdown 文件', 'No folders or Markdown files'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotConfigured() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 56,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.current.githubNotConfigured,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileTile(_TreeNode node, {required int depth}) {
    final opening = _openingPath == node.path;
    return ListTile(
      contentPadding: EdgeInsets.fromLTRB(16 + depth * 20, 0, 12, 0),
      leading: Icon(
        node.remoteKind == ArticleRemoteKind.repoDraft
            ? Icons.drafts_outlined
            : Icons.article_outlined,
      ),
      title: Text(node.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        _relativePath(node.path, node.remoteKind),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: opening
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      enabled: _openingPath == null || opening,
      onTap: () => _openRemoteFile(node),
    );
  }

  ArticleStatus _statusForKind(ArticleRemoteKind kind) {
    return switch (kind) {
      ArticleRemoteKind.post => ArticleStatus.synced,
      ArticleRemoteKind.repoDraft => ArticleStatus.repoDraft,
    };
  }

  String _relativePath(String path, ArticleRemoteKind kind) {
    final prefix = switch (kind) {
      ArticleRemoteKind.post => 'source/_posts/',
      ArticleRemoteKind.repoDraft => 'source/_drafts/',
    };
    return path.startsWith(prefix) ? path.substring(prefix.length) : path;
  }

  String _slugFromFileName(String name) {
    return name.toLowerCase().endsWith('.md')
        ? name.substring(0, name.length - 3)
        : name;
  }

  String _titleFromFileName(String name) {
    return _slugFromFileName(name).replaceAll('-', ' ');
  }

  String _label(String zh, String en) {
    return AppStrings.isZh ? zh : en;
  }
}
