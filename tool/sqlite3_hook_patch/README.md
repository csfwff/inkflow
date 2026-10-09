# sqlite3 native hook 补丁

## 问题背景

sqlite3 Flutter 包（v3.3.2）的 native assets hook 默认从 GitHub 下载预编译的库文件
（Android 是 `.so`，Windows 是 `sqlite3.x64.windows.dll`）。

在 Dart 3.6+ 中，`Object.hash` 使用随机种子，导致 hook 的下载缓存目录名每次运行都不同
（见 `sqlite3/lib/src/hook/assets.dart` 的 `dirname => 'download-${hashCode...}'`），
缓存机制失效，每次构建都重新下载。在国内网络环境下 GitHub 下载经常超时，
导致 `flutter run` 和 `flutter build` 失败（错误形如
`Target build_hooks failed : Building native assets failed`）。

## 解决方案

修改 sqlite3 包的 `hook/build.dart`，增加按平台读取本地预编译库的能力：

- 先查 `hooks.user_defines.sqlite3.local_path_<os>`（例如 `local_path_windows`、
  `local_path_android`），查不到再回退到旧配置项 `local_path`
- 命中时直接复制本地文件，跳过 GitHub 下载和 SHA-256 校验
- 未配置的平台（Linux / macOS 等）保持原有行为（从 GitHub 下载）

因此可以只为本机需要的平台提供离线库，而不影响其它平台的构建与 CI。

## 文件说明

```
tool/sqlite3_hook_patch/
├── build.dart    # 修改后的 hook 文件（备份）
└── README.md     # 本说明

native/sqlite3/sqlite3-3.3.2/
├── android/arm64/libsqlite3.arm64.android.so   # 官方 release 二进制（已提交）
└── windows/x64/sqlite3.dll                      # 官方 release 二进制（已提交）
```

## 使用方法

### 1. 放置本地库文件

把官方 release 的二进制放到 `native/` 下对应平台目录，例如：

```
native/sqlite3/sqlite3-3.3.2/windows/x64/sqlite3.dll
native/sqlite3/sqlite3-3.3.2/android/arm64/libsqlite3.arm64.android.so
```

文件名必须以库文件本身的文件名结尾（hook 复制时会重命名成目标平台的标准文件名）。

### 2. 配置 pubspec.yaml

在 `pubspec.yaml` 中添加 `hooks` 配置块（注意与 `flutter` 同级），
路径相对项目根目录，使用正斜杠：

```yaml
hooks:
  user_defines:
    sqlite3:
      local_path_android: native/sqlite3/sqlite3-3.3.2/android/arm64/libsqlite3.arm64.android.so
      local_path_windows: native/sqlite3/sqlite3-3.3.2/windows/x64/sqlite3.dll
```

### 3. 应用补丁

每次 `flutter pub get` 或 `flutter pub upgrade` 后，pub cache 里的包会被重新解压，
补丁需要重新应用（脚本会同时清理 hook 的编译缓存，避免继续使用旧的 `hook.dill`）：

```bat
:: Windows
apply_patch.bat
```

```bash
# macOS / Linux
sh apply_patch.sh
```

也可以手动执行：

```bash
# Windows
copy /Y tool\sqlite3_hook_patch\build.dart %LOCALAPPDATA%\Pub\Cache\hosted\pub.dev\sqlite3-3.3.2\hook\build.dart

# macOS / Linux
cp tool/sqlite3_hook_patch/build.dart ~/.pub-cache/hosted/pub.dev/sqlite3-3.3.2/hook/build.dart
```

### 4. 运行构建

```bash
flutter run -d windows   # 桌面端
flutter run              # 手机
flutter build apk        # 构建 APK
```

## 与 GitHub Actions 的关系

CI（`.github/workflows/`）不应用本补丁，走的是 sqlite3 包原始的下载逻辑。
GitHub 的 runner 能正常访问 GitHub Releases，所以 CI 不受影响，也无需改动。
本补丁只影响本地构建：本地应用补丁后，Windows / Android 构建完全离线，不再依赖 GitHub。

## 注意事项

- 如果升级了 sqlite3 包版本（如 3.3.2 → 3.3.3），需要同步更新
  `apply_patch.bat` / `apply_patch.sh` 里的路径，并升级补丁本体
- 此补丁只修改了获取库文件的方式，不影响 sqlite3 的运行时行为
- `native/` 下的二进制文件体积较大，目前已直接提交到仓库；
  如后续觉得仓库过大可改用 Git LFS 管理
