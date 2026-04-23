# Dogbody 🐶

一只住在你桌面右下角的小狗，帮你记录工作中的 **Todo / 日志 / 日报 / 周报**。
点它一下 → 弹出一个极简输入框 → 一行搞定记录。

> macOS 13 Ventura+ · SwiftUI + AppKit · 本地 SQLite (GRDB)

---

## 特性

- 🐾 **桌面悬浮宠物**：透明窗口，始终置顶，可拖动到任意位置，跨 Space 跟随
- ✍️ **点击即记**：点宠物 → 毛玻璃输入框紧贴宠物弹出，支持简单前缀语法
  - `- 买咖啡豆` → 存为 **Todo**
  - `/ 修完了登录 bug` → 存为 **日志**（默认无前缀也是日志）
  - `#标签` → 自动解析为 tag
  - `@18:30` / `@明天10点` → 自动创建时间提醒
- 📋 **Todo 列表**：勾选完成、划删除、按状态筛选
- 📆 **时间线**：按日聚合 Todo + 日志，近 7/14/30 天切换
- 📝 **周报自动生成**：近 7 天 / 本周 / 近 30 天，一键复制 Markdown 或导出 `.md`
- ⏰ **宠物主动提醒**：
  - 每天可配置时间（默认 18:00）宠物摇铃 + 系统通知
  - 单条 Todo 带 `@时间` 会到点单独提醒
- 😀 **多种状态动画**：idle / thinking / happy / celebrate / remind / sleep
- 💾 **纯本地存储**：SQLite，数据在 `~/Library/Application Support/Dogbody/dogbody.sqlite`，不上传任何东西

---

## 快速开始

### 1. 前置依赖

- macOS 13+
- Xcode 15+（命令行工具够用 SwiftUI 预览也可以）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（用于从 `project.yml` 生成 xcodeproj）

```bash
brew install xcodegen
```

### 2. 生成 Xcode 工程并运行

```bash
cd dogbody
xcodegen generate     # 根据 project.yml 生成 Dogbody.xcodeproj
open Dogbody.xcodeproj
```

在 Xcode 里点 ▶️ Run 即可。首次构建会从 SPM 拉取 [GRDB.swift](https://github.com/groue/GRDB.swift)。

### 3. 首次使用

1. 启动后，Dock 里**不会**有图标（`LSUIElement = true`），只在菜单栏有一个 🐾 小图标作为入口
2. 宠物默认出现在主屏幕右下角，拖动即可搬家，位置会被记住
3. 系统弹出"通知权限"对话框时请允许，否则提醒功能无法工作

---

## 输入语法速查

| 输入 | 效果 |
|---|---|
| `- 买咖啡豆` | 创建一个 Todo |
| `- 周会分享 @明天10点` | Todo + 明天 10:00 到点提醒 |
| `- 写 PRD @18:30 #产品` | Todo + 今晚 18:30 提醒 + tag `产品` |
| `/ 修完了登录 bug` | 日志条目 |
| `开了个跨部门对齐会 #会议` | 日志条目（默认无前缀） |

`@时间` 目前支持：`@HH`、`@HH:MM`、`@今天HH:MM`、`@明天HH:MM`、`@today`、`@tomorrow`。

---

## 目录结构

```
Dogbody/
├── App/              @main 入口与 AppDelegate
├── Pet/              透明宠物窗、状态机、帧动画
├── Input/            QuickInput 面板与输入解析
├── Features/
│   ├── Todo/         Todo 列表
│   ├── Timeline/     时间线
│   ├── Weekly/       周报生成与导出
│   ├── Reminder/     提醒调度与通知
│   └── Settings/     设置面板
├── Storage/          GRDB 封装与模型
├── MenuBar/          菜单栏入口
├── Resources/        (预留给 PetSprites 帧动画素材)
└── Assets.xcassets
```

---

## 未来可扩展

- [ ] 换 Live2D / Rive 精致版宠物皮肤
- [ ] 全局快捷键唤起 QuickInput（现在只能点宠物）
- [ ] 导出到飞书 / Notion / 企业微信
- [ ] iCloud 同步
- [ ] 自然语言解析升级（"下周三三点"、"后天晚上"）
- [ ] 宠物在屏幕上随机散步

数据 schema 已经为这些扩展预留了 `tags`、`priority`、`repeatRule` 等字段。

---

## 排错

**宠物不见了？**
菜单栏 🐾 → "显示 / 隐藏宠物"，或按 `⌘⇧P`。

**通知没响？**
系统设置 → 通知 → Dogbody，确认 "允许通知" 已开启。

**想清空所有数据？**
菜单栏 🐾 → 设置 → "在 Finder 中打开"，删掉 `dogbody.sqlite`，重启 App。

---

## 协议

MIT
