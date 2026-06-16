# Inkflow 开发方向规划

编写日期：2026-06-13

---

## 1. 图床上传路径配置优化

**现状**

- `upyunPath` 默认 `/`，`imageGithubPath` 默认 `images`，两个图床的路径语义不统一
- 用户输入路径时容易多写或漏写前导 `/`
- 设置页的路径预览（`_imagePathPreview`）已经存在，但输入体验不够直观

**方案**

- 在路径输入框左侧添加固定前缀 `/`（使用 `InputDecoration.prefixText` 或 `prefixIcon`），提示用户无需手动输入前导 `/`
- 统一两个图床的路径字段语义：都是"存储目录"，不包含前导 `/`
- `upyunPath` 默认值从 `/` 改为 `''`（空字符串表示根目录），与 GitHub 侧的 `imageGithubPath` 默认 `images` 对齐
- 迁移：读取旧值时自动清理前导 `/`

**可行性：高**

改动范围小（`settings_page.dart` 的输入框 + `settings_service.dart` 的迁移 + `image_path_builder.dart` 已有斜杠清理逻辑）。`InputDecoration.prefixText` 是 Flutter 原生支持的，零额外依赖。

---

## 2. GitHub 文件列表树展示

**现状**

- 同步时 `_traverseDirectory` 递归遍历 `source/_posts` 和 `source/_drafts`，但结果只存入数据库，没有目录结构的展示
- `GitHubService.listDirectoryContents` 已支持按目录列出子项

**方案**

- 新增 `FileTreePage`，从首页导航进入
- 复用 `listDirectoryContents` API，懒加载目录树（点击展开时才请求子目录）
- 数据结构：`TreeNode { name, path, type: dir|file, children?, sha }`
- 只展示 `.md` 文件，点击可跳转到编辑器（如果本地已有则打开本地版本，否则拉取远程内容）
- 目录树缓存在内存中，同步后刷新

**可行性：高**

核心 API 已就绪，主要是 UI 工作。难点在于 GitHub API 的 rate limit（每小时 5000 次），但目录树请求量不大。懒加载可以避免一次性大量请求。

---

## 3. 主题支持扩展

**现状**

- `AppThemeMode` 只有 `system / light / dark` 三选一
- 主题色硬编码为 `Color(0xFF277568)`（`main.dart` 的 `seedColor`）
- `ThemeData` 构建逻辑集中在 `_MyAppState._buildTheme`

**方案**

- 引入主题配置模型：`AppTheme { name, seedColor, brightness }`
- 内置几套预设主题（如当前的墨绿、蓝色、紫色等）
- 支持从 JSON/YAML 配置文件加载自定义主题：
  - 应用目录下放 `themes/custom_themes.yaml`
  - 格式：`[{name: "Ocean", seedColor: "#0077B6", brightness: light}]`
- 设置页的主题选择改为列表/卡片选择器，展示主题预览色块
- 自定义主题文件在应用启动时扫描加载

**可行性：中**

核心改动是把 `seedColor` 从硬编码改为可配置。`ColorScheme.fromSeed` 已经支持任意 seed color。JSON/YAML 解析（已有 `yaml` 包）和文件扫描（`path_provider` + `dart:io`）都是成熟方案。难点在于：深色/浅色模式下颜色的可读性需要做基本校验，以及自定义主题文件的错误处理。

---

## 4. 减少手动输入，增加选择/点击交互

**现状**

大部分设置项已经是输入框，用户需要手动输入仓库名、分支名、路径等。部分字段只有几个固定选项却用文本框。

**方案**

- **GitHub 仓库**：填入 token + owner 后，调用 GitHub API 列出该用户/组织的仓库列表，用下拉选择替代手动输入
- **分支**：选中仓库后，列出分支列表供选择
- **Categories**：已有分类时展示为 chip 列表，点击添加；允许手动输入新分类
- **Tags**：同上，已有标签展示为 chip，支持点击添加 + 手动输入
- **图床路径**：GitHub 图床填入 repo 后可浏览目录选择路径
- **日期子目录 / 文件命名**：已是下拉选择，保持不变

**可行性：中**

GitHub API 列出仓库和分支已有 `listDirectoryContents` 的模式可复用。主要工作量在：
1. 需要先验证 token 有效性再发请求
2. 异步加载时的 loading/error 状态处理
3. 去掉输入框后需要保留"手动输入"兜底（如仓库名不在列表中时）

建议分批推进：先做 layout/categories/tags 的选择器（纯本地数据，无 API 调用），再做 GitHub 仓库/分支的动态加载。

---

## 5. 基于 commit 记录的增量同步

**现状**

- `syncFromGitHub` 每次全量遍历 `source/_posts` 和 `source/_drafts` 所有文件
- 每个 `.md` 文件都要单独调用 `getFileContent` API
- 文章多时（>50 篇）API 调用次数 = 目录数 + 文件数，容易触发 rate limit

**方案**

利用 GitHub Commits API 做增量同步：

```
GET /repos/{owner}/{repo}/commits?path=source/_posts&since={lastSyncTime}&per_page=100
```

流程：
1. 本地记录 `lastSyncTime`（上次同步时间）
2. 请求 `source/_posts` 和 `source/_drafts` 的 commit 记录（`since` 参数过滤）
3. 从 commit 的 `files` 字段获取变更文件列表（added / modified / removed）
4. 只拉取 added/modified 的文件内容，标记 removed 的文件为 `remoteDeleted`
5. 更新 `lastSyncTime`

降级策略：如果增量请求失败（如 since 时间过旧、commit 数过多），自动回退到全量同步。

**可行性：中到高**

