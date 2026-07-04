# 功能 3：主题支持扩展调研

调研日期：2026-07-04

## 目标

扩展 Inkflow 的主题能力，让用户可以在现有“跟随系统 / 浅色 / 深色”的基础上选择不同主题色，并为后续自定义主题文件或应用内颜色选择器预留扩展空间。

## 结论

建议分阶段推进：

1. 第一阶段：内置主题预设 + 持久化主题 ID。
2. 第二阶段：从应用目录读取 YAML 自定义主题。
3. 第三阶段：应用内颜色选择器，作为可选增强。

优先不要把 `brightness` 放进主题预设模型。现有 `AppThemeMode { system, light, dark }` 已经负责亮暗模式，主题预设应只表达“色彩风格”，例如 seed color、名称、预览色等。这样可以避免“主题本身要求 dark，但用户选择 light”这类冲突。

## 当前现状

- 主题构建集中在 `lib/main.dart` 的 `_MyAppState._buildTheme`。
- 当前主题色硬编码为 `Color(0xFF277568)`。
- 亮暗模式由 `AppThemeMode { system, light, dark }` 控制。
- 设置页通用设置里已有主题分段按钮，只能切换系统 / 浅色 / 深色。
- 配置持久化在 `SettingsService`，使用 `SharedPreferences` 保存普通配置。
- `Settings.toExportJson` / `applyExportJson` 当前没有导出导入 `themeMode` 和 `locale`，功能 3 实现时建议顺手补齐。
- 项目已经有 `yaml` 和 `path_provider` 依赖，后续支持自定义主题文件不需要新增基础解析依赖。

## 推荐设计

新增一个轻量主题预设模型：

```dart
class AppThemePreset {
  final String id;
  final String name;
  final Color seedColor;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.seedColor,
  });
}
```

`Settings` 中新增字段：

```dart
String themePresetId;
```

默认值建议为当前墨绿色主题，例如 `inkGreen`。这样旧用户升级后视觉不变。

主题构建继续使用 Flutter Material 3 的 `ColorScheme.fromSeed`：

```dart
ColorScheme.fromSeed(
  seedColor: selectedPreset.seedColor,
  brightness: brightness,
)
```

现有 `_buildTheme(Brightness brightness)` 可以改为：

```dart
ThemeData _buildTheme(Brightness brightness, AppThemePreset preset)
```

或者内部从 `settingsService.settings.themePresetId` 解析当前预设。

## 内置主题建议

第一阶段可以先内置 5 到 6 个低风险主题：

- `inkGreen`：当前默认墨绿，保持兼容。
- `oceanBlue`：蓝色，适合偏工具感界面。
- `violet`：紫色，少量使用即可，不要大面积渐变。
- `rose`：暖色主题，主要用于强调色。
- `graphite`：中性灰黑，适合深色用户。
- `amber`：偏暖黄，用作轻量备选。

内置主题不要做得过于花哨。Inkflow 是写作和发布工具，整体仍应保持安静、耐看、低干扰。

## 设置页交互

建议在通用设置的“主题”区域拆成两块：

1. 亮暗模式：保留现有 `SegmentedButton<AppThemeMode>`。
2. 主题色：新增预设列表或紧凑卡片网格。

预设卡片建议包含：

- 主题名称。
- 一个主色圆点或色块。
- 一组小色条预览 primary / secondary / surface。
- 当前选中态。

窄屏下使用单列或两列，宽屏下可以使用更紧凑的网格。不要使用大面积营销式卡片，设置页应保持工具型密度。

## 自定义主题文件

第二阶段可以读取应用支持目录下：

```text
themes/custom_themes.yaml
```

推荐 YAML 格式：

```yaml
themes:
  - id: ocean
    name: Ocean
    seedColor: "#0077B6"
  - id: plum
    name: Plum
    seedColor: "#7B2CBF"
```

解析规则建议：

