import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/friend_link.dart';
import '../services/friend_link_parser.dart';
import '../services/friend_link_service.dart';
import '../services/github_service.dart';
import '../services/log_service.dart';
import 'friend_link_edit_page.dart';

/// 友链筛选
enum _FriendLinkFilter { all, enabled, disabled }

enum _FriendLinkToolbarAction { check, pull, push, addDev }

enum _FriendLinkItemAction { edit, check, delete }

class FriendLinkPage extends StatefulWidget {
  const FriendLinkPage({super.key});

  @override
  State<FriendLinkPage> createState() => _FriendLinkPageState();
}

class _FriendLinkPageState extends State<FriendLinkPage> {
  static const double _compactBreakpoint = 640;

  final FriendLinkService _service = FriendLinkService();
  List<FriendLink> _links = [];
  bool _loading = true;
  bool _syncing = false;
  bool _checking = false;
  bool _hasUnpushedChanges = false;
  final Map<String, LinkCheckResult> _checkResults = {};
  final Set<String> _checkingLinks = {};
  _FriendLinkFilter _filter = _FriendLinkFilter.all;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await _service.init(articleService.database);
    await _loadLinks();
  }

  Future<void> _loadLinks() async {
    setState(() => _loading = true);
    final links = await _service.getAll();
    if (mounted) {
      setState(() {
        _links = links;
        _loading = false;
      });
    }
  }

  List<FriendLink> get _filteredLinks {
    switch (_filter) {
      case _FriendLinkFilter.all:
        return _links;
      case _FriendLinkFilter.enabled:
        return _links.where((l) => !l.isCommented).toList();
      case _FriendLinkFilter.disabled:
        return _links.where((l) => l.isCommented).toList();
    }
  }

  Future<void> _syncFromGitHub() async {
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

    setState(() => _syncing = true);

    final github = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
      branch: settings.githubBranch,
    );

    final result = await _service.syncFromGitHub(github, settings.friendLinkPath);

    if (!mounted) return;
    setState(() => _syncing = false);

    if (result.success) {
      setState(() => _hasUnpushedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.syncFriendLinks}: ${result.count}')),
      );
      await _loadLinks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.syncFriendLinks}: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pushToGitHub() async {
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

    setState(() => _syncing = true);

    final github = GitHubService(
      token: settings.githubToken,
      owner: settings.githubOwner,
      repo: settings.githubRepo,
      branch: settings.githubBranch,
    );

    final result = await _service.pushToGitHub(github, settings.friendLinkPath);

    if (!mounted) return;
    setState(() => _syncing = false);

    if (result.success) {
      setState(() => _hasUnpushedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.syncFriendLinks}: ${result.count}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.syncFriendLinks}: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddMenu() {
    final s = AppStrings.current;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(s.addFriendLink),
              onTap: () {
                Navigator.pop(ctx);
                _addLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.content_paste),
              title: Text(s.pasteYaml),
              onTap: () {
                Navigator.pop(ctx);
                _pasteFromYaml();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _checkLinks() async {
    final enabledLinks = _links.where((l) => !l.isCommented).toList();
    final enabledKeys = enabledLinks.map(_linkKey).toSet();
    setState(() {
      _checking = true;
      _checkingLinks.addAll(enabledKeys);
    });

    LogService.instance.logAction('检测友链', detail: '${enabledLinks.length} 条');

    var accessible = 0;
    await Future.wait(enabledLinks.map((link) async {
      final key = _linkKey(link);
      final result = await _service.checkLink(link);

      if (!mounted) return;
      if (result.isAccessible) {
        accessible++;
      }

      setState(() {
        _checkingLinks.remove(key);
        _checkResults[_resultKey(result)] = result;
      });
    }));

    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkingLinks.removeAll(enabledKeys);
    });
    LogService.instance.info(
      '友链检测完成: $accessible/${enabledLinks.length} 可访问',
      tag: 'FriendLink',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('友链检测完成：$accessible/${enabledLinks.length} 可访问')),
    );
  }

  Future<void> _checkSingleLink(FriendLink link) async {
    final key = _linkKey(link);
    setState(() => _checkingLinks.add(key));

    final result = await _service.checkLink(link);

    if (!mounted) return;
    setState(() {
      _checkingLinks.remove(key);
      _checkResults[_resultKey(result)] = result;
    });
  }

  String _linkKey(FriendLink link) => '${link.id ?? link.name}|${link.link}';

  String _resultKey(LinkCheckResult result) =>
      '${result.linkId ?? result.name}|${result.url}';

  void _markUnpushedChanges() {
    if (!mounted) return;
    if (_hasUnpushedChanges) return;
    setState(() => _hasUnpushedChanges = true);
  }

  Future<bool> _confirmLeaveWithUnpushedChanges() async {
    if (!_hasUnpushedChanges) return true;
    final zh = AppStrings.isZh;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(zh ? '友链修改未推送' : 'Friend Links Not Pushed'),
        content: Text(
          zh
              ? '你有本地友链修改还没有推送到 GitHub。现在返回后修改仍会保存在本地，但远程不会同步。确定返回吗？'
              : 'You have local friend link changes that have not been pushed to GitHub. They will stay local, but the remote file will not be updated. Leave anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.current.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(zh ? '仍然返回' : 'Leave'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addLink() async {
    final result = await Navigator.push<FriendLink>(
      context,
      MaterialPageRoute(builder: (_) => const FriendLinkEditPage()),
    );

    if (result != null) {
      await _service.insert(result);
      LogService.instance.logAction('添加友链', detail: result.name);
      await _loadLinks();
      _markUnpushedChanges();
    }
  }

  Future<void> _editLink(FriendLink link) async {
    final result = await Navigator.push<FriendLink>(
      context,
      MaterialPageRoute(builder: (_) => FriendLinkEditPage(friendLink: link)),
    );

    if (result != null) {
      await _service.update(result);
      LogService.instance.logAction('编辑友链', detail: result.name);
      await _loadLinks();
      _markUnpushedChanges();
    }
  }

  Future<void> _deleteLink(FriendLink link) async {
    final s = AppStrings.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteFriendLink),
        content: Text('${s.deleteFriendLink}: ${link.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteFriendLink, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && link.id != null) {
      await _service.delete(link.id!);
      LogService.instance.logAction('删除友链', detail: link.name);
      await _loadLinks();
      _markUnpushedChanges();
    }
  }

  Future<void> _toggleLinkEnabled(FriendLink link, bool enabled) async {
    final updated = link.copyWith(isCommented: !enabled);
    await _service.update(updated);
    LogService.instance.logAction(
      enabled ? '启用友链' : '禁用友链',
      detail: link.name,
    );

    if (!mounted) return;
    setState(() {
      final index = _links.indexWhere((l) => l.id == link.id);
      if (index >= 0) {
        _links[index] = updated;
      }
      _hasUnpushedChanges = true;
    });
  }

  Future<void> _addDevLink() async {
    final devLink = FriendLink(
      name: '鼠鼠在碎觉',
      link: 'https://sszsj.com',
      avatar: 'https://tmx.fishpi.cn/image/head.jpg',
      descr: '我是不慎落入世界的一滴水墨',
      isDev: true,
    );

    final existing = await _service.getByName(devLink.name);
    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${devLink.name} 已存在')),
        );
      }
      return;
    }

    await _service.insert(devLink);
    LogService.instance.logAction('添加作者友链');
    await _loadLinks();
    _markUnpushedChanges();
  }

  Future<void> _pasteFromYaml() async {
    final s = AppStrings.current;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.pasteYaml),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: InputDecoration(
              hintText: '- name: xxx\n  link: https://xxx\n  avatar: https://xxx\n  descr: xxx',
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.done),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      final links = FriendLinkParser.parseYaml(controller.text);
      final count = await _service.insertBatch(links);
      LogService.instance.logAction('从 YAML 粘贴友链', detail: '$count 条');
      await _loadLinks();
      if (count > 0) {
        _markUnpushedChanges();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 $count 条友链')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canLeave = await _confirmLeaveWithUnpushedChanges();
        if (canLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.friendLinks),
          actions: _buildAppBarActions(s),
        ),
        body: Column(
          children: [
            _buildFilterBar(s),
            if (_hasUnpushedChanges) _buildUnpushedBanner(),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLinks.isEmpty
                      ? Center(
                          child: Text(
                            s.noItemsAvailable,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : _buildLinkList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMenu,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildUnpushedBanner() {
    final zh = AppStrings.isZh;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.tertiaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_upload_outlined, size: 18, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              zh ? '有未推送的友链修改' : 'Friend link changes are not pushed',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _syncing ? null : _pushToGitHub,
            child: Text(zh ? '推送' : 'Push'),
          ),
        ],
      ),
    );
  }

  bool get _isCompactLayout => MediaQuery.sizeOf(context).width < _compactBreakpoint;

  List<Widget> _buildAppBarActions(AppStrings s) {
    if (_isCompactLayout) {
      return [
        if (_syncing || _checking) const _SmallActionSpinner(),
        PopupMenuButton<_FriendLinkToolbarAction>(
          icon: const Icon(Icons.more_vert),
          tooltip: AppStrings.isZh ? '更多' : 'More',
          enabled: !_syncing,
          onSelected: (action) {
            switch (action) {
              case _FriendLinkToolbarAction.check:
                _checkLinks();
              case _FriendLinkToolbarAction.pull:
                _syncFromGitHub();
              case _FriendLinkToolbarAction.push:
                _pushToGitHub();
              case _FriendLinkToolbarAction.addDev:
                _addDevLink();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _FriendLinkToolbarAction.check,
              enabled: !_checking,
              child: _menuItem(
                icon: Icons.link_outlined,
                label: AppStrings.isZh ? '检测友链' : 'Check Links',
              ),
            ),
            PopupMenuItem(
              value: _FriendLinkToolbarAction.pull,
              child: _menuItem(
                icon: Icons.cloud_download_outlined,
                label: s.syncFriendLinks,
              ),
            ),
            PopupMenuItem(
              value: _FriendLinkToolbarAction.push,
              child: _menuItem(
                icon: Icons.cloud_upload_outlined,
                label: AppStrings.isZh ? '推送到 GitHub' : 'Push to GitHub',
              ),
            ),
            PopupMenuItem(
              value: _FriendLinkToolbarAction.addDev,
              child: _menuItem(
                icon: Icons.person_add_outlined,
                label: s.addDevFriendLink,
              ),
            ),
          ],
        ),
      ];
    }

    if (_syncing) {
      return [const _SmallActionSpinner()];
    }

    return [
      if (_checking)
        const _SmallActionSpinner()
      else
        IconButton(
          icon: const Icon(Icons.link_outlined),
          tooltip: '检测友链',
          onPressed: _checkLinks,
        ),
      IconButton(
        icon: const Icon(Icons.cloud_download_outlined),
        tooltip: s.syncFriendLinks,
        onPressed: _syncFromGitHub,
      ),
      IconButton(
        icon: const Icon(Icons.cloud_upload_outlined),
        tooltip: '推送到 GitHub',
        onPressed: _pushToGitHub,
      ),
      IconButton(
        icon: const Icon(Icons.person_add_outlined),
        tooltip: s.addDevFriendLink,
        onPressed: _addDevLink,
      ),
    ];
  }

  Widget _buildFilterBar(AppStrings s) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('${s.logAll} (${_links.length})', _FriendLinkFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip(
            '${s.friendLinkEnabled} (${_links.where((l) => !l.isCommented).length})',
            _FriendLinkFilter.enabled,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            '${s.friendLinkDisabled} (${_links.where((l) => l.isCommented).length})',
            _FriendLinkFilter.disabled,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, _FriendLinkFilter filter) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _buildLinkList() {
    final links = _filteredLinks;
    // 仅在「全部」视图下支持拖拽排序；对筛选子集重排语义不清晰。
    if (_filter != _FriendLinkFilter.all) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: links.length,
        itemBuilder: (ctx, index) => _buildLinkCard(links[index], null),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      buildDefaultDragHandles: false,
      itemCount: links.length,
      onReorderItem: _onReorder,
      itemBuilder: (ctx, index) => _buildLinkCard(links[index], index),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // 「全部」视图下 _filteredLinks 就是 _lists，索引一致。
    // onReorderItem 已自动处理下移时的索引调整，这里直接用 newIndex。
    setState(() {
      final link = _links.removeAt(oldIndex);
      _links.insert(newIndex.clamp(0, _links.length), link);
    });
    await _service.saveOrder(_links);
    _markUnpushedChanges();
  }

  Widget _buildLinkCard(FriendLink link, int? reorderIndex) {
    final s = AppStrings.current;
    final isDisabled = link.isCommented;
    final checkKey = _linkKey(link);
    final checkResult = _checkResults[checkKey];
    final isChecking = _checkingLinks.contains(checkKey);
    final compact = _isCompactLayout;

    return Card(
      key: reorderIndex != null ? ValueKey(link.id) : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      color: isDisabled
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: Stack(
        children: [
          InkWell(
            onTap: () => _editLink(link),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 拖拽手柄（仅在可排序时显示）
                  if (reorderIndex != null)
                    ReorderableDragStartListener(
                      index: reorderIndex,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.drag_handle,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: link.avatar.isNotEmpty ? NetworkImage(link.avatar) : null,
                    child: link.avatar.isEmpty
                        ? Text(link.name.isNotEmpty ? link.name[0] : '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                link.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (link.isDev)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'DEV',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (link.descr.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            link.descr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          link.link,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isChecking || checkResult != null) ...[
                          const SizedBox(height: 4),
                          _buildCheckResultLine(
                            result: checkResult,
                            checking: isChecking,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tooltip(
                    message: isDisabled ? s.friendLinkDisabled : s.friendLinkEnabled,
                    child: Switch(
                      value: !isDisabled,
                      onChanged: (enabled) => _toggleLinkEnabled(link, enabled),
                    ),
                  ),
                  if (compact)
                    _buildLinkMoreButton(link, isChecking)
                  else ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: s.editFriendLink,
                      onPressed: () => _editLink(link),
                    ),
                    IconButton(
                      icon: isChecking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.link, size: 20),
                      tooltip: '检测链接',
                      onPressed: isChecking ? null : () => _checkSingleLink(link),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteLink(link),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isDisabled) _buildDisabledCornerBadge(s),
        ],
      ),
    );
  }

  Widget _buildDisabledCornerBadge(AppStrings s) {
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          s.friendLinkDisabled,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkMoreButton(FriendLink link, bool isChecking) {
    final s = AppStrings.current;
    return PopupMenuButton<_FriendLinkItemAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: AppStrings.isZh ? '更多' : 'More',
      onSelected: (action) {
        switch (action) {
          case _FriendLinkItemAction.edit:
            _editLink(link);
          case _FriendLinkItemAction.check:
            _checkSingleLink(link);
          case _FriendLinkItemAction.delete:
            _deleteLink(link);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _FriendLinkItemAction.edit,
          child: _menuItem(icon: Icons.edit_outlined, label: s.editFriendLink),
        ),
        PopupMenuItem(
          value: _FriendLinkItemAction.check,
          enabled: !isChecking,
          child: _menuItem(
            icon: Icons.link,
            label: isChecking
                ? (AppStrings.isZh ? '检测中...' : 'Checking...')
                : (AppStrings.isZh ? '检测链接' : 'Check Link'),
          ),
        ),
        PopupMenuItem(
          value: _FriendLinkItemAction.delete,
          child: _menuItem(
            icon: Icons.delete_outline,
            label: s.deleteFriendLink,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckResultLine({
    required LinkCheckResult? result,
    required bool checking,
  }) {
    final zh = AppStrings.isZh;
    if (checking) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 6),
          Text(
            zh ? '检测中...' : 'Checking...',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final isOk = result?.isAccessible == true;
    final color = isOk ? Colors.green : Theme.of(context).colorScheme.error;
    final text = isOk
        ? '${zh ? '可访问' : 'Accessible'}${result?.statusCode == null ? '' : ' (${result!.statusCode})'}'
        : result?.error ?? (zh ? '不可访问' : 'Unavailable');

    return Row(
      children: [
        Icon(isOk ? Icons.check_circle : Icons.error, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _SmallActionSpinner extends StatelessWidget {
  const _SmallActionSpinner();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
