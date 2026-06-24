# 网络与代理

网络代理相关的所有东西：桌面/移动端代理软件的配置、文档、安装包，外加 WSL 怎么接入网络。

## 目录结构

```
2-network/
├── wsl-network.md       # WSL 接入网络：apt 代理、环境变量、DNS、自检、排错
├── desktop/             # 桌面端
│   ├── amnezia/         # 当前主力，Amnezia VPN，整机全局接管（网络层）
│   └── clash/           # Clash Verge，已弃用留作备用：config / docs / releases
├── mobile/              # 移动端
│   ├── ios/             # iPhone 配置、链式代理、美区 Apple ID 教程
│   └── android/         # NekoBox
└── blogger-scripts/     # 博主分享的 Clash / mihomo 扩展脚本（防 DNS 泄露）
```

## 说明

- 桌面端当前使用 Amnezia（装在 Windows），Clash 已弃用，配置与文档留在 `desktop/clash/` 备用。
- WSL 侧无需任何代理配置，原理见下方「流量路径」。原先指向 Clash `127.0.0.1:7897` 的 SSH ProxyCommand 已在 `~/.ssh/config` 注释停用。
- 若改用需手动配置代理的梯子，WSL 侧的接入方式（apt 代理、环境变量、DNS、自检、排错）见 [wsl-network.md](./wsl-network.md)。
- 安装包基本入库；仅超过 GitHub 单文件 100MB 上限的（Amnezia、Clash 的 WebView2 修复版）未入库，下载地址见对应目录的 README。

## 流量路径

现代网络请求自上而下分层处理：应用层（程序传输的内容）→ 传输层（TCP/UDP，分段与端口）→ 网络层（IP 寻址与路由）→ 链路层（网卡收发）。代理工作在哪一层，决定它能接管哪些流量。

Clash/Clash Verge 的系统代理工作在应用层，需各程序自行配置，未配置的程序仍走直连，属选择性接管。而 Clash/Clash Verge 的 TUN 模式 和本机当前使用的 Amnezia 工作在网络层：它在 Windows 上创建一块虚拟网卡（TUN/L3 设备），并将系统
默认路由指向该网卡，因此整机所有 IP 流量均经此进入隧道，无需各程序单独配置。


WSL2 运行于镜像（mirrored）模式，与 Windows 共用网卡和路由表。WSL 流量出 Windows 时同样经过该网卡进入隧道，因此 WSL 侧无需代理配置。

代价是延迟与上行带宽。隧道出口在 AWS 东京，到 GitHub 的 RTT 稳定在约 60 ms、丢包接近 0%，隧道 MTU 为 1320。下行约 2–5 MB/s，上行约 0.4–0.7 MB/s，上下行明显不对称。因此常规改动推送为秒级，而上传较大的新增内容（git push 的 pack 走上行）受上行带宽制约会明显变慢——这是隧道特性，非 git 或网络故障。

