# Jot

桌面角落的极简小生物, 点一下记一笔.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE) [![Platform](https://img.shields.io/badge/macOS-13%2B-lightgrey.svg)]() [![Release](https://img.shields.io/github/v/release/wenyg/jot?include_prereleases)](https://github.com/wenyg/jot/releases)

---

## 安装

[Releases](https://github.com/wenyg/jot/releases) 下载 zip, 解压, 拖 `Jot.app` 进 `/Applications`.

首次打开会被 macOS 拦下, 终端跑一行解决:

```bash
xattr -dr com.apple.quarantine /Applications/Jot.app
```

macOS 13.1+, Apple Silicon / Intel 都支持.

## 用法

**点小宠物 → 写一笔 → 回车.**

按 `⌘⇧J` 打开时间流看历史. 周末填周报: 右上角 "复制本周" → 粘到周报系统.

数据本地存在 `~/Library/Application Support/Jot/`.

## 自己构建

```bash
brew install xcodegen
git clone https://github.com/wenyg/jot.git && cd jot
./scripts/build.sh
```

## License

[MIT](LICENSE) © 2026 wenyg
