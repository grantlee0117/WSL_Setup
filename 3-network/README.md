# 网络与代理

网络代理相关的所有东西：桌面/移动端代理软件的配置、文档、安装包，外加 WSL 怎么接入网络。

## 目录结构

```
3-network/
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

代价是延迟与上行带宽。隧道出口在 AWS 东京，到 GitHub 的 RTT 稳定在约 60 ms、丢包接近 0%，隧道 MTU 为 1320。

吞吐随时段波动，下面是 2026-06 分时段多轮实测的范围（测量落点不同、结果差异很大，故标注路径）：

- 下行（到 GitHub 全程）：约 3–9 MB/s，多数在 5–6。
- 上行（到 GitHub，真实 git push 实测）：传输阶段约 1.4–3.4 MiB/s；一次约 10 MB 的 push 计入握手与压缩开销后，有效速率约 0.9–1.5 MB/s。
- 参照（仅测「本机→东京」接入段，落点为 Cloudflare 东京边缘，与 AWS 出口同城）：下行约 16 MB/s 很稳、上行约 1.5–4.6 MB/s——可见本机接入侧不是瓶颈，限制来自隧道本身与上下行的天然不对称。

结论：下行快于上行（约 2–4×）。常规改动推送为秒级；上传较大的新增内容（git push 的 pack 走上行）受上行速率制约会变慢，且单次 push 还要摊握手/压缩开销——这是隧道特性，非 git 或网络故障。

