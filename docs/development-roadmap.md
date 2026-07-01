# Inkflow 开发方向规划

编写日期：2026-06-13
更新日期：2026-07-01

> **进度总览**
>
> - [x] 1. 图床上传路径配置优化
> - [ ] 2. GitHub 文件列表树展示
> - [ ] 3. 主题支持扩展
> - [x] 4. 减少手动输入，增加选择/点击交互
> - [x] 5. 基于 commit 记录的增量同步
> - [x] 6. 网易云音乐外链播放器插入
> - [x] 7. 元数据图片配置增强
> - [x] 8. 自定义元数据支持
> - [x] 9. 检查更新
> - [x] 10. 反馈入口
> - [x] 11. 应用内显示开发者信息
> - [x] 12. 友链编辑与管理
> - [x] 13. 图床图片压缩
> - [x] 14. 应用内日志查看

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

## 9. 检查更新

**现状**

- 应用没有版本更新检测机制，用户需要手动关注 GitHub 仓库获取新版本

**方案**

- 使用 GitHub Releases API 检查最新版本：
  ```
  GET https://api.github.com/repos/{owner}/{repo}/releases/latest
  ```
- 本地记录当前应用版本号（从 `pubspec.yaml` 的 `version` 字段读取）
- 设置页添加"检查更新"按钮，点击后对比本地版本与远程版本
- 发现新版本时弹出对话框，展示更新日志（release body），提供"前往下载"按钮跳转到 release 页面
- 可选：启动时静默检查，有更新时在首页展示小红点提示

**可行性：高**

GitHub Releases API 是公开的，无需认证（rate limit 60次/小时，足够用）。版本对比用 `semver` 比较即可。Flutter 的 `package_info_plus` 插件可以方便地获取当前版本号。

---

## 10. 反馈入口

**现状**

- 用户遇到问题或有建议时没有统一的反馈渠道

**方案**

- 设置页添加"问题反馈"入口
- 点击后跳转到摸鱼派发帖页面：`https://fishpi.cn`
- 引导文案提示用户发帖并 @csfwff
- 展示注册链接供新用户使用：`https://fishpi.cn/register?r=csfwff`
- 使用 `url_launcher` 打开外部链接

**可行性：高**

纯 UI + 外部链接跳转，无技术难点。`url_launcher` 是 Flutter 官方维护的成熟插件。

---

## 11. 应用内显示开发者信息

**现状**

- 设置页没有展示开发者和博客信息

**方案**

- 设置页底部添加"关于"区域，展示开发者信息：
  - 博客头像（圆形，点击跳转博客）
  - 博客名称：鼠鼠在碎觉
  - 作者：唐墨夏
  - 简介：我是不慎落入世界的一滴水墨
- 点击博客名称或头像跳转到 https://sszsj.com（`url_launcher`）
- 信息硬编码即可，无需配置化

**可行性：高**

纯 UI 展示 + 外部链接，零技术难点。

---

## 12. 友链编辑与管理

**现状**

- 设置页"关于"tab 有一段硬编码的友链 YAML 文本，仅供复制
- 没有友链的增删改查能力
- 友链文件中可能有注释条目（`# - name: xxx`），表示暂时移除的友链，标准 YAML 解析器会丢弃注释

**方案**

### 数据模型

`FriendLink` 模型：
- `id` — 数据库主键
- `name` — 名称
- `link` — 链接
- `avatar` — 头像 URL
- `descr` — 简介
- `isCommented` — 是否被注释（暂时禁用状态）
- `isDev` — 是否为开发者友链（标记作者预置的友链）

### 友链文件解析

自定义逐行解析器（不复用 `FrontmatterHelper`，因标准 `yaml` 包会丢弃注释）：

```yaml
# 解析逻辑：
# "# - name: xxx" → isCommented: true
# "- name: xxx"   → isCommented: false
# 非列表行（如空行、顶部注释）→ 跳过或保留为文件头尾
```

生成时根据 `isCommented` 决定是否加 `# ` 前缀，保持注释条目的原始格式不丢失。

### 数据库存储

- 新增 `FriendLinkRows` 表（Drift）
- 字段：`id`, `name`, `link`, `avatar`, `descr`, `isCommented`, `isDev`, `createdAt`
- `schemaVersion` 升级，需 migration

### 设置项

- 友链文件路径：可配置，默认 `source/_data/links.yml`
- 存入 `Settings`，在设置页"通用"或"GitHub"tab 中展示

### GitHub 同步

- 独立同步按钮（不在文章同步流程中）
- 点击后从 GitHub 拉取友链文件 → 解析 → 更新本地数据库
- 推送时：本地数据 → 生成 YAML → GitHubService.createFile / updateFile
- 首次同步时文件可能不存在，需处理 404

### UI 设计

**首页入口：**
- 顶部操作区或菜单中增加"友链管理"入口
- 点击进入 `FriendLinkPage`

**友链列表页（`FriendLinkPage`）：**
- 默认显示全部友链
- 注释友链：灰色背景 + "已禁用"状态标签
- 筛选/分组切换：
  - **筛选模式**：顶部 chip（全部 / 启用中 / 已禁用）
  - **分组模式**：按启用状态分组显示
- 每条友链卡片：头像、名称、简介、链接、状态
- 点击卡片进入编辑
- 滑动或长按删除
- FAB 点击 → 手动逐条添加（打开编辑表单）
- FAB 长按 → 从 YAML 粘贴批量添加

**友链编辑表单：**
- 字段：名称、链接、头像 URL、简介
- 开关：启用/禁用（控制是否注释）
- 保存后更新本地数据库

