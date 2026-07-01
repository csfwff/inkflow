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

class FriendLinkPage extends StatefulWidget {
  const FriendLinkPage({super.key});

  @override
  State<FriendLinkPage> createState() => _FriendLinkPageState();
}

class _FriendLinkPageState extends State<FriendLinkPage> {
  final FriendLinkService _service = FriendLinkService();
  List<FriendLink> _links = [];
  bool _loading = true;
  bool _syncing = false;
  _FriendLinkFilter _filter = _FriendLinkFilter.all;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    await _service.init();
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

  Future<void> _addLink() async {
    final result = await Navigator.push<FriendLink>(
      context,
      MaterialPageRoute(builder: (_) => const FriendLinkEditPage()),
    );

    if (result != null) {
      await _service.insert(result);
      LogService.instance.logAction('添加友链', detail: result.name);
      await _loadLinks();
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
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(s.friendLinks),
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
              onSelected: (v) {
                switch (v) {
                  case 'sync':
                    _syncFromGitHub();
                  case 'push':
                    _pushToGitHub();
                  case 'dev':
                    _addDevLink();
                  case 'yaml':
                    _pasteFromYaml();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'sync', child: Text(s.syncFriendLinks)),
                PopupMenuItem(value: 'push', child: Text('推送到 GitHub')),
                PopupMenuItem(value: 'dev', child: Text(s.addDevFriendLink)),
                PopupMenuItem(value: 'yaml', child: Text(s.pasteYaml)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(s),
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
        onPressed: _addLink,
        child: const Icon(Icons.add),
      ),
    );
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: links.length,
      itemBuilder: (ctx, index) => _buildLinkCard(links[index]),
    );
  }

  Widget _buildLinkCard(FriendLink link) {
    final s = AppStrings.current;
    final isDisabled = link.isCommented;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isDisabled
          ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: InkWell(
        onTap: () => _editLink(link),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
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
                        if (isDisabled)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.friendLinkDisabled,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onErrorContainer,
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
                  ],
                ),
              ),
              // Delete
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteLink(link),
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
