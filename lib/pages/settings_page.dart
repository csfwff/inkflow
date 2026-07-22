import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_strings.dart';
import '../main.dart';
import '../models/article.dart';
import '../models/app_theme_preset.dart';
import '../models/settings.dart';
import 'log_viewer_page.dart';
import '../services/github_service.dart';
import '../services/log_service.dart';
import '../services/image_host/image_path_builder.dart';
import '../widgets/responsive.dart';

enum _Tab { general, github, imageHost, about }

enum _UpdatePackageKind { androidApk, windowsZip, linuxTarGz }

class _UpdatePackageAsset {
  final _UpdatePackageKind kind;
  final String url;
  final String name;
  final String version;
  final int? size;

  const _UpdatePackageAsset({
    required this.kind,
    required this.url,
    required this.name,
    required this.version,
    this.size,
  });
}

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsPage({super.key, this.onSettingsChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const MethodChannel _updateChannel = MethodChannel(
    'com.xiaomo.inkflow/update',
  );

  _Tab _selectedTab = _Tab.general;
  late Settings _settings;
  String _version = '';

  bool _checkingUpdate = false;
  bool _downloading = false;
  final ValueNotifier<double?> _downloadProgressNotifier =
      ValueNotifier<double?>(null);
  bool _downloadDialogVisible = false;
  BuildContext? _downloadDialogContext;

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
    _githubPathPatternCtrl = TextEditingController(
      text: _settings.githubPathPattern,
    );
    _permalinkPatternCtrl = TextEditingController(
      text: _settings.permalinkPattern,
    );
    _imageGithubRepoCtrl = TextEditingController(
      text: _settings.imageGithubRepo,
    );
    _imageGithubPathCtrl = TextEditingController(
      text: _settings.imageGithubPath,
    );
    _imageGithubDomainCtrl = TextEditingController(
      text: _settings.imageGithubDomain,
    );
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
    _downloadProgressNotifier.dispose();
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
        Uri.parse(
          'https://api.github.com/repos/csfwff/inkflow/releases/latest',
        ),
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

      // 提取当前平台的安装包下载链接
      _UpdatePackageAsset? updateAsset;
      if (!kIsWeb &&
          (Platform.isAndroid || Platform.isWindows || Platform.isLinux)) {
        final assets = (data['assets'] as List<dynamic>?) ?? [];
        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          final name = assetMap['name'] as String? ?? '';
          final kind = _updatePackageKindForAsset(name);
          if (kind != null) {
            final downloadUrl = assetMap['browser_download_url'] as String?;
            if (downloadUrl != null && downloadUrl.isNotEmpty) {
              final size = assetMap['size'];
              updateAsset = _UpdatePackageAsset(
                kind: kind,
                url: downloadUrl,
                name: name,
                version: remoteVersion,
                size: size is int ? size : int.tryParse('$size'),
              );
            }
            break;
          }
        }
      }

      if (_isNewerVersion(remoteVersion, localVersion)) {
        var packageCached = false;
        if (updateAsset != null) {
          final packageFile = await _getUpdatePackageFile(updateAsset);
          packageCached = await _hasDownloadedPackage(
            packageFile,
            updateAsset.size,
          );
        }
        _showUpdateDialog(
          zh,
          remoteVersion,
          body,
          htmlUrl,
          updateAsset,
          packageCached: packageCached,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(zh ? '已是最新版本' : 'Already up to date')),
          );
        }
      }
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Update',
        context: '检查更新失败',
      );
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

  _UpdatePackageKind? _updatePackageKindForAsset(String name) {
    final lowerName = name.toLowerCase();
    if (!kIsWeb && Platform.isAndroid && lowerName.endsWith('.apk')) {
      return _UpdatePackageKind.androidApk;
    }
    if (!kIsWeb &&
        Platform.isWindows &&
        lowerName.endsWith('.zip') &&
        lowerName.contains('windows')) {
      return _UpdatePackageKind.windowsZip;
    }
    if (!kIsWeb &&
        Platform.isLinux &&
        lowerName.endsWith('.tar.gz') &&
        lowerName.contains('linux')) {
      return _UpdatePackageKind.linuxTarGz;
    }
    return null;
  }

  void _showUpdateDialog(
    bool zh,
    String version,
    String body,
    String url,
    _UpdatePackageAsset? updateAsset, {
    required bool packageCached,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          icon: Icon(
            Icons.system_update,
            color: Theme.of(ctx).colorScheme.primary,
            size: 40,
          ),
          title: Text(zh ? '发现新版本 v$version' : 'New version v$version'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    body.isNotEmpty
                        ? body
                        : (zh ? '有新版本可用' : 'A new version is available'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (packageCached) ...[
                    const SizedBox(height: 16),
                    Text(
                      _cachedPackageText(updateAsset, zh),
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
            if (!_downloading && updateAsset != null)
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _downloadAndInstall(updateAsset);
                },
                child: Text(
                  packageCached
                      ? _installButtonText(updateAsset, zh)
                      : (zh ? '下载安装' : 'Download & Install'),
                ),
              ),
            if (!_downloading && updateAsset == null)
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text(zh ? '前往下载' : 'Download'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndInstall(_UpdatePackageAsset updateAsset) async {
    final zh = AppStrings.isZh;
    if (_downloading) {
      _showDownloadProgressDialog(zh, updateAsset.version);
      return;
    }

    final packageFile = await _getUpdatePackageFile(updateAsset);
    if (await _hasDownloadedPackage(packageFile, updateAsset.size)) {
      _showInstallPrompt(
        updateAsset,
        packageFile.path,
        zh,
        alreadyDownloaded: true,
      );
      return;
    }

    setState(() {
      _downloading = true;
    });
    _setDownloadProgress(0);
    _showDownloadProgressDialog(zh, updateAsset.version);

    final canNotify = await _ensureNotificationPermission();
    if (canNotify) {
      _postDownloadProgressNotification(zh, 0);
    }

    final client = http.Client();
    final tempFile = File('${packageFile.path}.part');
    IOSink? sink;
    try {
      await packageFile.parent.create(recursive: true);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final request = http.Request('GET', Uri.parse(updateAsset.url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw HttpException('Update download failed: ${response.statusCode}');
      }

      final total = response.contentLength ?? updateAsset.size;
      int received = 0;
      int? lastNotifiedPercent = 0;
      sink = tempFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        final progress = total != null && total > 0 ? received / total : null;
        _setDownloadProgress(progress);

        final percent = progress == null
            ? null
            : (progress * 100).floor().clamp(0, 100).toInt();
        if (canNotify && percent != lastNotifiedPercent) {
          lastNotifiedPercent = percent;
          _postDownloadProgressNotification(zh, percent);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (updateAsset.size != null && updateAsset.size! > 0) {
        final downloadedSize = await tempFile.length();
        if (downloadedSize != updateAsset.size) {
          throw const FileSystemException('Update package size mismatch');
        }
      }

      if (await packageFile.exists()) {
        await packageFile.delete();
      }
      await tempFile.rename(packageFile.path);
      await _cleanupOldUpdatePackages(packageFile);

      _setDownloadProgress(1);
      if (canNotify) {
        _postDownloadCompleteNotification(zh, packageFile.path);
      }
      _closeDownloadProgressDialog();
      _showInstallPrompt(updateAsset, packageFile.path, zh);
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Update',
        context: '下载更新失败: ${updateAsset.name}',
      );
      try {
        await sink?.close();
      } catch (_) {}
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      if (canNotify) {
        _postDownloadFailedNotification(zh);
      }
      _closeDownloadProgressDialog();
      _showUpdateError(zh, downloading: true);
    } finally {
      client.close();
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  void _setDownloadProgress(double? progress) {
    if (!mounted) return;
    _downloadProgressNotifier.value = progress?.clamp(0.0, 1.0).toDouble();
  }

  void _showDownloadProgressDialog(bool zh, String version) {
    if (!mounted || _downloadDialogVisible) return;
    _downloadDialogVisible = true;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        _downloadDialogContext = ctx;
        return AlertDialog(
          icon: Icon(
            Icons.downloading,
            color: Theme.of(ctx).colorScheme.primary,
            size: 40,
          ),
          title: Text(zh ? '正在下载 v$version' : 'Downloading v$version'),
          content: ValueListenableBuilder<double?>(
            valueListenable: _downloadProgressNotifier,
            builder: (context, progress, _) {
              final percent = progress == null
                  ? null
                  : (progress * 100).floor().clamp(0, 100).toInt();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(
                    percent == null
                        ? (zh ? '正在下载...' : 'Downloading...')
                        : '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(zh ? '隐藏' : 'Hide'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _downloadDialogContext = null;
      _downloadDialogVisible = false;
    });
  }

  void _closeDownloadProgressDialog() {
    final dialogContext = _downloadDialogContext;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }
    _downloadDialogContext = null;
    _downloadDialogVisible = false;
  }

  void _showInstallPrompt(
    _UpdatePackageAsset updateAsset,
    String filePath,
    bool zh, {
    bool alreadyDownloaded = false,
  }) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.download_done,
          color: Theme.of(ctx).colorScheme.primary,
          size: 40,
        ),
        title: Text(
          alreadyDownloaded
              ? _readyPackageTitle(updateAsset, zh)
              : (zh ? '下载完成' : 'Download Complete'),
        ),
        content: Text(
          _installPromptContent(
            updateAsset,
            zh,
            alreadyDownloaded: alreadyDownloaded,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(zh ? '稍后安装' : 'Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _installUpdatePackage(updateAsset, filePath);
            },
            child: Text(_installButtonText(updateAsset, zh)),
          ),
        ],
      ),
    );
  }

  String _cachedPackageText(_UpdatePackageAsset? updateAsset, bool zh) {
    if (updateAsset?.kind == _UpdatePackageKind.windowsZip) {
      return zh
          ? '已检测到下载好的 Windows 更新包，可直接安装。'
          : 'The Windows update package is already downloaded and ready to install.';
    }
    if (updateAsset?.kind == _UpdatePackageKind.linuxTarGz) {
      return zh
          ? '已检测到下载好的 Linux 更新包，可直接安装。'
          : 'The Linux update package is already downloaded and ready to install.';
    }
    return zh
        ? '已检测到下载好的安装包，可直接安装。'
        : 'The APK is already downloaded and ready to install.';
  }

  String _readyPackageTitle(_UpdatePackageAsset updateAsset, bool zh) {
    if (updateAsset.kind == _UpdatePackageKind.windowsZip ||
        updateAsset.kind == _UpdatePackageKind.linuxTarGz) {
      return zh ? '更新包已下载' : 'Update Ready';
    }
    return zh ? '安装包已下载' : 'APK Ready';
  }

  String _installPromptContent(
    _UpdatePackageAsset updateAsset,
    bool zh, {
    required bool alreadyDownloaded,
  }) {
    if (updateAsset.kind == _UpdatePackageKind.windowsZip) {
      if (alreadyDownloaded) {
        return zh
            ? '检测到之前下载的 Windows 更新包，无需重新下载。安装会关闭并重启应用。'
            : 'A previously downloaded Windows update package was found. Installing will close and restart the app.';
      }
      return zh
          ? 'Windows 更新包已下载完成。安装会关闭并重启应用。'
          : 'The Windows update package has been downloaded. Installing will close and restart the app.';
    }
    if (updateAsset.kind == _UpdatePackageKind.linuxTarGz) {
      if (alreadyDownloaded) {
        return zh
            ? '检测到之前下载的 Linux 更新包，无需重新下载。安装会关闭并重启应用。'
            : 'A previously downloaded Linux update package was found. Installing will close and restart the app.';
      }
      return zh
          ? 'Linux 更新包已下载完成。安装会关闭并重启应用。'
          : 'The Linux update package has been downloaded. Installing will close and restart the app.';
    }
    return alreadyDownloaded
        ? (zh
              ? '检测到之前下载的安装包，无需重新下载。'
              : 'A previously downloaded APK was found. No need to download again.')
        : (zh
              ? '安装包已下载完成，可以开始安装。'
              : 'The APK has been downloaded and is ready to install.');
  }

  String _installButtonText(_UpdatePackageAsset updateAsset, bool zh) {
    if (updateAsset.kind == _UpdatePackageKind.windowsZip ||
        updateAsset.kind == _UpdatePackageKind.linuxTarGz) {
      return zh ? '立即安装并重启' : 'Install & Restart';
    }
    return zh ? '立即安装' : 'Install';
  }

  Future<void> _installUpdatePackage(
    _UpdatePackageAsset updateAsset,
    String filePath,
  ) async {
    switch (updateAsset.kind) {
      case _UpdatePackageKind.androidApk:
        await _installApk(filePath);
      case _UpdatePackageKind.windowsZip:
        await _installWindowsUpdate(filePath);
      case _UpdatePackageKind.linuxTarGz:
        await _installLinuxUpdate(filePath);
    }
  }

  Future<void> _installApk(String filePath) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _updateChannel.invokeMethod<void>('cancelDownloadNotification');
        await _updateChannel.invokeMethod<void>('installApk', {
          'filePath': filePath,
        });
        return;
      } catch (e, stack) {
        await LogService.instance.logException(
          e,
          stack,
          tag: 'Update',
          context: '调用 Android 安装接口失败，改用系统打开安装包',
        );
      }
    }
    await OpenFilex.open(filePath);
  }

  Future<void> _installWindowsUpdate(String packagePath) async {
    if (kIsWeb || !Platform.isWindows) {
      await OpenFilex.open(packagePath);
      return;
    }

    final zh = AppStrings.isZh;
    final exeFile = File(Platform.resolvedExecutable);
    final installDir = exeFile.parent;
    final canWrite = await _canWriteToDirectory(installDir);
    var runAsAdmin = false;

    if (!canWrite) {
      final confirmed = await _confirmWindowsAdminInstall(zh);
      if (confirmed != true) return;
      runAsAdmin = true;
    }

    try {
      final script = await _createWindowsUpdateScript(
        packagePath: packagePath,
        exePath: exeFile.path,
        installDir: installDir.path,
      );
      await _startWindowsUpdateScript(script.path, runAsAdmin: runAsAdmin);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Update',
        context: '启动 Windows 更新脚本失败',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            zh
                ? '启动 Windows 更新失败，请手动下载更新'
                : 'Failed to start Windows update. Please update manually.',
          ),
        ),
      );
    }
  }

  Future<void> _installLinuxUpdate(String packagePath) async {
    if (kIsWeb || !Platform.isLinux) {
      await OpenFilex.open(packagePath);
      return;
    }

    final zh = AppStrings.isZh;
    final exeFile = File(Platform.resolvedExecutable);
    final installDir = exeFile.parent;
    final canWrite = await _canWriteToDirectory(installDir);
    var usePkexec = false;
    String? pkexecPath;

    if (!canWrite) {
      pkexecPath = await _findExecutable('pkexec');
      if (pkexecPath == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              zh
                  ? '当前安装目录不可写，且未找到 pkexec，请手动解压更新包'
                  : 'The install directory is not writable and pkexec was not found. Please update manually.',
            ),
          ),
        );
        await OpenFilex.open(packagePath);
        return;
      }
      if (!mounted) return;
      final confirmed = await _confirmLinuxPrivilegedInstall(zh);
      if (confirmed != true) return;
      usePkexec = true;
    }

    try {
      final script = await _createLinuxUpdateScript(
        packagePath: packagePath,
        exePath: exeFile.path,
        installDir: installDir.path,
      );
      await _startLinuxUpdateScript(
        script.path,
        usePkexec: usePkexec,
        pkexecPath: pkexecPath,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Update',
        context: '启动 Linux 更新脚本失败',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            zh
                ? '启动 Linux 更新失败，请手动下载更新'
                : 'Failed to start Linux update. Please update manually.',
          ),
        ),
      );
    }
  }

  Future<bool> _canWriteToDirectory(Directory dir) async {
    try {
      final probe = File(p.join(dir.path, '.inkflow_update_write_test'));
      await probe.writeAsString('ok');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool?> _confirmWindowsAdminInstall(bool zh) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(zh ? '需要管理员权限' : 'Administrator Permission Required'),
        content: Text(
          zh
              ? '当前安装目录不可写，更新需要以管理员权限运行安装脚本。是否继续？'
              : 'The current install directory is not writable. The updater needs administrator permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(zh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(zh ? '继续' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmLinuxPrivilegedInstall(bool zh) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(zh ? '需要管理员权限' : 'Administrator Permission Required'),
        content: Text(
          zh
              ? '当前安装目录不可写，更新会通过 pkexec 请求管理员权限。安装完成后会关闭并重启应用，是否继续？'
              : 'The current install directory is not writable. The updater will request administrator permission through pkexec, then close and restart the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(zh ? '取消' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(zh ? '继续' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Future<File> _createWindowsUpdateScript({
    required String packagePath,
    required String exePath,
    required String installDir,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final updatesDir = Directory(p.join(dir.path, 'updates'));
    await updatesDir.create(recursive: true);
    final script = File(p.join(updatesDir.path, 'install_windows_update.ps1'));
    final exeName = p.basename(exePath);
    final logPath = p.join(updatesDir.path, 'windows_update.log');

    await script.writeAsString('''
\$ErrorActionPreference = 'Stop'
\$processId = $pid
\$zipPath = ${_psQuote(packagePath)}
\$exePath = ${_psQuote(exePath)}
\$exeName = ${_psQuote(exeName)}
\$installDir = ${_psQuote(installDir)}
\$logPath = ${_psQuote(logPath)}
\$stagingDir = Join-Path \$env:TEMP ('inkflow_update_' + [guid]::NewGuid().ToString('N'))
\$backupDir = Join-Path \$env:TEMP ('inkflow_backup_' + [guid]::NewGuid().ToString('N'))

function Write-UpdateLog([string]\$message) {
  \$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Add-Content -LiteralPath \$logPath -Value "[\$timestamp] \$message"
}

try {
  Write-UpdateLog 'Updater started.'
  for (\$i = 0; \$i -lt 120; \$i++) {
    \$process = Get-Process -Id \$processId -ErrorAction SilentlyContinue
    if (\$null -eq \$process) { break }
    Start-Sleep -Milliseconds 500
  }
  if (\$null -ne (Get-Process -Id \$processId -ErrorAction SilentlyContinue)) {
    throw 'InkFlow did not exit in time.'
  }

  New-Item -ItemType Directory -Path \$stagingDir -Force | Out-Null
  New-Item -ItemType Directory -Path \$backupDir -Force | Out-Null
  Expand-Archive -LiteralPath \$zipPath -DestinationPath \$stagingDir -Force

  \$expandedExe = Get-ChildItem -LiteralPath \$stagingDir -Recurse -Filter \$exeName | Select-Object -First 1
  if (\$null -eq \$expandedExe) {
    throw "Cannot find \$exeName in update package."
  }
  \$sourceDir = Split-Path -Parent \$expandedExe.FullName

  Get-ChildItem -LiteralPath \$installDir -Force | Copy-Item -Destination \$backupDir -Recurse -Force

  try {
    Get-ChildItem -LiteralPath \$sourceDir -Force | Copy-Item -Destination \$installDir -Recurse -Force
  } catch {
    Write-UpdateLog "Copy failed, restoring backup: \$(\$_.Exception.Message)"
    Get-ChildItem -LiteralPath \$backupDir -Force | Copy-Item -Destination \$installDir -Recurse -Force
    throw
  }

  \$newExe = Join-Path \$installDir \$exeName
  Start-Process -FilePath \$newExe -WorkingDirectory \$installDir
  Write-UpdateLog 'Updater finished.'
} catch {
  Write-UpdateLog "Updater failed: \$(\$_.Exception.Message)"
  Start-Process -FilePath \$exePath -WorkingDirectory \$installDir
} finally {
  Remove-Item -LiteralPath \$stagingDir -Recurse -Force -ErrorAction SilentlyContinue
}
''');
    return script;
  }

  Future<void> _startWindowsUpdateScript(
    String scriptPath, {
    required bool runAsAdmin,
  }) async {
    if (runAsAdmin) {
      final scriptArg =
          '-NoProfile -ExecutionPolicy Bypass -File "$scriptPath"';
      await Process.start('powershell.exe', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-Command',
        'Start-Process -FilePath powershell.exe -ArgumentList ${_psQuote(scriptArg)} -Verb RunAs',
      ], mode: ProcessStartMode.detached);
      return;
    }

    await Process.start('powershell.exe', [
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      '-File',
      scriptPath,
    ], mode: ProcessStartMode.detached);
  }

  String _psQuote(String value) {
    return "'${value.replaceAll("'", "''")}'";
  }

  Future<File> _createLinuxUpdateScript({
    required String packagePath,
    required String exePath,
    required String installDir,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final updatesDir = Directory(p.join(dir.path, 'updates'));
    await updatesDir.create(recursive: true);
    final script = File(p.join(updatesDir.path, 'install_linux_update.sh'));
    final exeName = p.basename(exePath);
    final logPath = p.join(updatesDir.path, 'linux_update.log');
    final env = Platform.environment;

    await script.writeAsString('''
#!/bin/sh
set -u

APP_PID=$pid
ARCHIVE=${_shQuote(packagePath)}
EXE_PATH=${_shQuote(exePath)}
EXE_NAME=${_shQuote(exeName)}
INSTALL_DIR=${_shQuote(installDir)}
LOG_PATH=${_shQuote(logPath)}
APP_USER=${_shQuote(env['USER'] ?? '')}
APP_HOME=${_shQuote(env['HOME'] ?? '')}
APP_DISPLAY=${_shQuote(env['DISPLAY'] ?? '')}
APP_WAYLAND_DISPLAY=${_shQuote(env['WAYLAND_DISPLAY'] ?? '')}
APP_XAUTHORITY=${_shQuote(env['XAUTHORITY'] ?? '')}
APP_DBUS_SESSION_BUS_ADDRESS=${_shQuote(env['DBUS_SESSION_BUS_ADDRESS'] ?? '')}
APP_XDG_RUNTIME_DIR=${_shQuote(env['XDG_RUNTIME_DIR'] ?? '')}
STAGING_DIR=\$(mktemp -d "\${TMPDIR:-/tmp}/inkflow_update_XXXXXX")
BACKUP_DIR=\$(mktemp -d "\${TMPDIR:-/tmp}/inkflow_backup_XXXXXX")

log() {
  printf '[%s] %s\\n' "\$(date '+%Y-%m-%d %H:%M:%S')" "\$1" >> "\$LOG_PATH" 2>/dev/null || true
}

cleanup() {
  rm -rf "\$STAGING_DIR"
}
trap cleanup EXIT

start_app() {
  cd "\$INSTALL_DIR" 2>/dev/null || true
  if [ "\$(id -u)" -eq 0 ] && [ -n "\$APP_USER" ] && command -v runuser >/dev/null 2>&1; then
    runuser -u "\$APP_USER" -- env \\
      HOME="\$APP_HOME" \\
      DISPLAY="\$APP_DISPLAY" \\
      WAYLAND_DISPLAY="\$APP_WAYLAND_DISPLAY" \\
      XAUTHORITY="\$APP_XAUTHORITY" \\
      DBUS_SESSION_BUS_ADDRESS="\$APP_DBUS_SESSION_BUS_ADDRESS" \\
      XDG_RUNTIME_DIR="\$APP_XDG_RUNTIME_DIR" \\
      "\$EXE_PATH" >/dev/null 2>&1 &
    return
  fi
  nohup "\$EXE_PATH" >/dev/null 2>&1 &
}

restore_and_restart() {
  log "\$1"
  if [ -d "\$BACKUP_DIR" ]; then
    cp -a "\$BACKUP_DIR"/. "\$INSTALL_DIR"/ 2>/dev/null || true
  fi
  start_app
  exit 1
}

log 'Updater started.'
i=0
while kill -0 "\$APP_PID" 2>/dev/null; do
  if [ "\$i" -ge 120 ]; then
    log 'InkFlow did not exit in time.'
    exit 1
  fi
  i=\$((i + 1))
  sleep 0.5
done

if ! tar -xzf "\$ARCHIVE" -C "\$STAGING_DIR"; then
  restore_and_restart 'Failed to extract update package.'
fi

UPDATED_EXE=\$(find "\$STAGING_DIR" -type f -name "\$EXE_NAME" -print -quit 2>/dev/null)
if [ -z "\$UPDATED_EXE" ]; then
  restore_and_restart "Cannot find \$EXE_NAME in update package."
fi
SOURCE_DIR=\$(dirname "\$UPDATED_EXE")

if ! cp -a "\$INSTALL_DIR"/. "\$BACKUP_DIR"/; then
  restore_and_restart 'Failed to create install backup.'
fi

if ! cp -a "\$SOURCE_DIR"/. "\$INSTALL_DIR"/; then
  log 'Copy failed, restoring backup.'
  cp -a "\$BACKUP_DIR"/. "\$INSTALL_DIR"/ 2>/dev/null || true
  start_app
  exit 1
fi

chmod +x "\$INSTALL_DIR/\$EXE_NAME" 2>/dev/null || true
start_app
log 'Updater finished.'
rm -rf "\$BACKUP_DIR"
''');
    await Process.run('chmod', ['+x', script.path]);
    return script;
  }

  Future<void> _startLinuxUpdateScript(
    String scriptPath, {
    required bool usePkexec,
    String? pkexecPath,
  }) async {
    if (usePkexec) {
      await Process.start(pkexecPath ?? 'pkexec', [
        '/bin/sh',
        scriptPath,
      ], mode: ProcessStartMode.detached);
      return;
    }

    await Process.start('/bin/sh', [
      scriptPath,
    ], mode: ProcessStartMode.detached);
  }

  Future<String?> _findExecutable(String name) async {
    if (kIsWeb) return null;
    try {
      final result = await Process.run('which', [name]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        if (output.isNotEmpty) {
          return output.split('\n').first.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  String _shQuote(String value) {
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }

  Future<File> _getUpdatePackageFile(_UpdatePackageAsset updateAsset) async {
    final dir = await getApplicationSupportDirectory();
    final fileName =
        'inkflow_${_safeFilePart(updateAsset.version)}_${_safeFilePart(updateAsset.name)}';
    return File(p.join(dir.path, 'updates', fileName));
  }

  String _safeFilePart(String value) {
    final safe = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    return safe.isEmpty ? 'update.apk' : safe;
  }

  Future<bool> _hasDownloadedPackage(File file, int? expectedSize) async {
    if (!await file.exists()) return false;
    final length = await file.length();
    if (expectedSize != null && expectedSize > 0) {
      return length == expectedSize;
    }
    return length > 0;
  }

  Future<void> _cleanupOldUpdatePackages(File keepFile) async {
    final dir = keepFile.parent;
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File &&
          entity.path != keepFile.path &&
          _sameUpdatePackageFamily(entity.path, keepFile.path)) {
        try {
          await entity.delete();
        } catch (e) {
          await LogService.instance.warn(
            '清理旧更新包失败: ${entity.path}: $e',
            tag: 'Update',
          );
        }
      }
    }
  }

  bool _sameUpdatePackageFamily(String filePath, String keepPath) {
    final fileName = p.basename(filePath).toLowerCase();
    final keepName = p.basename(keepPath).toLowerCase();
    if (keepName.endsWith('.tar.gz')) {
      return fileName.endsWith('.tar.gz');
    }
    return p.extension(filePath).toLowerCase() ==
        p.extension(keepPath).toLowerCase();
  }

  Future<bool> _ensureNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _updateChannel.invokeMethod<bool>(
            'ensureNotificationPermission',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  void _postDownloadProgressNotification(bool zh, int? percent) {
    _invokeUpdateChannel('showDownloadProgress', {
      'title': zh ? '正在下载 InkFlow 更新' : 'Downloading InkFlow Update',
      'text': percent == null
          ? (zh ? '正在下载...' : 'Downloading...')
          : '$percent%',
      'progress': percent ?? 0,
      'indeterminate': percent == null,
    });
  }

  void _postDownloadCompleteNotification(bool zh, String filePath) {
    _invokeUpdateChannel('showDownloadComplete', {
      'title': zh ? 'InkFlow 更新已下载' : 'InkFlow Update Downloaded',
      'text': zh ? '点击安装新版本' : 'Tap to install the new version',
      'filePath': filePath,
    });
  }

  void _postDownloadFailedNotification(bool zh) {
    _invokeUpdateChannel('showDownloadFailed', {
      'title': zh ? 'InkFlow 更新下载失败' : 'InkFlow Update Failed',
      'text': zh ? '请稍后重试' : 'Please try again later',
    });
  }

  void _invokeUpdateChannel(String method, Map<String, Object?> arguments) {
    if (kIsWeb || !Platform.isAndroid) return;
    unawaited(
      _updateChannel.invokeMethod<void>(method, arguments).catchError((_) {}),
    );
  }

  void _showUpdateError(bool zh, {bool downloading = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            downloading
                ? (zh
                      ? '更新下载失败，请稍后重试'
                      : 'Update download failed, please try later')
                : (zh
                      ? '检查更新失败，请稍后重试'
                      : 'Update check failed, please try later'),
          ),
        ),
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
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Settings',
        context: '加载 GitHub 仓库列表失败',
      );
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
    } catch (e, stack) {
      await LogService.instance.logException(
        e,
        stack,
        tag: 'Settings',
        context: '加载 GitHub 分支列表失败',
      );
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
    LogService.instance.info('设置已保存', tag: 'Settings');
    widget.onSettingsChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.current.settingsTitle)),
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
            _sidebarItem(
              _Tab.about,
              Icons.info_outline,
              AppStrings.isZh ? '关于' : 'About',
            ),
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
      (
        _Tab.about,
        Icons.info_outline,
        identical(s, AppStrings.zh) ? '关于' : 'About',
      ),
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
              value: AppLocale.system,
              child: Text(s.langSystem),
            ),
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
        _themePresetSelector(s),
        _divider(),
        _sectionHeader(
          identical(s, AppStrings.zh) ? '永久链接格式' : 'Permalink pattern',
        ),
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
                onChanged: (v) =>
                    setDialogState(() => includeSensitive = v ?? false),
                title: Text(
                  s.includeSensitive,
                  style: const TextStyle(fontSize: 13),
                ),
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
                final password = includeSensitive
                    ? passwordCtrl.text.trim()
                    : null;
                if (includeSensitive &&
                    (password == null || password.isEmpty)) {
                  return;
                }
                final encoded = settingsService.exportConfig(
                  includeSensitive: includeSensitive,
                  password: password,
                );
                Navigator.of(ctx).pop();
                _copyToClipboard(encoded);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.exportSuccess)));
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
                decoration: InputDecoration(labelText: s.importConfigHint),
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
                  success = await settingsService.importConfigEncrypted(
                    data,
                    password,
                  );
                }

                if (success) {
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(s.importSuccess)));
                    _refreshCtrlsFromSettings();
                    widget.onSettingsChanged?.call();
                  }
                } else if (needPassword) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(s.importFailed)));
                  }
                }
              },
              child: Text(
                needPassword ? s.importConfigConfirm : s.importConfig,
              ),
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
            icon: Icon(
              Icons.delete_forever,
              color: Theme.of(context).colorScheme.error,
            ),
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
                  onPressed: (_checkingUpdate || _downloading)
                      ? null
                      : () => _checkUpdate(zh),
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
                    errorBuilder: (_, __, ___) =>
                        CircleAvatar(radius: 24, child: Icon(Icons.person)),
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
                  SnackBar(
                    content: Text(
                      zh ? '已复制友链 YAML' : 'Friend link YAML copied',
                    ),
                  ),
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
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error,
          size: 40,
        ),
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.clearArticleDataDesc)));
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _settingSubLabel(s.themeMode),
          const SizedBox(height: 8),
          SegmentedButton<AppThemeMode>(
            segments: [
              ButtonSegment(
                value: AppThemeMode.system,
                label: Text(s.themeSystem),
              ),
              ButtonSegment(
                value: AppThemeMode.light,
                label: Text(s.themeLight),
              ),
              ButtonSegment(value: AppThemeMode.dark, label: Text(s.themeDark)),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (v) {
              setState(() => _settings.themeMode = v.first);
              _save();
            },
          ),
        ],
      ),
    );
  }

  Widget _themePresetSelector(AppStrings s) {
    final effectivePreset = AppThemePresets.byId(_settings.themePresetId);
    final zh = identical(s, AppStrings.zh);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _settingSubLabel(s.themeColor),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columnCount = constraints.maxWidth < 360
                  ? 1
                  : (constraints.maxWidth < 560 ? 2 : 3);
              final spacing = 8.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columnCount - 1)) /
                  columnCount;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final preset in AppThemePresets.all)
                    SizedBox(
                      width: itemWidth,
                      child: _themePresetCard(
                        preset,
                        selected: preset.id == effectivePreset.id,
                        zh: zh,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _themePresetCard(
    AppThemePreset preset, {
    required bool selected,
    required bool zh,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewScheme = ColorScheme.fromSeed(
      seedColor: preset.seedColor,
      brightness: Theme.of(context).brightness,
    );
    final borderColor = selected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.42)
          : colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (_settings.themePresetId == preset.id) return;
          setState(() => _settings.themePresetId = preset.id);
          _save();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: preset.seedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      preset.label(zh: zh),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected ? colorScheme.primary : null,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _themeSwatch(previewScheme.primary),
                  const SizedBox(width: 6),
                  _themeSwatch(previewScheme.secondary),
                  const SizedBox(width: 6),
                  _themeSwatch(previewScheme.tertiary),
                  const SizedBox(width: 6),
                  _themeSwatch(previewScheme.surfaceContainerHighest),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeSwatch(Color color) {
    return Expanded(
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
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
          hint: zh
              ? '可留空；仅填写相对目录，不含文件名'
              : 'Optional; enter a relative directory only, without filename',
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
        _divider(),
        _sectionHeader(zh ? '新建友链文件格式' : 'New friend link file format'),
        _dropdownRow<FriendLinkFileFormat>(
          value: _settings.friendLinkNewFileFormat,
          items: [
            DropdownMenuItem(
              value: FriendLinkFileFormat.butterfly,
              child: Text(
                zh
                    ? '分组格式（class_name / link_list）'
                    : 'Grouped (class_name / link_list)',
              ),
            ),
            DropdownMenuItem(
              value: FriendLinkFileFormat.flat,
              child: Text(
                zh ? '扁平格式（url / desc / image）' : 'Flat (url / desc / image)',
              ),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _settings.friendLinkNewFileFormat = value);
            _save();
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            zh
                ? '仅在远端文件不存在或为空时使用；已有文件会自动识别并保持原格式。'
                : 'Used only when the remote file is missing or empty. Existing files are detected and kept in their current format.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                            horizontal: 12,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value:
                                _repos.any(
                                  (r) => r.name == _settings.githubRepo,
                                )
                                ? _settings.githubRepo
                                : null,
                            isExpanded: true,
                            hint: Text(zh ? '选择仓库' : 'Select repository'),
                            items: _repos
                                .map(
                                  (repo) => DropdownMenuItem(
                                    value: repo.name,
                                    child: Row(
                                      children: [
                                        Icon(
                                          repo.private
                                              ? Icons.lock_outline
                                              : Icons.folder_outlined,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
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
                                  ),
                                )
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
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                            horizontal: 12,
                            vertical: 4,
                          ),
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
                                .map(
                                  (branch) => DropdownMenuItem(
                                    value: branch,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.fork_right,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(branch),
                                      ],
                                    ),
                                  ),
                                )
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
              value: ImageHostType.github,
              child: Text(s.imageHostGithub),
            ),
            DropdownMenuItem(
              value: ImageHostType.upyun,
              child: Text(s.imageHostUpyun),
            ),
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
              child: Text(zh ? '不使用' : 'None'),
            ),
            DropdownMenuItem(
              value: ImageDateFolderMode.year,
              child: Text(zh ? '年' : 'Year'),
            ),
            DropdownMenuItem(
              value: ImageDateFolderMode.yearMonth,
              child: Text(zh ? '年 / 月' : 'Year / Month'),
            ),
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
              child: Text(zh ? '时间戳' : 'Timestamp'),
            ),
            DropdownMenuItem(
              value: ImageNamingMode.original,
              child: Text(zh ? '源文件名' : 'Original name'),
            ),
            DropdownMenuItem(
              value: ImageNamingMode.timestampOriginal,
              child: Text(zh ? '时间戳 _ 源文件名' : 'Timestamp _ Original'),
            ),
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

  Widget _settingSubLabel(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 向指定输入框的光标位置插入文本
  void _insertToken(
    TextEditingController ctrl,
    String token,
    ValueChanged<String> setter,
  ) {
    final sel = ctrl.selection;
    final text = ctrl.text;
    final start = sel.start >= 0 ? sel.start : text.length;
    final newText =
        text.substring(0, start) +
        token +
        text.substring(sel.end >= 0 ? sel.end : text.length);
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

  Widget _buildQuickButtons(
    AppStrings s,
    TextEditingController ctrl,
    ValueChanged<String> setter,
    List<(String, String)> tokens,
  ) {
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
    return _buildQuickButtons(
      s,
      _permalinkPatternCtrl,
      (v) => _settings.permalinkPattern = v,
      [
        ('/', '/'),
        ('{year}', '{year}'),
        ('{month}', '{month}'),
        ('{day}', '{day}'),
        ('{timestamp}', '{timestamp}'),
        ('{slug}', '{slug}'),
        ('{category}', '{category}'),
        ('.html', '.html'),
      ],
    );
  }

  Widget _pathPatternQuickButtons(AppStrings s) {
    return _buildQuickButtons(
      s,
      _githubPathPatternCtrl,
      (v) => _settings.githubPathPattern = v,
      [
        ('/', '/'),
        ('{year}', '{year}'),
        ('{month}', '{month}'),
        ('{day}', '{day}'),
        ('{category}', '{category}'),
      ],
    );
  }

  String _buildPathPatternExample(AppStrings s) {
    final pattern = _githubPathPatternCtrl.text.trim();
    if (pattern.isEmpty) {
      return identical(s, AppStrings.zh)
          ? '留空时：保存为 source/_posts/hello-world.md'
          : 'When empty: saved as source/_posts/hello-world.md';
    }
    final now = DateTime.now();
    final example = Article.normalizeRelativeFilePath(
      pattern
          .replaceAll('{year}', now.year.toString())
          .replaceAll('{month}', now.month.toString().padLeft(2, '0'))
          .replaceAll('{day}', now.day.toString().padLeft(2, '0'))
          .replaceAll('{category}', 'tech'),
    );
    final examplePath = example.isEmpty
        ? 'source/_posts/hello-world.md'
        : 'source/_posts/$example/hello-world.md';
    return identical(s, AppStrings.zh)
        ? '示例：$examplePath（首尾 / 会自动忽略）'
        : 'Example: $examplePath (leading/trailing / is ignored)';
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
        .replaceAll(
          '{timestamp}',
          (now.millisecondsSinceEpoch ~/ 1000).toString(),
        )
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
