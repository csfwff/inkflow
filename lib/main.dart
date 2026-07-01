import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'l10n/app_strings.dart';
import 'models/settings.dart';
import 'pages/home_page.dart';
import 'services/log_service.dart';
import 'services/settings_service.dart';
import 'services/article_service.dart';

final settingsService = SettingsService();
final articleService = ArticleService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 桌面平台需要初始化 sqflite FFI（Web 不需要）
  if (!kIsWeb) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await articleService.init();
  await settingsService.init();
  AppStrings.setLocale(settingsService.settings.locale);

  // 记录启动日志
  final log = LogService.instance;
  final info = await PackageInfo.fromPlatform();
  log.info('应用启动: ${info.version}+${info.buildNumber}', tag: 'App');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final settings = settingsService.settings;

    return MaterialApp(
      title: AppStrings.current.appTitle,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _resolveThemeMode(settings.themeMode),
      locale: _resolveLocale(settings.locale),
      home: HomePage(onSettingsChanged: _onSettingsChanged),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF277568),
      brightness: brightness,
    ).copyWith(
      surface: isDark ? const Color(0xFF111413) : const Color(0xFFF8FAF8),
      surfaceContainerLowest:
          isDark ? const Color(0xFF0C0F0E) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          isDark ? const Color(0xFF171B1A) : const Color(0xFFF1F4F2),
      surfaceContainer:
          isDark ? const Color(0xFF1D2220) : const Color(0xFFEAF0ED),
      outlineVariant:
          isDark ? const Color(0xFF343B38) : const Color(0xFFDCE4E0),
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: colorScheme.surface,
    );
    final hintColor = colorScheme.onSurfaceVariant.withValues(
      alpha: isDark ? 0.50 : 0.58,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        hintStyle: TextStyle(color: hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  ThemeMode _resolveThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  Locale? _resolveLocale(AppLocale locale) {
    switch (locale) {
      case AppLocale.zh:
        return const Locale('zh');
      case AppLocale.en:
        return const Locale('en');
      case AppLocale.system:
        return null;
    }
  }

  void _onSettingsChanged() {
    AppStrings.setLocale(settingsService.settings.locale);
    setState(() {});
  }
}
