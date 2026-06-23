# 网络与代理

网络代理相关的所有东西：桌面/移动端代理软件的配置、文档、安装包，外加 WSL 怎么接入网络。

## 目录结构

```
2-network/
├── wsl-network.md       # WSL 接入网络：apt 代理、环境变量、DNS、自检、排错
├── desktop/             # 桌面端
│   ├── amnezia/         # 当前主力，Amnezia VPN，全局 TUN
│   └── clash/           # Clash Verge，已弃用留作备用：config / docs / releases
├── mobile/              # 移动端
│   ├── ios/             # iPhone 配置、链式代理、美区 Apple ID 教程
│   └── android/         # NekoBox
└── blogger-scripts/     # 博主分享的 Clash / mihomo 扩展脚本（防 DNS 泄露）
```

## 说明

- 桌面端现在用 Amnezia 开全局 TUN，Clash 基本不用了，配置和文档还留在 `desktop/clash/` 备用。
- 全局 TUN 下 WSL 直连 GitHub 就行：镜像模式和 Windows 共用一套网络栈，TUN 在网络层兜底，不用再给 SSH 配 ProxyCommand（原来指向 Clash `127.0.0.1:7897` 的那条已经在 `~/.ssh/config` 注释掉）。
- 梯子装好之后，WSL 侧怎么接（apt 代理、环境变量、DNS、排错）和用哪个梯子无关，单独写在 [wsl-network.md](./wsl-network.md)。
- 安装包基本都入库了；只有超过 GitHub 单文件 100MB 上限的（Amnezia、Clash 的 WebView2 修复版）没进 git，对应目录的 README 里有下载地址。
