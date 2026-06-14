import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkflow/l10n/app_strings.dart';
import 'package:inkflow/models/settings.dart';

void main() {
  group('AppStrings locale 选择', () {
    tearDown(() {
      // 重置为系统默认，避免影响其他测试
      AppStrings.setLocale(AppLocale.system);
    });

    test('setLocale(zh) 后 current 返回中文', () {
      AppStrings.setLocale(AppLocale.zh);
      expect(identical(AppStrings.current, AppStrings.zh), isTrue);
      expect(AppStrings.isZh, isTrue);
    });

    test('setLocale(en) 后 current 返回英文', () {
      AppStrings.setLocale(AppLocale.en);
      expect(identical(AppStrings.current, AppStrings.en), isTrue);
      expect(AppStrings.isZh, isFalse);
    });

    test('setLocale(system) 后 current 跟随系统', () {
      AppStrings.setLocale(AppLocale.system);
      // system 时取决于运行环境，但不应崩溃
      expect(AppStrings.current, isNotNull);
    });

    test('中文文案包含关键字段', () {
      expect(AppStrings.zh.appTitle, 'Inkflow');
      expect(AppStrings.zh.newArticle, '新建文章');
      expect(AppStrings.zh.publish, '发布');
      expect(AppStrings.zh.settingsTitle, '设置');
    });

    test('英文文案包含关键字段', () {
      expect(AppStrings.en.appTitle, 'Inkflow');
      expect(AppStrings.en.newArticle, 'New Article');
      expect(AppStrings.en.publish, 'Publish');
      expect(AppStrings.en.settingsTitle, 'Settings');
    });

    test('forLocale 返回正确的语言包', () {
      expect(identical(AppStrings.forLocale(const Locale('zh')), AppStrings.zh), isTrue);
      expect(identical(AppStrings.forLocale(const Locale('en')), AppStrings.en), isTrue);
      expect(identical(AppStrings.forLocale(const Locale('fr')), AppStrings.en), isTrue);
    });
  });
}
