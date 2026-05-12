# Inkflow - Flutter 博客发布工具

## 项目概述
Flutter 项目，用于开发一个博客发布工具（类似 Hexo 客户端）。

核心功能：
1. 查看编辑 Markdown
2. 上传图片到图床（可扩展）
3. 使用 GitHub API 发布文章

## 文档导航

详细文档位于 `docs/` 目录：

- [UI 设计指南](docs/ui-design-guide.md) - 产品定位、页面设计、UI 风格
- [开发规则](docs/development-rules.md) - 项目结构、代码规范、强制规则
- [UI/UX PRO MAX](docs/ui-ux-pro-max.md) - 高端 UI 设计原则

## 快速参考

### 项目结构
```
lib/
├── services/    # 网络请求封装
├── pages/       # 页面组件
└── models/      # 数据模型
```

### 核心原则
- 每次只实现一个功能
- UI 和逻辑分离
- 不要过度设计
- 只能修改 lib/ 目录

### 禁止事项
- 禁止修改 android / ios / web / windows 等目录
- 禁止修改 Gradle / Android 构建文件
- 禁止进行项目级重构
