<p align="center">
  <img src="web/icons/Icon-512.png" width="120" alt="InkFlow Logo">
</p>

<h1 align="center">墨流 InkFlow</h1>

<p align="center">
  一款面向 Hexo + GitHub Pages 的全平台写作客户端<br>
  支持 <b>Web</b> · <b>Linux</b> · <b>Windows</b> · <b>macOS</b> · <b>Android</b>
</p>

<p align="center">
  <a href="https://github.com/csfwff/inkflow/releases">📦 下载</a> ·
  <a href="https://inkflow.sszsj.com">🌐 Web 版</a> ·
  <a href="https://fishpi.cn">💬 反馈</a>
</p>

---

## 功能概览

- 从 GitHub 仓库同步文章（支持增量同步）
- Markdown 编辑、元数据管理、自定义字段
- 本地草稿 / 仓库草稿 / 正式发布 三种保存方式
- 图床支持 GitHub 图床 & 又拍云
- 自定义主题色、多语言（中/英）
- 检查更新、应用内反馈

## ⚠️ 前置条件

> **本应用不负责搭建 Hexo 以及配置自动部署！！！**

使用前请确保你已经：

1. 拥有 GitHub 账号
2. 创建了 Hexo 仓库，且配置好了自动部署
3. GitHub Pages 站点能正常访问

如果你还没有搭建 Hexo，可以参考以下教程：

- [Hexo 博客搭建教程（一）——搭建篇](https://fishpi.cn/article/1781253951404)
- [使用 hexo 框架在 github.io 上搭建博客网站](https://cooooing.github.io/%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0/%E4%BD%BF%E7%94%A8hexo%E6%A1%86%E6%9E%B6%E5%9C%A8github-io%E4%B8%8A%E6%90%AD%E5%BB%BA%E5%8D%9A%E5%AE%A2%E7%BD%91%E7%AB%99/)

关于自动部署，你可以直接跟 AI 说：

```
帮我写一个 github action 的 workflow，自动部署 hexo 到 github pages
```

## 📖 使用教程

### 1. 配置 GitHub

进入 **设置 → GitHub** 页签，依次填入以下信息：

**获取 Token：**

1. 访问 [GitHub Personal Access Tokens](https://github.com/settings/personal-access-tokens)
2. 点击 `Fine-grained personal access tokens` → `Generate new token`
3. 按如下配置：
   - **Token name**：随意填，例如 `inkflow`
   - **Resource owner**：选你自己
   - **Expiration**：`No expiration`
   - **Repository access**：`Only select repositories`，勾选你的 Hexo 仓库（如需 GitHub 图床，一并勾选图床仓库）
   - **Permissions**：添加 `Contents: Read and write`（`Metadata` 会自动附带）
4. 点击 `Generate token`，**立即复制保存**，之后无法再查看

**填写配置：**

- **Token**：粘贴上面获取的 Token
- **Owner**：你的 GitHub 用户名
- **仓库**：点击刷新按钮加载列表，选择 Hexo 仓库（也可手动输入）
- **分支**：选择仓库后自动加载
- **文章目录格式**：按需配置

### 2. 配置图床

#### GitHub 图床

选择图床类型为 **GitHub**，填入图片仓库名、存储路径和自定义域名。

#### 又拍云

选择图床类型为 **又拍云**，填入以下信息：

| 字段 | 来源 |
|---|---|
| 空间名称 | 又拍云控制台创建的空间 |
| 操作员 / 密码 | [又拍云操作员管理](https://console.upyun.com/account/operators/) |
| 域名 | 空间绑定的域名 |

### 3. 同步文章

回到首页，点击右上角同步按钮：

- **首次同步**：文章较多时耗时较长，请耐心等待
- **后续同步**：使用增量同步，速度更快
- 同步完成后将展示文章列表

### 4. 编辑文章

点击文章或点击 `+` 新增文章，进入编辑器。右上角四个按钮：

| 按钮 | 说明 |
|---|---|
| 📋 元数据 | 编辑标签、分类、封面图等，支持自定义字段 |
| 💾 本地草稿 | 仅保存到本地，不推送远程 |
| 📤 仓库草稿 | 推送至仓库 `drafts` 目录 |
| 🚀 正式发布 | 推送至仓库 `posts` 目录 |

## 📦 下载

**桌面端 & 移动端：** [GitHub Releases](https://github.com/csfwff/inkflow/releases)

**Web 版（免安装）：** [https://inkflow.sszsj.com](https://inkflow.sszsj.com)

> ⚠️ 目前仍在测试阶段，功能会频繁调整。
> **请务必备份远程仓库分支，防止数据丢失！**

## 💬 问题反馈

请在 [摸鱼派](https://fishpi.cn) 发帖并 **@csfwff**

新用户注册：[点击注册（邀请链接）](https://fishpi.cn/register?r=csfwff)
