# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **documentation-only repository** — there is no source code, build system, or tests. It contains step-by-step guides (written in Chinese) for setting up a complete Windows 11 + WSL2 development environment from scratch, plus bundled proxy/VPN configuration files and installers.

## Structure

- `01-windows-setup.md` — Windows side: clean install, display/GPU settings, Git, SSH, Chrome, VSCode, Deskflow
- `02-wsl2-setup.md` — WSL2 side: network/proxy/DNS, dev toolchains (Python, Node, Java, Rust, Go), Claude Code, Docker
- `README.md` — Table of contents linking the two guides
- `梯子配置/` — Clash Verge proxy configs, scripts, GeoIP databases, installer binaries, and iOS setup docs

## Writing Conventions

- All documentation is written in **Simplified Chinese**
- Each code block is annotated with an execution mode icon:
  - `📋` — copy-paste the whole block at once
  - `✂️` — execute commands one by one (environment changes between steps)
  - `📝` — content to paste into an editor, not a terminal command
- Risk levels for package installations use colored markers: 🟢 (safe), 🟡 (low risk), 🟠 (needs attention)
- Tables are used heavily for config explanations, verification checklists, and comparisons

## Key Technical Details

- WSL2 networking uses **mirrored mode** (`networkingMode=mirrored` in `.wslconfig`) so WSL shares the Windows host's network stack and proxy
- DNS is managed via a `[boot] command=` in `/etc/wsl.conf` that forcefully removes the resolv.conf symlink and writes public DNS servers (223.5.5.5, 8.8.8.8) on every WSL startup
- Proxy is configured at multiple layers: apt proxy config, `~/.bashrc` env vars, optional SSH ProxyCommand, and Windows-side Clash TUN mode as a catch-all
- The default Clash proxy port referenced throughout is **7897**

## Editing Guidelines

- When editing the guides, preserve the execution mode icons (📋/✂️/📝) and risk level markers (🟢/🟡/🟠)
- Keep the sequential dependency between docs: `01-windows-setup.md` must be completed before `02-wsl2-setup.md`
- The `.gitignore` excludes `梯子配置/梯子配置/LapTop/软件安装包/win/WebView2_Bundled/`
