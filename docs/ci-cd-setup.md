# CI/CD 自动构建与发布指南

## 概述

项目使用 GitHub Actions 实现自动构建和发布。当推送 `v*` 格式的 tag 时，自动构建以下平台并发布：

| 平台 | 产物 | 部署方式 |
|------|------|----------|
| Web | 静态网站 | 自动部署到 GitHub Pages |
| Android | APK + AAB | 发布到 GitHub Release |
| Windows | zip 压缩包 | 发布到 GitHub Release |
| Linux | tar.gz 压缩包 | 发布到 GitHub Release |
| macOS ARM | zip (Apple Silicon) | 发布到 GitHub Release |

---

## 发布流程

```bash
# 1. 更新 pubspec.yaml 中的版本号
# version: 1.1.0+2

# 2. 提交
git add .
git commit -m "release: v1.1.0"

# 3. 打 tag 并推送
git tag v1.1.0
git push origin master --tags
```

推送 tag 后，GitHub Actions 会自动运行，构建完成后在 [Releases](../../releases) 页面可以看到所有产物。

## 质量门禁

提交 Pull Request 或推送到 `master` 时，`Quality` 工作流会依次执行：

```text
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

标签发布工作流也会先执行同一套检查；任一步失败时，不会开始平台构建或创建
Release。提交前可在本地运行相同命令。

---

## 必须配置的 GitHub Secrets

在仓库的 **Settings → Secrets and variables → Actions** 中添加以下 Secrets：

### GitHub Pages（Web 部署）

无需额外配置 Secret，但需要在仓库设置中启用 GitHub Pages：

1. 进入仓库 **Settings → Pages**
2. **Source** 选择 **GitHub Actions**
3. 保存

### Android 签名（可选但强烈建议）

如果不配置，Android 产物将使用 debug 签名，无法上架应用商店。

#### 第一步：生成签名密钥

在本地执行以下命令生成 keystore 文件：

```bash
keytool -genkey -v -keystore inkflow-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias inkflow
```

按提示输入密码和信息。完成后会生成 `inkflow-release.jks` 文件。

> **注意：** 请妥善保管此文件和密码，丢失后无法恢复。

#### 第二步：配置 Secrets

需要配置 4 个 Secret：

| Secret 名称 | 说明 | 示例值 |
|-------------|------|--------|
| `KEYSTORE_BASE64` | keystore 文件的 Base64 编码 | 见下方命令 |
| `KEYSTORE_PASSWORD` | keystore 的密码 | `your_password` |
| `KEY_ALIAS` | 密钥别名 | `inkflow` |
| `KEY_PASSWORD` | 密钥密码 | `your_key_password` |

**获取 KEYSTORE_BASE64：**

```bash
# macOS / Linux
base64 -i inkflow-release.jks | tr -d '\n'

# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("inkflow-release.jks"))
```

将输出的整段字符串粘贴到 `KEYSTORE_BASE64` Secret 中。

---

## 工作流文件说明

工作流文件位于 `.github/workflows/release.yml`。

### 触发条件

- **推送 tag：** `git push origin v1.0.0` 会自动触发全部构建和发布
- **手动触发：** 在 GitHub Actions 页面点击 **Run workflow**（仅构建，不发布 Release）

### 构建流程

```
push v* tag
    └── quality
         ├── build-web ──────────→ deploy-pages (GitHub Pages)
         ├── build-android ──────→┐
         ├── build-windows ──────→│
         ├── build-linux ────────→├── release (GitHub Release)
         └── build-macos-arm ────→┘
```

- Web 和其他平台并行构建
- Web 构建完成后自动部署到 GitHub Pages
- 所有桌面/移动平台构建完成后，统一创建 GitHub Release

### 产物列表

| 产物 | 文件名 | 说明 |
|------|--------|------|
| Android APK | `app-release.apk` | 通用 APK，可直接安装 |
| Android AAB | `app-release.aab` | App Bundle，用于上架 Google Play |
| Windows | `inkflow-windows.zip` | 解压后运行 exe |
| Linux | `inkflow-linux.tar.gz` | 解压后运行可执行文件 |
| macOS ARM | `inkflow-macos-arm.zip` | Apple Silicon Mac 使用 |

---

## 常见问题

### Q: 如何手动触发构建但不发布？

在 GitHub → Actions → Build & Release → Run workflow，选择分支即可。手动触发不会创建 Release。

### Q: Android 构建报签名错误？

检查 Secrets 配置是否正确：
- `KEYSTORE_BASE64` 是否完整（无换行）
- `KEYSTORE_PASSWORD`、`KEY_ALIAS`、`KEY_PASSWORD` 是否与生成 keystore 时一致

### Q: 如何修改 Flutter 版本？

编辑 `.github/workflows/quality.yml` 和 `.github/workflows/release.yml` 中的
`flutter-version`，并保持两处一致。

### Q: GitHub Pages 部署失败？

1. 确认仓库 Settings → Pages 的 Source 已选择 **GitHub Actions**
2. 确认仓库是公开的（Private 仓库需要 GitHub Pro/Team）

### Q: 如何只构建部分平台？

编辑 `release.yml`，注释掉不需要的 job 即可。
