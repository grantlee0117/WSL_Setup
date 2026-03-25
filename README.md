# Windows + WSL2 开发环境配置指南

从零开始，在 Windows 11 上搭建一套完整的 WSL2 开发环境。

面向有一定基础的开发者，但即使你是第一次接触 Linux 命令行，跟着文档一步步来也能完成。

## 文档

| 文档 | 内容 | 预估耗时 |
|------|------|:---:|
| [01-windows-setup.md](./01-windows-setup.md) | Windows 侧配置：纯净系统、显示器、显卡、基础软件安装 | 30-60 分钟 |
| [02-wsl2-setup.md](./02-wsl2-setup.md) | WSL2 安装配置：网络代理、开发工具链、Claude Code 等 | 60-90 分钟 |
| [03-embedded-setup.md](./03-embedded-setup.md) | STM32 嵌入式开发：交叉编译工具链、CubeMX、烧录链路 | 30-60 分钟 |

按顺序阅读，先完成 01，再做 02，嵌入式开发需要再做 03。

## 配置完成后你会得到

- 纯净的 Windows 11 系统 + Chrome、VSCode、Git、SSH Key
- WSL2 Ubuntu 24.04，网络和代理已配通
- Python、Node.js、Java、Rust、Go 开发环境
- Claude Code、Codex CLI、Gemini CLI
- Docker Engine
- Claude Code skill 所需的全部底层依赖（LibreOffice、TeX Live、poppler 等）
- （可选）STM32 嵌入式开发环境：ARM GCC、CMake、OpenOCD、CubeMX
