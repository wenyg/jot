# Jot

桌面角落一只极简剪影小生物, 点一下就记一笔. TODO / 日志 / 提醒 / 周报, 一个输入框搞定.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Platform](https://img.shields.io/badge/macOS-13%2B-lightgrey.svg)]() [![Release](https://img.shields.io/github/v/release/wenyg/jot?include_prereleases)](https://github.com/wenyg/jot/releases)

---

## 安装

到 [Releases](https://github.com/wenyg/jot/releases) 下最新的 `Jot-vX.Y.Z-macOS-universal.zip`, 解压, 把 `Jot.app` 拖进 `/Applications`.

首次打开会被 macOS 拦下 (本项目没有 Apple 开发者证书). 终端跑一行解决:

```bash
xattr -dr com.apple.quarantine /Applications/Jot.app
```

之后双击就能用. Apple Silicon / Intel Mac 都支持, 需要 macOS 13.1+.

## 用法

- **记一笔**: 点桌面小宠物 → 输入框弹出 → 写 → 回车. 程序会猜这是 TODO 还是日志, 猜错按 `Tab` 翻转.
- **打开时间流**: 菜单栏小爪子 → "打开 Jot", 或 `⌘⇧J`. 所有记录按天倒序在一条流里.
- **复制本周到周报系统**: 时间流右上角 "复制本周" (或 `⌘C`). 输出按日期分组的 Markdown, 直接粘到周报系统就能用. 周一时自动指向上周.
- **标签 / 提醒**: 文本里写 `#项目名` 自动成 tag, 写 `@明天10点` / `@18:30` 自动到时提醒.
- **隐藏宠物**: 菜单栏 → "显示 / 隐藏宠物", 或 `⌘⇧P`.

数据全部存在 `~/Library/Application Support/Jot/jot.sqlite`, 纯本地, 不上传.

## 自己构建

```bash
brew install xcodegen
git clone https://github.com/wenyg/jot.git && cd jot
./scripts/build.sh   # 产物在 dist/
```

## License

[MIT](LICENSE) © 2026 wenyg
