import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  // ── SharedPreferences keys (普通配置) ──
  static const _keyGithubOwner = 'github_owner';
  static const _keyGithubRepo = 'github_repo';
  static const _keyGithubBranch = 'github_branch';
  static const _keyGithubPathPattern = 'github_path_pattern';
  static const _keyPermalinkPattern = 'permalink_pattern';
  static const _keyImageHostType = 'image_host_type';
  static const _keyImageGithubRepo = 'image_github_repo';
  static const _keyImageGithubPath = 'image_github_path';
  static const _keyImageGithubDomain = 'image_github_domain';
  static const _keyUpyunBucket = 'upyun_bucket';
  static const _keyUpyunOperator = 'upyun_operator';
  static const _keyUpyunDomain = 'upyun_domain';
  static const _keyUpyunPath = 'upyun_path';
  static const _keyImageUseDateFolder = 'image_use_date_folder';
  static const _keyImageNamingMode = 'image_naming_mode';
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';

  // ── Secure storage keys (敏感凭据) ──
  static const _secureGithubToken = 'github_token';
  static const _secureUpyunPassword = 'upyun_password';

  late SharedPreferences _prefs;
  late FlutterSecureStorage _secure;
  late Settings settings;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _secure = const FlutterSecureStorage();
    settings = await _load();
  }

  Future<Settings> _load() async {
    // 读取敏感字段：安全存储 -> 回退 SharedPreferences -> 迁移
    final githubToken = await _readSecureWithMigration(_secureGithubToken);
    final upyunPassword = await _readSecureWithMigration(_secureUpyunPassword);

    return Settings(
      githubToken: githubToken,
      githubOwner: _prefs.getString(_keyGithubOwner) ?? '',
      githubRepo: _prefs.getString(_keyGithubRepo) ?? '',
      githubBranch: _prefs.getString(_keyGithubBranch) ?? 'main',
      githubPathPattern:
          _prefs.getString(_keyGithubPathPattern) ?? '{year}/{month}',
      permalinkPattern: _prefs.getString(_keyPermalinkPattern) ??
          'articles/{year}/{month}/{day}/{timestamp}.html',
      imageHostType:
          ImageHostType.values[_prefs.getInt(_keyImageHostType) ?? 0],
      imageGithubRepo: _prefs.getString(_keyImageGithubRepo) ?? '',
      imageGithubPath: _cleanPath(_prefs.getString(_keyImageGithubPath) ?? 'images'),
      imageGithubDomain: _prefs.getString(_keyImageGithubDomain) ?? '',
      upyunBucket: _prefs.getString(_keyUpyunBucket) ?? '',
      upyunOperator: _prefs.getString(_keyUpyunOperator) ?? '',
      upyunPassword: upyunPassword,
      upyunDomain: _prefs.getString(_keyUpyunDomain) ?? '',
      upyunPath: _cleanPath(_prefs.getString(_keyUpyunPath) ?? ''),
      imageUseDateFolder: _prefs.getBool(_keyImageUseDateFolder) ?? false,
      imageNamingMode:
          ImageNamingMode.values[_prefs.getInt(_keyImageNamingMode) ?? 0],
      themeMode: AppThemeMode.values[_prefs.getInt(_keyThemeMode) ?? 0],
      locale: AppLocale.values[_prefs.getInt(_keyLocale) ?? 0],
    );
  }

  Future<void> save() async {
    // 敏感字段写入安全存储
    await Future.wait([
      _secure.write(key: _secureGithubToken, value: settings.githubToken),
      _secure.write(key: _secureUpyunPassword, value: settings.upyunPassword),
    ]);

    // 普通配置写入 SharedPreferences
    await Future.wait([
      _prefs.setString(_keyGithubOwner, settings.githubOwner),
      _prefs.setString(_keyGithubRepo, settings.githubRepo),
      _prefs.setString(_keyGithubBranch, settings.githubBranch),
      _prefs.setString(_keyGithubPathPattern, settings.githubPathPattern),
      _prefs.setString(_keyPermalinkPattern, settings.permalinkPattern),
      _prefs.setInt(_keyImageHostType, settings.imageHostType.index),
      _prefs.setString(_keyImageGithubRepo, settings.imageGithubRepo),
      _prefs.setString(_keyImageGithubPath, settings.imageGithubPath),
      _prefs.setString(_keyImageGithubDomain, settings.imageGithubDomain),
      _prefs.setString(_keyUpyunBucket, settings.upyunBucket),
      _prefs.setString(_keyUpyunOperator, settings.upyunOperator),
      _prefs.setString(_keyUpyunDomain, settings.upyunDomain),
      _prefs.setString(_keyUpyunPath, settings.upyunPath),
      _prefs.setBool(_keyImageUseDateFolder, settings.imageUseDateFolder),
      _prefs.setInt(_keyImageNamingMode, settings.imageNamingMode.index),
      _prefs.setInt(_keyThemeMode, settings.themeMode.index),
      _prefs.setInt(_keyLocale, settings.locale.index),
    ]);
  }

  /// 清理路径：去除前导和尾部斜杠
  String _cleanPath(String path) {
    return path.replaceAll(RegExp(r'^/+|/+$'), '');
  }

  /// 从安全存储读取，若为空则尝试从 SharedPreferences 迁移旧值。
  Future<String> _readSecureWithMigration(String key) async {
    // 优先读安全存储
    final secureValue = await _secure.read(key: key);
    if (secureValue != null && secureValue.isNotEmpty) return secureValue;

    // 回退：读 SharedPreferences 旧值
    final oldValue = _prefs.getString(key) ?? '';
    if (oldValue.isNotEmpty) {
      // 迁移到安全存储并清理旧值
      await _secure.write(key: key, value: oldValue);
      await _prefs.remove(key);
    }
    return oldValue;
  }
}
