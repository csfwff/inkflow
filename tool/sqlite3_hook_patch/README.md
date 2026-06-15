# sqlite3 native hook 补丁

## 问题背景

sqlite3 Flutter 包（v3.3.2）的 native assets hook 默认从 GitHub 下载预编译的 `.so` 文件。

在 Dart 3.6+ 中，`Object.hash` 使用随机种子，导致 hook 的缓存目录名每次运行都不同，
缓存机制失效，每次都重新下载。在国内网络环境下 GitHub 下载经常超时，导致 `flutter run`
和 `flutter build` 卡住。

## 解决方案

修改 sqlite3 包的 `hook/build.dart`，增加 `local_path` 选项：
- 当 `pubspec.yaml` 中配置了 `hooks.user_defines.sqlite3.local_path` 时，
  直接读取本地文件，跳过 GitHub 下载和 SHA-256 校验
- 未配置时保持原有行为（从 GitHub 下载）

## 文件说明

```
tool/sqlite3_hook_patch/
├── build.dart    # 修改后的 hook 文件（备份）
└── README.md     # 本说明
```

## 使用方法

### 1. 放置 .so 文件

将下载的 `libsqlite3.arm64.android.so` 放到项目中，例如：

```
lib/assets/libsqlite3.arm64.android.so
```

### 2. 配置 pubspec.yaml

在 `pubspec.yaml` 中添加 `hooks` 配置块（注意与 `flutter` 同级）：

```yaml
hooks:
  user_defines:
    sqlite3:
      local_path: lib/assets/libsqlite3.arm64.android.so
```

`local_path` 是相对于项目根目录的路径，可以改成你实际放置文件的位置。

### 3. 应用补丁

每次 `flutter pub get` 或 `flutter pub upgrade` 后，需要将备份的 `build.dart`
复制回 pub cache：

```bash
# Windows
copy tool\sqlite3_hook_patch\build.dart %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\sqlite3-3.3.2\hook\build.dart

# macOS/Linux
cp tool/sqlite3_hook_patch/build.dart ~/.pub-cache/hosted/pub.dev/sqlite3-3.3.2/hook/build.dart
```

或者直接运行项目根目录的 `apply_patch` 脚本（见下方）。

### 4. 运行构建

```bash
flutter run        # 开发调试
flutter build apk  # 构建 APK
```

## 自动应用补丁脚本

可以创建一个脚本自动应用补丁：

**Windows (apply_patch.bat)**:
```bat
@echo off
set HOOK_PATH=%LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\sqlite3-3.3.2\hook\build.dart
copy /Y tool\sqlite3_hook_patch\build.dart "%HOOK_PATH%"
echo sqlite3 hook patch applied.
```

**macOS/Linux (apply_patch.sh)**:
```bash
#!/bin/bash
HOOK_PATH=~/.pub-cache/hosted/pub.dev/sqlite3-3.3.2/hook/build.dart
cp -f tool/sqlite3_hook_patch/build.dart "$HOOK_PATH"
echo "sqlite3 hook patch applied."
```

## 注意事项

- 如果升级了 sqlite3 包版本（如 3.3.2 → 3.3.3），需要更新补丁中的路径
- 此补丁仅修改了下载逻辑，不影响 sqlite3 的运行时行为
- `lib/assets/` 目录下的 `.so` 文件应加入 `.gitignore`（体积较大），
  或者用 Git LFS 管理