**添加开发者友链：**
- 友链列表页和设置页"关于"tab 都添加"添加作者友链"按钮
- 点击后一键将开发者预置友链（name: 鼠鼠在碎觉, link: https://sszsj.com 等）插入本地数据库
- 已添加时按钮置灰或提示"已添加"

**快速添加（YAML 粘贴）：**
- FAB 长按或菜单项触发"从 YAML 粘贴"
- 弹出对话框，提供多行文本输入框，支持粘贴友链 YAML 片段：
  ```yaml
  - name: xxx
    link: https://xxx
    avatar: https://xxx
    descr: xxx
  ```
- 解析逻辑复用友链文件的逐行解析器，支持注释条目（`#` 前缀标记为禁用）
- 解析后预览列表（名称 + 链接），显示解析成功/失败数量
- 确认后批量插入本地数据库，自动跳过已存在的同名友链
- 解析失败时高亮错误行，提示格式问题

**可行性：中**

核心难点是自定义 YAML 逐行解析（保留注释），但技术上很直接——逐行判断 `# ` 前缀即可。其余部分（Drift 表、CRUD 服务、UI 页面）都可复用项目已有模式，无技术瓶颈。

---

## 13. 图床图片压缩

**现状**

- 图片上传流程：`image_picker` 获取图片字节 → `ImageHostService.upload(bytes, filename)` 直接上传
- 没有压缩环节，大图直接上传会消耗更多存储空间和带宽
- `ImageUploader` 接口只接收 `Uint8List bytes` 和 `String filename`，无压缩参数

**方案**

### 设置项

在 `Settings` 模型中新增：
- `imageCompressEnabled` — 是否启用图片压缩（`bool`，默认 `false`）
- `imageCompressTargetKB` — 压缩目标大小（`int`，单位 KB，可选值：256 / 512 / 1024 / 2048 / 不限）

设置页"图床"tab 中添加：
- 压缩开关（`SwitchListTile`）
- 压缩程度下拉选择（启用后显示）

### 压缩逻辑

在 `ImageHostService` 的 `upload` 方法前增加压缩步骤：

```dart
Future<Uint8List> compressImage(Uint8List bytes, int targetKB) async {
  // 1. 使用 image 包解码
  // 2. 如果文件大小已小于 targetKB，直接返回
  // 3. 按比例缩小尺寸（宽高同比例缩放）
  // 4. 降低 JPEG 质量（从 85 逐步降到 60）
  // 5. 循环直到文件大小 ≤ targetKB 或质量降到下限
}
```

依赖：`image` 包（pub.dev 上成熟的纯 Dart 图片处理库，无原生依赖）

### 上传流程改造

```
pick image → 获取 bytes
    ↓
imageCompressEnabled == true ?
    ↓ yes
compressImage(bytes, targetKB)
    ↓
upload(bytes, filename)
```

改造点：
- `ImageHostService` 新增 `compressImage` 方法
- `upload` 方法增加可选的 `compress` 参数，或在调用前由 UI 层决定是否压缩
- 编辑器工具栏的 `_pickAndUploadImage` 和元数据页面的图片上传都走同一逻辑

### UI 反馈

- 压缩时显示 loading 指示（"压缩中..."）
- 上传完成提示中展示压缩效果（如 "2.3MB → 486KB"）

**可行性：中**

`image` 包是纯 Dart 实现，支持 JPEG/PNG 编解码和尺寸缩放，无平台依赖。压缩逻辑本身是 CPU 密集型操作，但图片通常在几 MB 以内，压缩耗时可接受。难点在于：
- 压缩循环需要平衡速度和质量（先缩尺寸再降质量）
- PNG 格式压缩效果有限，可能需要转为 JPEG
- 大图缩放时内存占用需要注意

---

## 14. 应用内日志查看

**现状**

- `LogService` 已存在，负责记录应用运行日志
- 日志目前只能通过控制台或文件查看，没有应用内查看入口
- 用户遇到问题时难以自行获取日志信息，不利于反馈和调试

**方案**

### 日志存储

- `LogService` 已有日志记录能力，需确认存储方式（内存列表 / 文件持久化）
- 如未持久化，需增加文件写入：使用 `path_provider` 获取应用目录，写入 `logs/app.log`
- 日志文件轮转：单文件上限 2MB，超过后重命名为 `app.log.1`，最多保留 3 个历史文件

### 日志等级

支持按等级过滤：
- `debug` — 调试信息（默认不显示）
- `info` — 常规操作记录
- `warn` — 警告
- `error` — 错误

### UI 设计

**入口：**
- 设置页"通用"tab 添加"查看日志"按钮
- 点击进入 `LogViewerPage`

**日志查看页（`LogViewerPage`）：**
- 顶部筛选栏：等级 chip（全部 / Info / Warn / Error）
- 日志列表：每条显示时间戳 + 等级标签 + 内容
  - `error` 等级红色高亮
  - `warn` 等级橙色高亮
- 底部操作栏：
  - 刷新按钮（重新读取日志文件）
  - 清空按钮（清空日志文件，需确认）
  - 复制按钮（复制全部日志到剪贴板，方便粘贴反馈）
- 自动滚动到底部展示最新日志

**可行性：高**

- `LogService` 已存在，核心是增加 UI 展示层
- 文件读写使用 `dart:io`，`path_provider` 已是项目依赖
- 日志轮转是标准文件操作
- 纯 UI + 文件读取，无网络依赖，无技术难点

---

## 剩余功能实施顺序

| 优先级 | 功能 | 理由 |
|---|---|---|
| 1 | 2. 文件列表树 | 核心 API 已就绪，同步逻辑已稳定，主要是 UI 工作 |
| 2 | 3. 主题扩展 | 独立功能，不影响核心流程，提升使用体验 |