- `id` 必填，并且只允许字母、数字、短横线、下划线。
- `name` 必填，用于设置页展示。
- `seedColor` 必填，支持 `#RRGGBB` 和 `#AARRGGBB`。
- 自定义主题 ID 与内置主题冲突时，内置主题优先，或者在 UI 中提示冲突并忽略该自定义项。
- 文件不存在时静默回退，只展示内置主题。
- 文件格式错误时记录日志，并在设置页给出非阻塞提示。

## 应用内颜色选择器

第三阶段如果要支持“直接选择自定义颜色”，可以调研并引入颜色选择器包。

候选：

- `flex_color_picker`：维护状态和生态更稳，适合 Material 风格应用。
- `flutter_colorpicker`：更老，使用面广，但维护和发布者状态需要谨慎评估。

如果只做内置主题和 YAML 文件，不需要引入颜色选择器依赖。

## 需要改动的文件

第一阶段主要涉及：

- `lib/models/settings.dart`
  - 新增 `themePresetId`。
  - 导出导入配置时包含 `themeMode`、`locale`、`themePresetId`。
- `lib/services/settings_service.dart`
  - 新增 SharedPreferences key。
  - load/save 读写 `themePresetId`。
- `lib/main.dart`
  - 根据 `themePresetId` 获取预设。
  - `_buildTheme` 使用预设 seed color。
- `lib/pages/settings_page.dart`
  - 主题区域拆成亮暗模式和主题预设选择。
- `lib/l10n/app_strings.dart`
  - 增加主题预设选择相关文案。

第二阶段可能新增：

- `lib/models/app_theme_preset.dart`
- `lib/services/theme_registry.dart`
- `lib/services/theme_config_loader.dart`

## 风险点

- 全局 UI 颜色变化会影响按钮、Chip、选中态、文件树吸顶 overlay 等组件的可读性。
- 当前 `_buildTheme` 手动覆盖了 `surface`、`surfaceContainer*`、`outlineVariant`。如果只替换 seed color，页面底色仍会保持当前偏冷绿灰风格；这对稳定性有利，但主题差异会更克制。
- 如果希望 surface 也跟随主题变化，需要额外做对比度检查，避免浅色模式发灰或深色模式过彩。
- 导入旧配置时没有 `themePresetId`，必须回退到默认墨绿。
- 自定义 YAML 文件在桌面和移动端可行；如果未来支持 Web，需要另行设计，因为 Web 无法按相同方式读取本地应用目录。

## 测试建议

第一阶段：

- `Settings` 默认值测试：旧配置无 `themePresetId` 时回退 `inkGreen`。
- `SettingsService` load/save 测试：主题 ID 能正确持久化。
- 配置导入导出测试：`themeMode`、`locale`、`themePresetId` 能 round-trip。
- Widget smoke test：设置页主题预设选择后触发 `onSettingsChanged`。
- 手工检查浅色 / 深色 / 跟随系统下各内置主题的可读性。

第二阶段：

- YAML 文件不存在时只展示内置主题。
- YAML 格式错误时不崩溃并记录日志。
- 颜色格式非法时忽略对应主题。
- 自定义主题 ID 冲突时行为符合预期。

## 推荐实施顺序

1. 新增 `AppThemePreset` 和内置主题 registry。
2. `Settings` / `SettingsService` 增加 `themePresetId`。
3. `main.dart` 使用当前主题预设生成 `ColorScheme`。
4. 设置页增加主题预设选择 UI。
5. 补导入导出字段：`themeMode`、`locale`、`themePresetId`。
6. 做一轮浅色、深色、窄屏、宽屏的视觉检查。
7. 稳定后再做 YAML 自定义主题文件。

## 参考

- Flutter `ColorScheme.fromSeed`：https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html
- Flutter `ThemeData`：https://api.flutter.dev/flutter/material/ThemeData-class.html
- `path_provider`：https://pub.dev/packages/path_provider
- `yaml`：https://pub.dev/packages/yaml
- `flex_color_picker`：https://pub.dev/packages/flex_color_picker
