import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/settings.dart';

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsPage({super.key, this.onSettingsChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Settings _settings;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _settings = settingsService.settings;
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${info.version}+${info.buildNumber}';
    });
  }

  Future<void> _save() async {
    await settingsService.save();
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.current;

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildGithubSection(s),
          const SizedBox(height: 16),
          _buildImageHostSection(s),
          const SizedBox(height: 16),
          _buildAppSection(s),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    bool obscure = false,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      obscureText: obscure,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── GitHub ──

  Widget _buildGithubSection(AppStrings s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sectionGithub,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildTextField(
              label: s.githubToken,
              value: _settings.githubToken,
              obscure: true,
              onChanged: (v) {
                _settings.githubToken = v;
                _save();
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: s.githubOwner,
              value: _settings.githubOwner,
              onChanged: (v) {
                _settings.githubOwner = v;
                _save();
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: s.githubRepo,
              value: _settings.githubRepo,
              onChanged: (v) {
                _settings.githubRepo = v;
                _save();
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: s.githubBranch,
              value: _settings.githubBranch,
              onChanged: (v) {
                _settings.githubBranch = v;
                _save();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Image Host ──

  Widget _buildImageHostSection(AppStrings s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sectionImageHost,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildDropdown<ImageHostType>(
              label: s.imageHostType,
              value: _settings.imageHostType,
              items: [
                DropdownMenuItem(
                    value: ImageHostType.github,
                    child: Text(s.imageHostGithub)),
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
            const SizedBox(height: 16),
            _buildImageHostFields(s),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHostFields(AppStrings s) {
    switch (_settings.imageHostType) {
      case ImageHostType.github:
        return Column(
          children: [
            _buildTextField(
              label: s.imageGithubRepo,
              value: _settings.imageGithubRepo,
              onChanged: (v) {
                _settings.imageGithubRepo = v;
                _save();
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: s.imageGithubPath,
              value: _settings.imageGithubPath,
              onChanged: (v) {
                _settings.imageGithubPath = v;
                _save();
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: s.imageGithubDomain,
              value: _settings.imageGithubDomain,
              onChanged: (v) {
                _settings.imageGithubDomain = v;
                _save();
              },
            ),
          ],
        );
      case ImageHostType.smms:
        return _buildTextField(
          label: s.smmsToken,
          value: _settings.smmsToken,
          obscure: true,
          onChanged: (v) {
            _settings.smmsToken = v;
            _save();
          },
        );
      case ImageHostType.imgur:
        return _buildTextField(
          label: s.imgurClientId,
          value: _settings.imgurClientId,
          onChanged: (v) {
            _settings.imgurClientId = v;
            _save();
          },
        );
    }
  }

  // ── App ──

  Widget _buildAppSection(AppStrings s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sectionApp,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildDropdown<AppLocale>(
              label: s.language,
              value: _settings.locale,
              items: [
                DropdownMenuItem(
                    value: AppLocale.system, child: Text(s.langSystem)),
                DropdownMenuItem(
                    value: AppLocale.zh, child: Text(s.langZh)),
                DropdownMenuItem(
                    value: AppLocale.en, child: Text(s.langEn)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _settings.locale = v);
                _save();
              },
            ),
            const SizedBox(height: 12),
            _buildDropdown<AppThemeMode>(
              label: s.theme,
              value: _settings.themeMode,
              items: [
                DropdownMenuItem(
                    value: AppThemeMode.system, child: Text(s.themeSystem)),
                DropdownMenuItem(
                    value: AppThemeMode.light, child: Text(s.themeLight)),
                DropdownMenuItem(
                    value: AppThemeMode.dark, child: Text(s.themeDark)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _settings.themeMode = v);
                _save();
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.version),
              trailing: Text(_version),
            ),
          ],
        ),
      ),
    );
  }
}
