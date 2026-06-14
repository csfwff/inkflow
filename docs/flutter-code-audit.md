# Flutter 代码审计记录

审计日期：2026-06-13

## 范围

- Flutter/Dart 应用入口、页面、服务层、模型、数据库与测试。
- 重点路径：
  - `lib/main.dart`
  - `lib/pages/`
  - `lib/services/`
  - `lib/models/`
  - `test/widget_test.dart`
  - `pubspec.yaml`

## 验证记录

### `flutter analyze`

结果：失败，发现 2 个问题。

- `lib/services/database/_db_native.dart:13`：`dbPath` 已计算但未使用。
- `lib/services/database/_db_web.dart:3`：直接导入了 `sqlite3`，但 `pubspec.yaml` 没有声明直接依赖。

### `flutter test`

结果：未跑完业务测试，构建 native asset 阶段失败。

- `sqlite3` 尝试从 GitHub 下载 `libsqlite3.x64.linux.so`。
- 当前环境网络超时，导致 native assets 构建失败。
- 现有 `test/widget_test.dart` 仍是 Flutter 模板 Counter 测试，和当前应用不匹配。

## 修复清单

### AUDIT-001：同步失败会被误判为远程删除

优先级：高

相关位置：

- `lib/services/github_service.dart`
  - `listDirectoryContents`
- `lib/services/sync_service.dart`
  - `syncFromGitHub`
  - `_syncDirectory`
  - `_traverseDirectory`

问题：

- GitHub 目录请求失败、权限错误、rate limit、目录不存在、网络异常时，`listDirectoryContents` 返回空列表。
- `syncFromGitHub` 随后用这个空结果和本地文章对账，把本地 `synced/repoDraft` 文章标记为草稿。
- 这会让一次失败同步造成批量“远程已删除”的假状态。

建议修复：

- 不要用 `[]` 表示请求失败。
- 为目录读取引入明确结果类型，例如 `GitHubListResult(success, entries, error)`。
- 只有 `source/_posts` 和 `source/_drafts` 都成功完成拉取后，才执行远程删除对账。
- 404 是否表示“目录为空”需要单独定义；其他非 2xx 应视为同步失败。

验收标准：

- 断网或 GitHub 返回 401/403/500 时，同步失败并显示错误。
- 本地已同步文章状态不会被修改。
- 真正远程删除文件时，仍能正确标记本地状态。

### AUDIT-002：posts 和 drafts 远程身份混淆

优先级：高

相关位置：

- `lib/services/sync_service.dart`
  - `_traverseDirectory`
- `lib/services/article_service.dart`
  - `upsertFromGitHub`
- `lib/services/github_service.dart`
  - `updatePost`
  - `deletePost`
- `lib/pages/editor_page.dart`
  - `_publish`
- `lib/pages/home_page.dart`
  - `_deleteArticle`

问题：

- 同步时保存的 `filePath` 去掉了 `source/_posts/` 或 `source/_drafts/` 前缀。
- 本地 upsert 只按 `filePath` 匹配。
- 如果正式文章和仓库草稿同名，会互相覆盖。
- 删除远程文章时 `deletePost` 固定删除 `source/_posts/$filePath`，删除仓库草稿会失败。
- 已有草稿发布为正式文章时，当前逻辑更像“在不同目录更新同一个 sha”，而不是清晰的移动/发布流程。

建议修复：

- 数据模型增加远程身份字段：
  - `remotePath`：完整路径，如 `source/_posts/2026/06/a.md`
  - `remoteKind`：`post` / `draft`
- upsert 使用完整远程路径或 `(remoteKind, filePath)` 做唯一身份。
- GitHub 删除和更新方法直接接收完整 `remotePath`，避免内部猜目录。
- 草稿发布为正式文章时：
  - 在 `source/_posts` 创建或更新正式文章。
  - 成功后删除 `source/_drafts` 旧文件。
  - 本地更新 `remotePath`、`remoteKind`、`githubSha`、`status`。

验收标准：

- 同名 draft 和 post 可同时存在，不互相覆盖。
- 删除仓库草稿会请求 `source/_drafts/...`。
- 草稿发布为正式文章后，远程草稿不残留，正式文章 sha 正确保存。

### AUDIT-003：数据库升级会删表

优先级：高

状态：已修复。当前 `schemaVersion` 已升级到 2，迁移逻辑使用 `addColumn` 和数据回填，不再删除 `article_rows`。

相关位置：

