import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/settings.dart';
import '../widgets/responsive.dart';

enum _Tab { general, github, imageHost }

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

  // TextEditingControllers — created once, reused across rebuilds
  late final TextEditingController _githubTokenCtrl;
  late final TextEditingController _githubOwnerCtrl;
  late final TextEditingController _githubRepoCtrl;
  late final TextEditingController _githubBranchCtrl;
  late final TextEditingController _imageGithubRepoCtrl;
  late final TextEditingController _imageGithubPathCtrl;
  late final TextEditingController _imageGithubDomainCtrl;
  late final TextEditingController _smmsTokenCtrl;
  late final TextEditingController _imgurClientIdCtrl;

  @override
  void initState() {
    super.initState();
    _settings = settingsService.settings;

    _githubTokenCtrl = TextEditingController(text: _settings.githubToken);
    _githubOwnerCtrl = TextEditingController(text: _settings.githubOwner);
    _githubRepoCtrl = TextEditingController(text: _settings.githubRepo);
    _githubBranchCtrl = TextEditingController(text: _settings.githubBranch);
    _imageGithubRepoCtrl = TextEditingController(text: _settings.imageGithubRepo);
    _imageGithubPathCtrl = TextEditingController(text: _settings.imageGithubPath);
    _imageGithubDomainCtrl = TextEditingController(text: _settings.imageGithubDomain);
    _smmsTokenCtrl = TextEditingController(text: _settings.smmsToken);
    _imgurClientIdCtrl = TextEditingController(text: _settings.imgurClientId);

    _loadVersion();
  }

  @override
  void dispose() {
    _githubTokenCtrl.dispose();
    _githubOwnerCtrl.dispose();
    _githubRepoCtrl.dispose();
    _githubBranchCtrl.dispose();
    _imageGithubRepoCtrl.dispose();
    _imageGithubPathCtrl.dispose();
    _imageGithubDomainCtrl.dispose();
    _smmsTokenCtrl.dispose();
    _imgurClientIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
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
      appBar:
          wide ? null : AppBar(title: Text(AppStrings.current.settingsTitle)),
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
        _infoRow(s.version, _version),
      ],
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
        _inputRow(
          controller: _githubRepoCtrl,
          onChanged: (v) {
            _settings.githubRepo = v;
            _save();
          },
        ),
        _divider(),
        _sectionHeader(s.githubBranch),
        _inputRow(
          controller: _githubBranchCtrl,
          onChanged: (v) {
            _settings.githubBranch = v;
            _save();
          },
        ),
      ],
    );
  }

  // ── Image Host tab ──

  Widget _buildImageHostTab(AppStrings s) {
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
                value: ImageHostType.smms, child: Text(s.imageHostSmms)),
            DropdownMenuItem(
                value: ImageHostType.imgur, child: Text(s.imageHostImgur)),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _settings.imageHostType = v);
            _save();
          },
        ),
        _divider(),
        _buildImageHostFields(s),
      ],
    );
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
              onChanged: (v) {
                _settings.imageGithubPath = v;
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
      case ImageHostType.smms:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(s.smmsToken),
            _inputRow(
              controller: _smmsTokenCtrl,
              obscure: true,
              onChanged: (v) {
                _settings.smmsToken = v;
                _save();
              },
            ),
          ],
        );
      case ImageHostType.imgur:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(s.imgurClientId),
            _inputRow(
              controller: _imgurClientIdCtrl,
              onChanged: (v) {
                _settings.imgurClientId = v;
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

  Widget _divider() {
    return Divider(height: 1, indent: 16);
  }

  Widget _inputRow({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(),
        ),
        obscureText: obscure,
        onChanged: onChanged,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
