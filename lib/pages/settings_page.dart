import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/settings.dart';
import 'log_viewer_page.dart';
import '../services/github_service.dart';
import '../services/image_host/image_path_builder.dart';
import '../widgets/responsive.dart';

enum _Tab { general, github, imageHost, about }

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsPage({super.key, this.onSettingsChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _Tab _selectedTab = _Tab.general;
  late Settings _settings;
  String _version = '';

  bool _checkingUpdate = false;
  bool _downloading = false;
  double _downloadProgress = 0;

  // GitHub 仓库和分支列表
  List<GitHubRepo> _repos = [];
  List<String> _branches = [];
  bool _loadingRepos = false;
  bool _loadingBranches = false;
  String? _repoError;
  String? _branchError;

  // TextEditingControllers — created once, reused across rebuilds
  late final TextEditingController _githubTokenCtrl;
  late final TextEditingController _githubOwnerCtrl;
  late final TextEditingController _githubRepoCtrl;
  late final TextEditingController _githubBranchCtrl;
  late final TextEditingController _githubPathPatternCtrl;
  late final TextEditingController _permalinkPatternCtrl;
  late final TextEditingController _imageGithubRepoCtrl;
  late final TextEditingController _imageGithubPathCtrl;
  late final TextEditingController _imageGithubDomainCtrl;
  late final TextEditingController _upyunBucketCtrl;
  late final TextEditingController _upyunOperatorCtrl;
  late final TextEditingController _upyunPasswordCtrl;
  late final TextEditingController _upyunDomainCtrl;
  late final TextEditingController _upyunPathCtrl;
  late final TextEditingController _friendLinkPathCtrl;

  @override
  void initState() {
    super.initState();
    _settings = settingsService.settings;

    _githubTokenCtrl = TextEditingController(text: _settings.githubToken);
    _githubOwnerCtrl = TextEditingController(text: _settings.githubOwner);
    _githubRepoCtrl = TextEditingController(text: _settings.githubRepo);
    _githubBranchCtrl = TextEditingController(text: _settings.githubBranch);
    _githubPathPatternCtrl = TextEditingController(text: _settings.githubPathPattern);
    _permalinkPatternCtrl = TextEditingController(text: _settings.permalinkPattern);
    _imageGithubRepoCtrl = TextEditingController(text: _settings.imageGithubRepo);
    _imageGithubPathCtrl = TextEditingController(text: _settings.imageGithubPath);
    _imageGithubDomainCtrl = TextEditingController(text: _settings.imageGithubDomain);
    _upyunBucketCtrl = TextEditingController(text: _settings.upyunBucket);
    _upyunOperatorCtrl = TextEditingController(text: _settings.upyunOperator);
    _upyunPasswordCtrl = TextEditingController(text: _settings.upyunPassword);
    _upyunDomainCtrl = TextEditingController(text: _settings.upyunDomain);
    _upyunPathCtrl = TextEditingController(text: _settings.upyunPath);
    _friendLinkPathCtrl = TextEditingController(text: _settings.friendLinkPath);

    _loadVersion();
  }

  @override
  void dispose() {
    _githubTokenCtrl.dispose();
    _githubOwnerCtrl.dispose();
    _githubRepoCtrl.dispose();
    _githubBranchCtrl.dispose();
    _githubPathPatternCtrl.dispose();
    _permalinkPatternCtrl.dispose();
    _imageGithubRepoCtrl.dispose();
    _imageGithubPathCtrl.dispose();
    _imageGithubDomainCtrl.dispose();
    _upyunBucketCtrl.dispose();
    _upyunOperatorCtrl.dispose();
    _upyunPasswordCtrl.dispose();
    _upyunDomainCtrl.dispose();
    _upyunPathCtrl.dispose();
    _friendLinkPathCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _checkUpdate(bool zh) async {
    setState(() => _checkingUpdate = true);
    try {
      final resp = await http.get(
        Uri.parse('https://api.github.com/repos/csfwff/inkflow/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (resp.statusCode != 200) {
        _showUpdateError(zh);
        return;
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?) ?? '';
      final remoteVersion = tagName.replaceFirst('v', '');
      final localVersion = _version.split('+').first;
      final body = (data['body'] as String?) ?? '';
      final htmlUrl = (data['html_url'] as String?) ?? '';

      // 提取 APK 下载链接
      String? apkUrl;
      if (!kIsWeb && Platform.isAndroid) {
        final assets = (data['assets'] as List<dynamic>?) ?? [];
        for (final asset in assets) {
          final name = (asset as Map<String, dynamic>)['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      if (_isNewerVersion(remoteVersion, localVersion)) {
        _showUpdateDialog(zh, remoteVersion, body, htmlUrl, apkUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(zh ? '已是最新版本' : 'Already up to date')),
          );
        }
      }
    } catch (_) {
      _showUpdateError(zh);
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  bool _isNewerVersion(String remote, String local) {
    final r = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final l = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final lv = i < l.length ? l[i] : 0;
      if (rv > lv) return true;
      if (rv < lv) return false;
    }
    return false;
  }

  void _showUpdateDialog(bool zh, String version, String body, String url, String? apkUrl) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: Icon(Icons.system_update, color: Theme.of(ctx).colorScheme.primary, size: 40),
          title: Text(zh ? '发现新版本 v$version' : 'New version v$version'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    body.isNotEmpty ? body : (zh ? '有新版本可用' : 'A new version is available'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (_downloading) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _downloadProgress),
                    const SizedBox(height: 4),
                    Text(
                      '${(_downloadProgress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (!_downloading)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(zh ? '稍后再说' : 'Later'),
              ),
            if (!_downloading && apkUrl != null)
              FilledButton(
                onPressed: () => _downloadAndInstall(apkUrl, ctx),
                child: Text(zh ? '下载安装' : 'Download & Install'),
              ),
            if (!_downloading && apkUrl == null)
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                },
                child: Text(zh ? '前往下载' : 'Download'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndInstall(String url, BuildContext dialogCtx) async {
    final zh = AppStrings.isZh;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/inkflow_update.apk';
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        _showUpdateError(zh);
        return;
      }

      final total = response.contentLength;
      int received = 0;
      final sink = file.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total != null && total > 0) {
          setState(() => _downloadProgress = received / total);
        }
      });

      await sink.close();

      if (mounted && dialogCtx.mounted) {
        setState(() => _downloading = false);
        Navigator.of(dialogCtx).pop();
        await OpenFilex.open(filePath);
      }
    } catch (_) {
      if (mounted && dialogCtx.mounted) {
        setState(() => _downloading = false);
        Navigator.of(dialogCtx).pop();
        _showUpdateError(zh);
      }
    }
  }

  void _showUpdateError(bool zh) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(zh ? '检查更新失败，请稍后重试' : 'Update check failed, please try later')),
      );
    }
  }

  /// 加载仓库列表
  Future<void> _loadRepositories() async {
    if (_settings.githubToken.isEmpty || _settings.githubOwner.isEmpty) {
      return;
    }

    setState(() {
      _loadingRepos = true;
      _repoError = null;
    });

    try {
      final github = GitHubService(
        token: _settings.githubToken,
        owner: _settings.githubOwner,
        repo: _settings.githubRepo,
      );
      final repos = await github.listRepositories();
      if (mounted) {
        setState(() {
          _repos = repos;
          _loadingRepos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingRepos = false;
          _repoError = e.toString();
        });
      }
    }
  }

  /// 加载分支列表
  Future<void> _loadBranches() async {
    if (_settings.githubToken.isEmpty ||
        _settings.githubOwner.isEmpty ||
        _settings.githubRepo.isEmpty) {
      return;
    }

    setState(() {
      _loadingBranches = true;
      _branchError = null;
    });

    try {
      final github = GitHubService(
        token: _settings.githubToken,
        owner: _settings.githubOwner,
        repo: _settings.githubRepo,
      );
      final branches = await github.listBranches();
      if (mounted) {
        setState(() {
          _branches = branches;
          _loadingBranches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingBranches = false;
          _branchError = e.toString();
        });
      }
    }
  }

  /// Save settings without triggering a rebuild of this page.
  /// Only the parent (MyApp) needs to rebuild for theme/locale changes.
  Future<void> _save() async {
    await settingsService.save();
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.current.settingsTitle),
      ),
      body: wide ? _buildWide() : _buildNarrow(),
    );
  }

  // ── Wide: sidebar + content ──

  Widget _buildWide() {
    return Row(
      children: [
        _buildSidebar(),
        VerticalDivider(width: 1),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildSidebar() {
    final s = AppStrings.current;
    return SizedBox(
      width: 200,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _sidebarItem(_Tab.general, Icons.tune, s.tabGeneral),
            _sidebarItem(_Tab.github, Icons.code, s.tabGithub),
            _sidebarItem(_Tab.imageHost, Icons.image, s.tabImageHost),
            _sidebarItem(_Tab.about, Icons.info_outline, AppStrings.isZh ? '关于' : 'About'),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(_Tab tab, IconData icon, String label) {
    final selected = _selectedTab == tab;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20),
        title: Text(label),
        selected: selected,
        selectedTileColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => setState(() => _selectedTab = tab),
      ),
    );
  }

  // ── Narrow: tab bar + content ──

  Widget _buildNarrow() {
    return Column(
      children: [
        _buildTabBar(),
        Divider(height: 1),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildTabBar() {
    final s = AppStrings.current;
    final tabs = [
      (_Tab.general, Icons.tune, s.tabGeneral),
      (_Tab.github, Icons.code, s.tabGithub),
      (_Tab.imageHost, Icons.image, s.tabImageHost),
      (_Tab.about, Icons.info_outline, identical(s, AppStrings.zh) ? '关于' : 'About'),
    ];

    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: tabs.map((t) {
          final selected = _selectedTab == t.$1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _selectedTab = t.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.$2, size: 20),
                      const SizedBox(height: 4),
                      Text(t.$3, style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Content ──

  Widget _buildContent() {
    final s = AppStrings.current;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        switch (_selectedTab) {
          _Tab.general => _buildGeneralTab(s),
          _Tab.github => _buildGithubTab(s),
          _Tab.imageHost => _buildImageHostTab(s),
          _Tab.about => _buildAboutTab(s),
        },
      ],
    );
  }

  // ── General tab ──

  Widget _buildGeneralTab(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.language),
        _dropdownRow<AppLocale>(
          value: _settings.locale,
          items: [
            DropdownMenuItem(
                value: AppLocale.system, child: Text(s.langSystem)),
            DropdownMenuItem(value: AppLocale.zh, child: Text(s.langZh)),
            DropdownMenuItem(value: AppLocale.en, child: Text(s.langEn)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _settings.locale = v);
            _save();
          },
        ),
        _divider(),
        _sectionHeader(s.theme),
        _segmentedTheme(s),
        _divider(),
        _sectionHeader(identical(s, AppStrings.zh) ? '永久链接格式' : 'Permalink pattern'),
        _inputRow(
          controller: _permalinkPatternCtrl,
          hint: identical(s, AppStrings.zh)
              ? '点击下方按钮插入占位符'
              : 'Tap buttons below to insert placeholders',
          onChanged: (v) {
            _settings.permalinkPattern = v;
            _save();
          },
        ),
        _permalinkQuickButtons(s),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Text(
            _buildPermalinkExample(s),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        _divider(),
        _buildImportExport(s),
        _divider(),
        _buildLogViewerEntry(s),
        _divider(),
        _buildDangerZone(s),
      ],
    );
  }

  // ── Import / Export ──

  Widget _buildImportExport(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.exportConfig),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: Text(s.exportConfig),
                  onPressed: () => _showExportDialog(s),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: Text(s.importConfig),
                  onPressed: () => _showImportDialog(s),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogViewerEntry(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.logViewer),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.article_outlined),
              label: Text(s.logViewer),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LogViewerPage()),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showExportDialog(AppStrings s) {
    bool includeSensitive = false;
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.exportConfig),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: includeSensitive,
                onChanged: (v) => setDialogState(() => includeSensitive = v ?? false),
                title: Text(s.includeSensitive, style: const TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              if (includeSensitive) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: s.enterPassword,
                    hintText: s.passwordHint,
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () {
                final password = includeSensitive ? passwordCtrl.text.trim() : null;
                if (includeSensitive && (password == null || password.isEmpty)) return;
                final encoded = settingsService.exportConfig(
                  includeSensitive: includeSensitive,
                  password: password,
                );
                Navigator.of(ctx).pop();
                _copyToClipboard(encoded);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.exportSuccess)),
                );
              },
              child: Text(s.exportConfig),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(AppStrings s) {
    final dataCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool needPassword = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.importConfig),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dataCtrl,
                decoration: InputDecoration(
                  labelText: s.importConfigHint,
                ),
                maxLines: 3,
              ),
              if (needPassword) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  decoration: InputDecoration(
                    labelText: s.enterPassword,
                    hintText: s.passwordHint,
                  ),
                  obscureText: true,
                  autofocus: true,
                  keyboardType: TextInputType.visiblePassword,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final data = dataCtrl.text.trim();
                if (data.isEmpty) return;

                bool success;
                if (!needPassword) {
                  // 先尝试无密码导入（纯 base64 格式）
                  success = await settingsService.importConfigPlain(data);
                  if (!success) {
                    // 失败 → 可能是加密格式，显示密码输入框
                    setDialogState(() => needPassword = true);
                    return;
                  }
                } else {
                  // 用密码解密导入
                  final password = passwordCtrl.text.trim();
                  if (password.isEmpty) return;
                  success = await settingsService.importConfigEncrypted(data, password);
                }

                if (success) {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.importSuccess)),
                    );
                    _refreshCtrlsFromSettings();
                    widget.onSettingsChanged?.call();
                  }
                } else if (needPassword) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(s.importFailed)),
                    );
                  }
                }
              },
              child: Text(needPassword ? s.importConfigConfirm : s.importConfig),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshCtrlsFromSettings() {
    final st = settingsService.settings;
    _githubTokenCtrl.text = st.githubToken;
    _githubOwnerCtrl.text = st.githubOwner;
    _githubRepoCtrl.text = st.githubRepo;
    _githubBranchCtrl.text = st.githubBranch;
    _githubPathPatternCtrl.text = st.githubPathPattern;
    _permalinkPatternCtrl.text = st.permalinkPattern;
    _imageGithubRepoCtrl.text = st.imageGithubRepo;
    _imageGithubPathCtrl.text = st.imageGithubPath;
    _imageGithubDomainCtrl.text = st.imageGithubDomain;
    _upyunBucketCtrl.text = st.upyunBucket;
    _upyunOperatorCtrl.text = st.upyunOperator;
    _upyunPasswordCtrl.text = st.upyunPassword;
    _upyunDomainCtrl.text = st.upyunDomain;
    _upyunPathCtrl.text = st.upyunPath;
    setState(() => _settings = st);
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  Widget _buildDangerZone(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            s.dangerZone,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            icon: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            label: Text(
              s.clearArticleData,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.error),
            ),
            onPressed: () => _showClearDataDialog(s),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            s.clearArticleDataDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTab(AppStrings s) {
    final zh = identical(s, AppStrings.zh);
    const blogName = '鼠鼠在碎觉';
    const blogLink = 'https://sszsj.com';
    const blogAvatar = 'https://tmx.fishpi.cn/image/head.jpg';
    const blogDesc = '我是不慎落入世界的一滴水墨';
    const authorName = '唐墨夏';

    const friendLinkYaml = '''
- name: 鼠鼠在碎觉
  link: https://sszsj.com
  avatar: https://tmx.fishpi.cn/image/head.jpg
  descr: 我是不慎落入世界的一滴水墨''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.version),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                _version,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (!kIsWeb) ...[
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: (_checkingUpdate || _downloading) ? null : () => _checkUpdate(zh),
                  child: (_checkingUpdate || _downloading)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(zh ? '检查更新' : 'Check Update'),
                ),
              ],
            ],
          ),
        ),
        _divider(),
        _sectionHeader(zh ? '作者' : 'Author'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(blogLink)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    blogAvatar,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => CircleAvatar(
                      radius: 24,
                      child: Icon(Icons.person),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(blogLink)),
                      child: Text(
                        blogName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$authorName · $blogDesc',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _divider(),
        _sectionHeader(zh ? '友链信息（点击复制）' : 'Friend Link (tap to copy)'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: GestureDetector(
            onTap: () {
              _copyToClipboard(friendLinkYaml);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(zh ? '已复制友链 YAML' : 'Friend link YAML copied')),
                );
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                friendLinkYaml,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        _divider(),
        _sectionHeader(zh ? '问题反馈' : 'Feedback'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    zh
                        ? '请在摸鱼派发帖并 @csfwff'
                        : 'Post on FishPi and mention @csfwff',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.feedback_outlined, size: 16),
                    label: Text(zh ? '前往反馈' : 'Go'),
                    onPressed: () => launchUrl(
                      Uri.parse('https://fishpi.cn'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  zh ? '没有账号？点此注册' : 'No account? Register here',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => launchUrl(
                  Uri.parse('https://fishpi.cn/register?r=csfwff'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog(AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Theme.of(ctx).colorScheme.error, size: 40),
        title: Text(s.clearArticleData),
        content: Text(s.clearArticleDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await articleService.clearAll();
              _settings.lastSyncTime = null;
              _save();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.clearArticleDataDesc)),
                );
              }
            },
            child: Text(s.clearArticleDataConfirm),
          ),
        ],
      ),
    );
  }

  Widget _segmentedTheme(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SegmentedButton<AppThemeMode>(
        segments: [
          ButtonSegment(
              value: AppThemeMode.system, label: Text(s.themeSystem)),
          ButtonSegment(
              value: AppThemeMode.light, label: Text(s.themeLight)),
          ButtonSegment(
              value: AppThemeMode.dark, label: Text(s.themeDark)),
        ],
        selected: {_settings.themeMode},
        onSelectionChanged: (v) {
          setState(() => _settings.themeMode = v.first);
          _save();
        },
      ),
    );
  }

  // ── GitHub tab ──

  Widget _buildGithubTab(AppStrings s) {
    final zh = identical(s, AppStrings.zh);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.githubToken),
        _inputRow(
          controller: _githubTokenCtrl,
          obscure: true,
          onChanged: (v) {
            _settings.githubToken = v;
            _save();
          },
        ),
        _divider(),
        _sectionHeader(s.githubOwner),
        _inputRow(
          controller: _githubOwnerCtrl,
          onChanged: (v) {
            _settings.githubOwner = v;
            _save();
          },
        ),
        _divider(),
        _sectionHeader(s.githubRepo),
        _buildRepoSelector(s),
        _divider(),
        _sectionHeader(s.githubBranch),
        _buildBranchSelector(s),
        _divider(),
        _sectionHeader(zh ? '文章目录格式' : 'Post directory pattern'),
        _inputRow(
          controller: _githubPathPatternCtrl,
          hint: zh ? '点击下方按钮插入占位符' : 'Tap buttons below to insert placeholders',
          onChanged: (v) {
            _settings.githubPathPattern = v;
            _save();
          },
        ),
        _pathPatternQuickButtons(s),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Text(
            _buildPathPatternExample(s),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        _divider(),
        _sectionHeader(s.friendLinkPath),
        _inputRow(
          controller: _friendLinkPathCtrl,
          hint: 'source/_data/link.yml',
          onChanged: (v) {
            _settings.friendLinkPath = v;
            _save();
          },
        ),
      ],
    );
  }

  /// 仓库选择器：支持下拉选择 + 手动输入
  Widget _buildRepoSelector(AppStrings s) {
    final zh = identical(s, AppStrings.zh);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _repos.isEmpty
                    ? TextField(
                        controller: _githubRepoCtrl,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: zh ? '输入仓库名' : 'Enter repo name',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          _settings.githubRepo = v;
                          _save();
                        },
                      )
                    : InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _repos.any((r) => r.name == _settings.githubRepo)
                                ? _settings.githubRepo
                                : null,
                            isExpanded: true,
                            hint: Text(zh ? '选择仓库' : 'Select repository'),
                            items: _repos
                                .map((repo) => DropdownMenuItem(
                                      value: repo.name,
                                      child: Row(
                                        children: [
                                          Icon(
                                            repo.private
                                                ? Icons.lock_outline
                                                : Icons.folder_outlined,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              repo.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _settings.githubRepo = v;
                                  _githubRepoCtrl.text = v;
                                  // 选择仓库后自动加载分支
                                  _branches = [];
                                  _settings.githubBranch = 'main';
                                  _githubBranchCtrl.text = 'main';
                                });
                                _save();
                                _loadBranches();
                              }
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadingRepos ? null : _loadRepositories,
                icon: _loadingRepos
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: zh ? '加载仓库列表' : 'Load repositories',
              ),
            ],
          ),
          if (_repoError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _repoError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (_repos.isEmpty && !_loadingRepos && _repoError == null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                zh
                    ? '填入 Token 和 Owner 后点击刷新加载仓库列表'
                    : 'Enter Token and Owner, then refresh to load repositories',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 分支选择器：支持下拉选择 + 手动输入
  Widget _buildBranchSelector(AppStrings s) {
    final zh = identical(s, AppStrings.zh);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _branches.isEmpty
                    ? TextField(
                        controller: _githubBranchCtrl,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: zh ? '输入分支名' : 'Enter branch name',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          _settings.githubBranch = v;
                          _save();
                        },
                      )
                    : InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _branches.contains(_settings.githubBranch)
                                ? _settings.githubBranch
                                : null,
                            isExpanded: true,
                            hint: Text(zh ? '选择分支' : 'Select branch'),
                            items: _branches
                                .map((branch) => DropdownMenuItem(
                                      value: branch,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.fork_right,
                                            size: 16,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(branch),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  _settings.githubBranch = v;
                                  _githubBranchCtrl.text = v;
                                });
                                _save();
                              }
                            },
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadingBranches ? null : _loadBranches,
                icon: _loadingBranches
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: zh ? '加载分支列表' : 'Load branches',
              ),
            ],
          ),
          if (_branchError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _branchError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (_branches.isEmpty &&
              !_loadingBranches &&
              _branchError == null &&
              _settings.githubRepo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                zh ? '点击刷新加载分支列表' : 'Click refresh to load branches',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Image Host tab ──

  Widget _buildImageHostTab(AppStrings s) {
    final zh = identical(s, AppStrings.zh);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(s.imageHostType),
        _dropdownRow<ImageHostType>(
          value: _settings.imageHostType,
          items: [
            DropdownMenuItem(
                value: ImageHostType.github, child: Text(s.imageHostGithub)),
            DropdownMenuItem(
                value: ImageHostType.upyun, child: Text(s.imageHostUpyun)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _settings.imageHostType = v);
            _save();
          },
        ),
        _divider(),
        _buildImageHostFields(s),
        _divider(),
        _sectionHeader(zh ? '按日期分目录' : 'Date subfolders'),
        _dropdownRow<ImageDateFolderMode>(
          value: _settings.imageDateFolderMode,
          items: [
            DropdownMenuItem(
                value: ImageDateFolderMode.none,
                child: Text(zh ? '不使用' : 'None')),
            DropdownMenuItem(
                value: ImageDateFolderMode.year,
                child: Text(zh ? '年' : 'Year')),
            DropdownMenuItem(
                value: ImageDateFolderMode.yearMonth,
                child: Text(zh ? '年 / 月' : 'Year / Month')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _settings.imageDateFolderMode = v);
            _save();
          },
        ),
        _divider(),
        _sectionHeader(zh ? '文件命名' : 'File naming'),
        _dropdownRow<ImageNamingMode>(
          value: _settings.imageNamingMode,
          items: [
            DropdownMenuItem(
                value: ImageNamingMode.timestamp,
                child: Text(zh ? '时间戳' : 'Timestamp')),
            DropdownMenuItem(
                value: ImageNamingMode.original,
                child: Text(zh ? '源文件名' : 'Original name')),
            DropdownMenuItem(
                value: ImageNamingMode.timestampOriginal,
                child: Text(zh ? '时间戳 _ 源文件名' : 'Timestamp _ Original')),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _settings.imageNamingMode = v);
            _save();
          },
        ),
        _divider(),
        _sectionHeader(s.imageCompress),
        SwitchListTile(
          title: Text(s.imageCompress),
          subtitle: Text(s.imageCompressDesc),
          value: _settings.imageCompressEnabled,
          onChanged: (v) {
            setState(() => _settings.imageCompressEnabled = v);
            _save();
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        if (_settings.imageCompressEnabled)
          _dropdownRow<int>(
            value: _settings.imageCompressTargetKB,
            items: [
              DropdownMenuItem(value: 256, child: Text('256 KB')),
              DropdownMenuItem(value: 512, child: Text('512 KB')),
              DropdownMenuItem(value: 1024, child: Text('1024 KB')),
              DropdownMenuItem(value: 2048, child: Text('2048 KB')),
              DropdownMenuItem(value: 0, child: Text(s.imageCompressUnlimited)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _settings.imageCompressTargetKB = v);
              _save();
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Text(
            '${zh ? '示例：' : 'Example: '}${_imagePathPreview()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }

  /// 根据当前图床、路径与命名选择生成一条示例远程路径，与真实上传共用同一套逻辑。
  String _imagePathPreview() {
    final basePath = _settings.imageHostType == ImageHostType.github
        ? _settings.imageGithubPath
        : _settings.upyunPath;
    final remotePath = buildRemoteImagePath(
      basePath,
      'example.png',
      dateFolderMode: _settings.imageDateFolderMode,
      namingMode: _settings.imageNamingMode,
    );
    return '/$remotePath';
  }

  Widget _buildImageHostFields(AppStrings s) {
    switch (_settings.imageHostType) {
      case ImageHostType.github:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(s.imageGithubRepo),
            _inputRow(
              controller: _imageGithubRepoCtrl,
              onChanged: (v) {
                _settings.imageGithubRepo = v;
                _save();
              },
            ),
            _divider(),
            _sectionHeader(s.imageGithubPath),
            _inputRow(
              controller: _imageGithubPathCtrl,
              prefixText: '/',
              onChanged: (v) {
                final clean = v.replaceAll(RegExp(r'^/+'), '');
                setState(() => _settings.imageGithubPath = clean);
                _save();
              },
            ),
            _divider(),
            _sectionHeader(s.imageGithubDomain),
            _inputRow(
              controller: _imageGithubDomainCtrl,
              onChanged: (v) {
                _settings.imageGithubDomain = v;
                _save();
              },
            ),
          ],
        );
      case ImageHostType.upyun:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(s.upyunBucket),
            _inputRow(
              controller: _upyunBucketCtrl,
              hint: s.upyunBucketHint,
              onChanged: (v) {
                _settings.upyunBucket = v;
                _save();
              },
            ),
            _divider(),
            _sectionHeader(s.upyunOperator),
            _inputRow(
              controller: _upyunOperatorCtrl,
              hint: s.upyunOperatorHint,
              onChanged: (v) {
                _settings.upyunOperator = v;
                _save();
              },
            ),
            _divider(),
            _sectionHeader(s.upyunPassword),
            _inputRow(
              controller: _upyunPasswordCtrl,
              hint: s.upyunPasswordHint,
              obscure: true,
              onChanged: (v) {
                _settings.upyunPassword = v;
                _save();
              },
            ),
            _divider(),
            _sectionHeader(s.upyunDomain),
            _inputRow(
              controller: _upyunDomainCtrl,
              hint: s.upyunDomainHint,
              onChanged: (v) {
                _settings.upyunDomain = v;
                _save();
              },
            ),
            _divider(),
            _sectionHeader(s.upyunPath),
            _inputRow(
              controller: _upyunPathCtrl,
              hint: s.upyunPathHint,
              prefixText: '/',
              onChanged: (v) {
                final clean = v.replaceAll(RegExp(r'^/+'), '');
                setState(() => _settings.upyunPath = clean);
                _save();
              },
            ),
          ],
        );
    }
  }

  // ── Shared style widgets ──

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// 向指定输入框的光标位置插入文本
  void _insertToken(TextEditingController ctrl, String token, ValueChanged<String> setter) {
    final sel = ctrl.selection;
    final text = ctrl.text;
    final start = sel.start >= 0 ? sel.start : text.length;
    final newText = text.substring(0, start) + token + text.substring(sel.end >= 0 ? sel.end : text.length);
    ctrl.text = newText;
    ctrl.selection = TextSelection.collapsed(offset: start + token.length);
    setter(newText);
    _save();
  }

  /// 删除光标左侧内容：若左侧是占位符（如 {year}）则整体删除，否则删一个字符
  void _deleteToken(TextEditingController ctrl, ValueChanged<String> setter) {
    final sel = ctrl.selection;
    final text = ctrl.text;
    final pos = sel.start;
    if (pos <= 0) return;

    final placeholderRe = RegExp(r'\{[a-zA-Z]+\}$');
    final before = text.substring(0, pos);
    final match = placeholderRe.firstMatch(before);

    int deleteFrom;
    if (match != null) {
      deleteFrom = match.start;
    } else {
      deleteFrom = pos - 1;
    }

    final newText = text.substring(0, deleteFrom) + text.substring(pos);
    ctrl.text = newText;
    ctrl.selection = TextSelection.collapsed(offset: deleteFrom);
    setter(newText);
    _save();
  }

  Widget _buildQuickButtons(AppStrings s, TextEditingController ctrl, ValueChanged<String> setter, List<(String, String)> tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ...tokens.map((t) {
            return ActionChip(
              label: Text(t.$1, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              onPressed: () => _insertToken(ctrl, t.$2, setter),
            );
          }),
          ActionChip(
            label: Icon(Icons.backspace_outlined, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: () => _deleteToken(ctrl, setter),
          ),
        ],
      ),
    );
  }

  Widget _permalinkQuickButtons(AppStrings s) {
    return _buildQuickButtons(s, _permalinkPatternCtrl, (v) => _settings.permalinkPattern = v, [
      ('/', '/'),
      ('{year}', '{year}'),
      ('{month}', '{month}'),
      ('{day}', '{day}'),
      ('{timestamp}', '{timestamp}'),
      ('{slug}', '{slug}'),
      ('{category}', '{category}'),
      ('.html', '.html'),
    ]);
  }

  Widget _pathPatternQuickButtons(AppStrings s) {
    return _buildQuickButtons(s, _githubPathPatternCtrl, (v) => _settings.githubPathPattern = v, [
      ('/', '/'),
      ('{year}', '{year}'),
      ('{month}', '{month}'),
      ('{day}', '{day}'),
      ('{category}', '{category}'),
    ]);
  }

  String _buildPathPatternExample(AppStrings s) {
    final pattern = _githubPathPatternCtrl.text.trim();
    if (pattern.isEmpty) {
      return identical(s, AppStrings.zh)
          ? '示例：输入 {year}/{month} → 2026/06'
          : 'Example: {year}/{month} → 2026/06';
    }
    final now = DateTime.now();
    final example = pattern
        .replaceAll('{year}', now.year.toString())
        .replaceAll('{month}', now.month.toString().padLeft(2, '0'))
        .replaceAll('{day}', now.day.toString().padLeft(2, '0'))
        .replaceAll('{category}', 'tech');
    return identical(s, AppStrings.zh) ? '示例：$example' : 'Example: $example';
  }

  String _buildPermalinkExample(AppStrings s) {
    final pattern = _permalinkPatternCtrl.text.trim();
    if (pattern.isEmpty) {
      return identical(s, AppStrings.zh)
          ? '示例：输入 articles/{year}/{month}/{day}/{slug}.html → articles/2024/06/15/hello-world.html'
          : 'Example: articles/{year}/{month}/{day}/{slug}.html → articles/2024/06/15/hello-world.html';
    }
    // 用示例数据替换占位符
    final now = DateTime.now();
    final example = pattern
        .replaceAll('{year}', now.year.toString())
        .replaceAll('{month}', now.month.toString().padLeft(2, '0'))
        .replaceAll('{day}', now.day.toString().padLeft(2, '0'))
        .replaceAll('{timestamp}', (now.millisecondsSinceEpoch ~/ 1000).toString())
        .replaceAll('{slug}', 'hello-world')
        .replaceAll('{category}', 'tech');
    return identical(s, AppStrings.zh) ? '示例：$example' : 'Example: $example';
  }

  Widget _divider() {
    return Divider(height: 1, indent: 16);
  }

  Widget _inputRow({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool obscure = false,
    String? hint,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (prefixText != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                prefixText,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(),
              ),
              obscureText: obscure,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InputDecorator(
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          border: OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

}
