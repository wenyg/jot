# Jot

一只住在桌面角落的极简剪影小生物, 想到什么点它一下就记下来.
TODO / 日志 / 提醒 / 周报, 一个输入框搞定.

> macOS 13+ · SwiftUI + AppKit · 本地 SQLite (GRDB)

---

## 设计取向 (v0.2 "Jot" 重设计)

这一版的想法来自一个简单问题: **如果乔布斯做这个, 他会怎么做?**

答案是: **做减法, 不做加法.**

| | v0.1 Dogbody | v0.2 Jot |
|---|---|---|
| 窗口 | 4 个 (Todo / Timeline / Weekly / Settings) | 1 个 (时间流) |
| 输入语法 | 前缀 `-` `/` `[]` `+` | 无语法, 直接写 |
| 分类方式 | 你告诉程序 | 程序猜, 猜错按 Tab 翻转 |
| 18 点提醒 | 系统通知 (默认开) | 宠物走到屏幕中间等你 (系统通知默认关) |
| 周报 | Markdown 文本 | 海报图片 (可分享) |
| 宠物 | emoji 🐶 | AI 生成的极简剪影 |

核心信念:
1. **写的时候别想**. 分类留给计算机, 猜错再按 Tab 改.
2. **看的时候别翻**. 所有东西一条时间流里.
3. **提醒要温柔**. 小动物走到你面前, 不要弹窗打断你.
4. **周报要能分享**. 是一张图, 不是一段文本.

---

## 快速开始

### 编译

需要 Xcode 15+ 和 [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open Dogbody.xcodeproj
# Cmd+R
```

或直接命令行构建:

```bash
xcodegen generate && xcodebuild -project Dogbody.xcodeproj -scheme Dogbody -configuration Debug
```

### 使用

- **记一笔**: 点桌面上的小宠物 → 输入框弹出 → 写 → 回车
- **切换分类**: 输入时按 `Tab` 在 TODO / 日志 之间翻转
- **标签**: 文本里带 `#项目名` 自动解析为 tag
- **定时提醒**: 文本里带 `@明天10点` / `@18:30` 自动创建到时提醒
- **打开时间流**: 菜单栏小爪子 → "打开 Jot", 或 `⌘⇧J`
- **导出海报**: 时间流右上角 → "导出为海报" → 复制到剪贴板
- **移动宠物**: 按住宠物拖到任意位置, 会记住
- **隐藏宠物**: 菜单栏 → "显示 / 隐藏宠物", 或 `⌘⇧P`

### 启发式分类规则

不再有前缀语法. 程序会看关键词猜:
- 有 "要 / 记得 / 需要 / 提醒 / 明天 / 下周" 之类 → **TODO**
- 有 "了 / 完成了 / 做了 / 感受 / 发现" 之类 → **日志**
- 猜不准时默认为**日志** (保守策略)
- 带 `@时间` 时强烈倾向 TODO

随便写, 错了按 Tab 翻就行.

---

## 目录结构

```
Dogbody/
├── App/                 启动入口 + AppDelegate
├── Pet/                 宠物窗口 / 动画器 / 视图 (单图 + SwiftUI 变换)
├── Input/               QuickInput 面板 + 启发式分类器
├── Features/
│   ├── River/           时间流统一视图 (替代原 Todo/Timeline/Weekly)
│   ├── Weekly/          周报海报 (ImageRenderer 导出 PNG)
│   ├── Reminder/        系统通知 + 到时调度
│   └── Settings/        设置
├── Storage/             GRDB 模型 + 数据库迁移
├── MenuBar/             菜单栏入口
└── Assets.xcassets/
    └── pet.imageset     AI 生成的极简剪影 PNG
```

---

## 数据位置

`~/Library/Application Support/Dogbody/dogbody.sqlite`

设置 → 关于 → "在 Finder 中打开" 可以直接打开目录. 纯本地, 不上传.

---

## 下一步可能会做

- 宠物真走路 (分帧位移 + 侧身精灵)
- 自然语言时间扩展: "周五下午 3 点"
- 每日收工总结: 宠物睡前告诉你今天完成了几件事
- 多宠物皮肤包
