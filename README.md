# Windows + WSL2 开发环境配置指南

从零开始，在 Windows 11 上搭建一套完整的 WSL2 开发环境（含可选的终端美化与 STM32 嵌入式开发）。

面向有一定基础的开发者，但即使你是第一次接触 Linux 命令行，跟着文档一步步来也能完成。

## 目录（按域划分，前缀数字代表推荐顺序）

| 域 | 内容 | 预估耗时 |
|------|------|:---:|
| [1-windows](./1-windows/README.md) | Windows 侧：纯净系统 / OOBE、显示器、显卡、基础软件、Git、SSH、Deskflow | 30–60 分钟 |
| [2-wsl](./2-wsl/README.md) | WSL2 安装与配置：`wsl.conf`、systemd、DNS / 网络基础 | 15–30 分钟 |
| [3-network](./3-network/README.md) | 代理 / 网络 / DNS：Windows 侧代理、WSL 侧代理与 DNS、网络自检、故障排查 | 视情况 |
| [4-dev](./4-dev/README.md) | 开发环境：编程语言（Python/Node/Java/Rust/Go/C++）、Claude Code、Codex/Gemini CLI、Docker、数据库客户端、性能分析、安全门禁、云原生（k8s/IaC）、可选 GPU/CUDA，以及 Claude Code skill 所需底层依赖 | 70–110 分钟 |
| [5-terminal](./5-terminal/README.md) | 终端环境（可选）：WezTerm + tmux + Nerd Font 主题化、一键分屏 | 15–30 分钟 |
| [6-embedded](./6-embedded/README.md) | STM32 嵌入式开发（可选）：交叉编译工具链、CubeMX、烧录链路 | 30–60 分钟 |

## 推荐流程

代理 / 网络配置横跨 Windows 与 WSL 两个阶段，所以阅读顺序不是严格"一个域读完再读下一个"，而是按下面的主线走、遇到网络步骤就跳到 `3-network` 的对应部分：

```
1-windows                   装好 Windows 基础（含代理软件的「安装」）
   │
   └─►（需要代理时）3-network     按需配好 Windows 侧代理 / 订阅
   ▼
2-wsl                       装 WSL2、配 wsl.conf / systemd / DNS
   │
   └─►（DNS / 代理有问题时）3-network   配 WSL 侧代理与 DNS、网络自检、排错
   ▼
4-dev                       开发工具链、Claude Code、Codex / Gemini、Docker
   │
   └─►（想美化终端）5-terminal     WezTerm + tmux 主题化（可选）
   ▼
（可选）6-embedded          STM32 嵌入式开发
```

一句话：**`1-windows` → `2-wsl` → `4-dev` 是主线**，凡是代理 / 网络 / DNS 相关的步骤都去 **`3-network`** 查；终端美化（`5-terminal`）和嵌入式（`6-embedded`）是可选支线。主线与可选域（`2-wsl`/`4-dev`/`5-terminal`/`6-embedded`）的 README 顶部都标了「前置依赖」；`3-network` 是按需查阅的横切域，无强制前置。

## 配置完成后你会得到

- 纯净的 Windows 11 系统 + Chrome、VSCode、Git、SSH Key
- WSL2 Ubuntu 24.04，网络和代理已配通
- Python、Node.js、Java、Rust、Go、C/C++ 开发环境
- Claude Code、Codex CLI、Gemini CLI
- Docker Engine
- 数据库客户端（psql/mysql/redis-cli）、本地 HTTPS（mkcert）、direnv 等本地开发辅助
- 性能分析（perf/hyperfine/heaptrack/mold）与安全质量门禁（shellcheck/gitleaks/pre-commit）
- 云原生工具链（kubectl/helm/kustomize/kind、OpenTofu、Ansible，可选）
- （可选）NVIDIA GPU / CUDA（WSL2）开发支持
- Claude Code skill 所需的全部底层依赖（LibreOffice、TeX Live、poppler 等）
- 统一主题化的终端（WezTerm + tmux，可选）
- （可选）STM32 嵌入式开发环境：ARM GCC、CMake、OpenOCD、CubeMX