GitHub Commits API 支持 `path` 过滤和 `since` 时间过滤，`files` 字段会列出每个 commit 变更的文件。需要注意：
- `since` 用的是 commit 时间，不是文件修改时间
- 同一文件在两次同步间被多次修改只取最终状态
- force push 或 rebase 可能导致 commit 历史变化，需要处理
- per_page=100 限制，如果两个 commit 之间变更很多需要分页

建议保留全量同步作为"强制同步"选项，增量同步作为默认行为。

---

## 6. 网易云音乐外链播放器插入

**现状**

编辑器工具栏有图片插入、链接插入等功能，Markdown 插入模式已成熟。

**方案**

- 工具栏新增"音乐"按钮
- 点击后弹出搜索对话框：
  - 搜索框调用网易云音乐搜索 API（`https://music.163.com/api/search/get/web?s={keyword}&type=1&limit=10`）
  - 展示搜索结果列表（歌曲名、歌手、时长）
  - 点击歌曲选中
- 选中后弹出播放器配置面板：
  - 尺寸选择：小 / 中 / 大 / 自定义宽高
  - 自动播放开关
  - 是否显示歌词
- 生成并插入 HTML embed 代码：
  ```html
  <iframe frameborder="no" border="0" marginwidth="0" marginheight="0"
    width="330" height="86"
    src="//music.163.com/outchain/player?type=2&id={songId}&auto=0&height=66">
  </iframe>
  ```

**可行性：中**

技术上没有难点——搜索 API 是公开的，iframe embed 代码是标准 HTML。需要注意：
- 网易云 API 可能有反爬限制，需要设置合理的请求头（Referer、User-Agent）
- 部分歌曲可能没有外链权限
- Hexo 主题需要支持 iframe（大多数主题支持）
- 搜索 API 不需要登录，但接口稳定性不保证，需要做错误处理

建议先做搜索 + 插入的基础功能，播放器配置作为后续迭代。

---

## 7. 元数据图片配置增强

**现状**

- `topImg` 和 `cover` 字段是纯文本输入框，需要手动粘贴 URL
- 图片上传功能只在编辑器工具栏有（`_pickAndUploadImage`）

**方案**

在元数据页面为 `topImg` 和 `cover` 增加三种获取方式：

1. **直接上传**：复用已有的 `ImagePicker` + `ImageHostService` 上传流程
   - 支持相册选择和相机拍照（`ImageSource.gallery` / `ImageSource.camera`）
   - 上传后自动填入 URL

2. **从文章已上传图片选择**：解析文章正文中所有 `![...](url)` 的图片 URL，展示为缩略图列表供选择
   - 用正则 `!\[.*?\]\((https?://[^\)]+)\)` 提取
   - 展示为网格选择器

3. **手动输入 URL**：保留现有输入框作为兜底

UI 结构：输入框右侧添加图片选择按钮（图标），点击后弹出底部面板（BottomSheet），三个 tab 切换。

**可行性：高**

上传逻辑（`ImagePicker` + `ImageHostService`）已在编辑器中实现，直接复用。图片 URL 提取是纯正则操作。主要工作是 UI 组合：底部面板 + tab 切换 + 缩略图网格。

---

## 8. 自定义元数据支持

**现状**

- `Article` 模型有固定的元数据字段（tags, categories, permalink, topImg, cover, layout, comments, published, excerpt, description, author）
- `FrontmatterHelper` 已经支持保留未知字段（`updateFrontmatter` 保持原始字段顺序，未识别的行原样保留）
- 但 UI 层只展示固定字段，用户无法查看或编辑自定义元数据

**方案**

- `Article` 模型新增 `Map<String, String> customFields` 字段
- `FrontmatterHelper.parseFrontmatter` 返回完整 Map（已有），同步/加载时将已知字段提取到 Article 的强类型字段，剩余字段存入 `customFields`
- `FrontmatterHelper.updateFrontmatter` 已支持保留未知字段，无需改动
- 数据库存储：`customFields` 序列化为 JSON 字符串存入新列
- 元数据页面底部新增"自定义字段"区域：
  - 已有的自定义字段展示为 key-value 列表，可编辑/删除
  - "添加字段"按钮新增一行
  - key 输入框，value 输入框
- 保存时，自定义字段写回 frontmatter

**可行性：高**

核心改动小：
1. `FrontmatterHelper` 已经保留未知字段，无需改动解析逻辑
2. Article 模型加一个 `Map<String, String>` 字段
3. 数据库加一列（需 migration，schemaVersion 升到 3）
4. 元数据页面加一个动态列表 UI

唯一的边界情况是自定义字段名与内置字段名冲突时需要提示。

---

## 建议实施顺序

| 优先级 | 功能 | 理由 |
|---|---|---|
| 1 | 8. 自定义元数据 | 基础设施已就绪（FrontmatterHelper），改动最小，用户价值高 |
| 2 | 1. 图床路径配置优化 | 纯 UI 优化，工作量小，立即改善体验 |
| 3 | 4. 减少手动输入（第一批） | 先做 categories/tags 的选择器，纯本地改动 |
| 4 | 5. 增量同步 | 解决核心痛点（大仓库同步慢），API 可行性已验证 |
| 5 | 2. 文件列表树 | 依赖同步逻辑稳定后做，API 已就绪 |
| 6 | 7. 元数据图片增强 | 复用现有上传逻辑，主要是 UI 组合 |
| 7 | 4. 减少手动输入（第二批） | GitHub 仓库/分支动态加载，需要额外 API 集成 |
| 8 | 3. 主题扩展 | 独立功能，不影响核心流程 |
| 9 | 6. 网易云播放器 | 锦上添花，依赖外部 API 稳定性 |
