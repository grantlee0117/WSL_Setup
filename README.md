# Windows + WSL2 开发环境配置指南

从零开始，在 Windows 11 上搭建一套完整的 WSL2 开发环境（含可选的终端美化与 STM32 嵌入式开发）。

面向有一定基础的开发者，但即使你是第一次接触 Linux 命令行，跟着文档一步步来也能完成。

## 目录（按域划分，前缀数字代表推荐顺序）

| 域 | 内容 | 预估耗时 |
|------|------|:---:|
| [1-windows](./1-windows/README.md) | Windows 侧：纯净系统 / OOBE、显示器、显卡、基础软件、Git、SSH、Deskflow | 30–60 分钟 |
| [2-network](./2-network/README.md) | 代理 / 网络 / DNS：Windows 侧代理、WSL 侧代理与 DNS、网络自检、故障排查 | 视情况 |
| [3-wsl](./3-wsl/README.md) | WSL2 安装与配置、开发工具链（Python/Node/Java/Rust/Go）、Claude Code、Docker | 60–90 分钟 |
| [4-terminal](./4-terminal/README.md) | 终端环境（可选）：WezTerm + tmux + Nerd Font 主题化、一键分屏 | 15–30 分钟 |
| [5-embedded](./5-embedded/README.md) | STM32 嵌入式开发（可选）：交叉编译工具链、CubeMX、烧录链路 | 30–60 分钟 |

## 推荐流程

代理 / 网络配置横跨 Windows 与 WSL 两个阶段，所以阅读顺序不是严格"一个域读完再读下一个"，而是按下面的主线走、遇到网络步骤就跳到 `2-network` 的对应部分：

```
1-windows                       装好 Windows 基础（含代理软件的「安装」）
   │
   └─►（需要代理时）2-network · 一    按需配好 Windows 侧代理 / 订阅
   ▼
3-wsl §一~§二                   装 WSL2、配 wsl.conf
   │
   └─►2-network · 二/三/四          配 WSL 侧代理与 DNS、网络自检、排错
   ▼
3-wsl §三~                      开发工具链、Claude Code、Docker
   │
   └─►（想美化终端）4-terminal       WezTerm + tmux 主题化（可选）
   ▼
（可选）5-embedded              STM32 嵌入式开发
```

一句话：**`1-windows` → `3-wsl` 是主线**，凡是代理 / 网络 / DNS 相关的步骤都去 **`2-network`** 查；终端美化（`4-terminal`）和嵌入式（`5-embedded`）是可选支线。每个子目录的 `README.md` 顶部都标了「前置依赖」。

## 配置完成后你会得到

- 纯净的 Windows 11 系统 + Chrome、VSCode、Git、SSH Key
- WSL2 Ubuntu 24.04，网络和代理已配通
- Python、Node.js、Java、Rust、Go 开发环境
- Claude Code、Codex CLI、Gemini CLI
- Docker Engine
- Claude Code skill 所需的全部底层依赖（LibreOffice、TeX Live、poppler 等）
- 统一主题化的终端（WezTerm + tmux，可选）
- （可选）STM32 嵌入式开发环境：ARM GCC、CMake、OpenOCD、CubeMX