- `lib/services/database/app_database.dart`
  - `migration`

问题：

- 旧实现中 `onUpgrade` 直接执行 `DROP TABLE IF EXISTS article_rows`。
- 后续任何 `schemaVersion` 增加都会清空用户本地文章。

建议修复：

- 用 Drift 的 `Migrator` 做按版本迁移。
- 每次新增字段都写清楚 from/to 逻辑。
- 给迁移补测试，至少覆盖旧 schema 到新 schema 的数据保留。

验收标准：

- 升级 schema 后，已有文章内容、状态、sha、metadata 不丢失。
- `flutter analyze` 不新增问题。

### AUDIT-004：敏感凭据明文存储

优先级：高

相关位置：

- `lib/services/settings_service.dart`
  - `save`
  - `_load`

问题：

- GitHub token、又拍云 operator password 等敏感信息保存在 `SharedPreferences`。
- 这些数据不适合放在普通偏好设置里。

建议修复：

- 使用系统安全存储保存敏感字段。
- 普通配置继续保存在 `SharedPreferences`。
- 引入安全存储时，设计一次迁移：
  - 读取旧 SharedPreferences 中的凭据。
  - 写入安全存储。
  - 清理旧明文字段。

验收标准：

- 新保存的 token/password 不再出现在 SharedPreferences。
- 已有用户升级后凭据仍可读取。
- 设置页显示和保存逻辑不回退。

### AUDIT-005：本地修改已同步文章后仍显示已同步

优先级：中

相关位置：

- `lib/pages/editor_page.dart`
  - `_buildArticle`
  - `_saveDraft`
- `lib/services/article_service.dart`
  - `update`
  - `upsertFromGitHub`

问题：

- 已同步文章本地修改保存后，仍保留 `ArticleStatus.synced`。
- 用户看到的是“已同步”，但远程并没有更新。
- 后续从 GitHub 同步时，远端内容可能覆盖本地未发布改动。

建议修复：

- 增加显式状态：
  - `pendingPublish`：本地修改，待发布。
  - `remoteDeleted`：远程已删除，本地保留。
- 本地保存已同步文章或仓库草稿时，把状态改为 `pendingPublish`，并保留 `remotePath`、`remoteKind`、`githubSha`。
- 同步远端内容前检测本地是否为 `pendingPublish`，是则不静默覆盖。
- 远端消失时，普通 `synced/repoDraft` 改为 `remoteDeleted`。
- 规划一个“从远端覆盖本地/放弃本地修改”的显式操作：
  - 仅对 `pendingPublish` 且仍存在远端文件的文章展示。
  - 点击后拉取 `remotePath` 最新内容，用远端内容覆盖本地内容和 metadata。
  - 状态恢复为 `synced` 或 `repoDraft`，`githubSha` 更新为远端最新 sha。
  - 如果远端已经不存在，提示远端文件不存在，不覆盖本地内容。
- 基于 `githubSha` 或 `updatedAt` 做冲突提示。

验收标准：

- 修改已同步文章并保存后，列表和编辑页显示“待发布/本地修改”。
- 拉取远端时不会静默覆盖本地未发布内容。
- 用户可以通过显式操作放弃本地修改，并从远端覆盖本地。
- 成功发布后状态恢复为 `synced`。

### AUDIT-006：Frontmatter 解析和生成不够可靠

优先级：中

相关位置：

- `lib/models/article.dart`
  - `buildFrontmatter`
  - `updateFrontmatter`
  - `bodyContent`
- `lib/services/sync_service.dart`
  - `_parseFrontmatter`
  - `_parseBlockList`

问题：

- 当前使用正则和字符串拼接处理 YAML frontmatter。
- 标题、标签、分类、描述中包含冒号、逗号、方括号、引号、换行时，可能生成非法 YAML 或解析错误。
- `date` 使用 `DateTime.tryParse`，但部分 Hexo 常见日期格式不一定能稳定解析。

建议修复：

- 使用 YAML 解析/编辑库处理 frontmatter。
- 保留未知字段。
- 写回时对字符串、列表、布尔值做正确 YAML 编码。
- 为常见 Hexo frontmatter 格式补单元测试。

验收标准：

- 含特殊字符的 title/tags/categories 能正确 round-trip。
- 未知字段保留。
- 正文中包含 `---` 不影响 frontmatter 边界识别。

### AUDIT-007：语言设置没有驱动业务文案

优先级：中

相关位置：

- `lib/main.dart`
  - `_resolveLocale`
