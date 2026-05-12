import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'models/settings.dart';
import 'pages/home_page.dart';
import 'services/settings_service.dart';
import 'services/article_service.dart';

final settingsService = SettingsService();
final articleService = ArticleService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settingsService.init();
  await articleService.init();
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _resolveThemeMode(settings.themeMode),
      locale: _resolveLocale(settings.locale),
      home: HomePage(onSettingsChanged: _onSettingsChanged),
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
    setState(() {});
  }
}
