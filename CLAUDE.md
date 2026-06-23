# CLAUDE.md

本文件为 Claude Code（claude.ai/code）在本仓库中工作时提供指引。

## 仓库用途

本仓库是一个**纯文档仓库**——没有源代码、构建系统或测试。内容为从零搭建完整 Windows 11 + WSL2 开发环境的分步教程（中文编写），附带代理/VPN 配置文件及安装包。

## 目录结构

按"域"分目录，目录前缀数字代表推荐阅读顺序，目录内的 `README.md` 即该域正文：

- `1-windows/` — Windows 侧：纯净系统/OOBE、显示/GPU、基础软件、Git、SSH、Deskflow
- `2-network/` — 网络/代理/DNS；`梯子配置/` 为 Clash Verge 配置、脚本、GeoIP、安装包
- `3-wsl/` — WSL2 安装与配置、开发工具链（Python/Node/Java/Rust/Go）、Claude Code、Docker；`scripts/` 含 fuck-zone 等辅助脚本
- `4-terminal/` — 终端环境（WezTerm + tmux + Nerd Font）：tmux.conf / wezterm.lua / ta / setup.sh / cheatsheet.md
- `5-embedded/` — STM32 嵌入式开发：交叉编译工具链、CubeMX、烧录链路
- `README.md` — 顶层总索引

## 写作规范

- 所有文档使用**简体中文**编写
- 每个代码块标注执行方式图标：
  - `📋` — 整块一次性复制粘贴执行
  - `✂️` — 逐条执行（步骤间环境会发生变化）
  - `📝` — 粘贴到编辑器的内容，非终端命令
- 软件包安装风险等级使用彩色标记：🟢（安全）、🟡（低风险）、🟠（需注意）
- 大量使用表格进行配置说明、验证清单和对比展示

## 关键技术细节

- WSL2 网络使用**镜像模式**（`.wslconfig` 中配置 `networkingMode=mirrored`），使 WSL 与 Windows 宿主机共享网络栈和代理
- DNS 通过 `/etc/wsl.conf` 中的 `[boot] command=` 管理——每次 WSL 启动时强制删除 resolv.conf 软链并写入公共 DNS（223.5.5.5、8.8.8.8）
- 代理在多个层级配置：apt 代理配置、`~/.bashrc` 环境变量、可选的 SSH ProxyCommand，以及 Windows 侧 Clash TUN 模式作为兜底
- 全文引用的默认 Clash 代理端口为 **7897**

## 编辑指引

- 编辑教程时，保留执行方式图标（📋/✂️/📝）和风险等级标记（🟢/🟡/🟠）
- 保持推荐阅读顺序：1-windows → 2-network → 3-wsl → 4-terminal →（可选）5-embedded
- `.gitignore` 已排除 `2-network/梯子配置/梯子配置/LapTop/软件安装包/win/WebView2_Bundled/`