- `lib/l10n/app_strings.dart`
  - `AppStrings.current`
- `lib/pages/`
  - 多处 `AppStrings.current`

问题：

- `MaterialApp.locale` 会读取设置。
- 但 `AppStrings.current` 直接读取 `PlatformDispatcher.instance.locale`。
- 用户在设置里切换中文/英文后，大部分业务文案仍跟随系统语言。

建议修复：

- 让 `AppStrings.current` 基于应用设置，而不是系统 locale。
- 或接入 Flutter 标准 l10n：`supportedLocales`、`localizationsDelegates`、ARB。
- 页面内避免用 `identical(AppStrings.current, AppStrings.zh)` 判断语言，改为明确 locale 状态。

验收标准：

- 系统语言为英文时，手动切换中文后所有应用文案显示中文。
- 系统语言为中文时，手动切换英文后所有应用文案显示英文。

### AUDIT-008：数据库路径实现不一致

优先级：中

相关位置：

- `lib/services/database/_db_native.dart`

问题：

- 代码计算了桌面端自定义目录和 `dbPath`，但最终 `SqfliteQueryExecutor.inDatabaseFolder(path: 'inkflow.db')` 没有使用这个路径。
- 这会让桌面端数据库位置不符合代码意图，也造成 analyzer warning。

建议修复：

- 明确 drift_sqflite 当前 API 的正确用法。
- 如果需要自定义路径，使用真实传入路径的 executor。
- 如果不需要自定义路径，删除 `_getDbDir`、`_getDesktopDir` 和 `dbPath` 相关逻辑。

验收标准：

- `flutter analyze` 中 `unused_local_variable` 消失。
- 桌面端数据库位置符合预期并有注释说明。

### AUDIT-009：依赖声明过松且缺直接依赖

优先级：低到中

相关位置：

- `pubspec.yaml`
- `lib/services/database/_db_web.dart`

问题：

- `sqlite3` 被直接导入，但没有在 `dependencies` 中声明。
- `drift`、`drift_sqflite`、`drift_dev`、`build_runner` 使用 `any`。
- 这会降低构建可复现性，也可能在未来依赖解析时引入不兼容版本。

建议修复：

- 在 `dependencies` 中添加直接依赖 `sqlite3`。
- 把 `any` 改为明确兼容范围。
- 跑一次 `flutter pub get` 和 `flutter analyze`。

验收标准：

- analyzer 不再报告 `depend_on_referenced_packages`。
- `pubspec.lock` 稳定。

### AUDIT-010：测试套件不可用

优先级：中

相关位置：

- `test/widget_test.dart`

问题：

- 测试仍是 Flutter Counter 模板。
- 当前应用初始化依赖数据库和 settings，全局 service 让 widget test 不易隔离。
- `flutter test` 当前还会触发 `sqlite3` native asset 下载，网络不可用时失败。

建议修复：

- 删除模板 Counter 测试，改成真实测试：
  - frontmatter round-trip 测试。
  - path builder 测试。
  - sync error 不误标远程删除测试。
  - settings locale 选择测试。
- 服务层引入可注入依赖，避免测试直接初始化真实数据库。
- 为 sqlite3 native asset 配置本地方案或在纯单元测试中避开数据库初始化。

验收标准：

- `flutter test` 能在无网络环境下运行核心单元测试。
- 至少覆盖 AUDIT-001、AUDIT-002、AUDIT-006 的关键边界。

## 建议修复顺序

1. 修 AUDIT-001：先防止同步失败误改本地状态。
2. 修 AUDIT-002：理清远程路径身份，避免 draft/post 数据混淆。
3. 修 AUDIT-010 的基础测试骨架：先建立能跑的单元测试。
4. 修 AUDIT-006：用测试保护 frontmatter 行为。
5. 修 AUDIT-005：补本地修改状态和冲突策略。
6. 修 AUDIT-003：迁移策略改为保数据。
7. 修 AUDIT-004：凭据迁到安全存储。
8. 修 AUDIT-007：修语言设置。
9. 修 AUDIT-008 和 AUDIT-009：清理 analyzer 和依赖声明。

## 后续工作记录

- [x] AUDIT-001
- [x] AUDIT-002
- [x] AUDIT-003
- [x] AUDIT-004
- [x] AUDIT-005
- [x] AUDIT-006
- [x] AUDIT-007
- [x] AUDIT-008
- [x] AUDIT-009
- [x] AUDIT-010
