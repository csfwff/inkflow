import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings.dart';

class SettingsService {
  static const _keyGithubToken = 'github_token';
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
  static const _keyUpyunPassword = 'upyun_password';
  static const _keyUpyunDomain = 'upyun_domain';
  static const _keyUpyunPath = 'upyun_path';
  static const _keyImageUseDateFolder = 'image_use_date_folder';
  static const _keyImageNamingMode = 'image_naming_mode';
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';

  late SharedPreferences _prefs;
  late Settings settings;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    settings = _load();
  }

  Settings _load() {
    return Settings(
      githubToken: _prefs.getString(_keyGithubToken) ?? '',
      githubOwner: _prefs.getString(_keyGithubOwner) ?? '',
      githubRepo: _prefs.getString(_keyGithubRepo) ?? '',
      githubBranch: _prefs.getString(_keyGithubBranch) ?? 'main',
      githubPathPattern: _prefs.getString(_keyGithubPathPattern) ?? '{year}/{month}',
      permalinkPattern: _prefs.getString(_keyPermalinkPattern) ?? 'articles/{year}/{month}/{day}/{timestamp}.html',
      imageHostType: ImageHostType.values[_prefs.getInt(_keyImageHostType) ?? 0],
      imageGithubRepo: _prefs.getString(_keyImageGithubRepo) ?? '',
      imageGithubPath: _prefs.getString(_keyImageGithubPath) ?? 'images',
      imageGithubDomain: _prefs.getString(_keyImageGithubDomain) ?? '',
      upyunBucket: _prefs.getString(_keyUpyunBucket) ?? '',
      upyunOperator: _prefs.getString(_keyUpyunOperator) ?? '',
      upyunPassword: _prefs.getString(_keyUpyunPassword) ?? '',
      upyunDomain: _prefs.getString(_keyUpyunDomain) ?? '',
      upyunPath: _prefs.getString(_keyUpyunPath) ?? '/',
      imageUseDateFolder: _prefs.getBool(_keyImageUseDateFolder) ?? false,
      imageNamingMode: ImageNamingMode.values[_prefs.getInt(_keyImageNamingMode) ?? 0],
      themeMode: AppThemeMode.values[_prefs.getInt(_keyThemeMode) ?? 0],
      locale: AppLocale.values[_prefs.getInt(_keyLocale) ?? 0],
    );
  }

  Future<void> save() async {
    await Future.wait([
      _prefs.setString(_keyGithubToken, settings.githubToken),
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
      _prefs.setString(_keyUpyunPassword, settings.upyunPassword),
      _prefs.setString(_keyUpyunDomain, settings.upyunDomain),
      _prefs.setString(_keyUpyunPath, settings.upyunPath),
      _prefs.setBool(_keyImageUseDateFolder, settings.imageUseDateFolder),
      _prefs.setInt(_keyImageNamingMode, settings.imageNamingMode.index),
      _prefs.setInt(_keyThemeMode, settings.themeMode.index),
      _prefs.setInt(_keyLocale, settings.locale.index),
    ]);
  }
}
