# Changelog

本文件记录项目的所有显著变更，遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 格式。

## [Unreleased]

### 修复

- **tmux 插件自动安装**（2026-06-23）：`terminal-setup/setup.sh` 在克隆 TPM 后新增调用
  `~/.tmux/plugins/tpm/bin/install_plugins` 的逻辑，确保 `tmux.conf` 声明的所有插件（tmux-sensible、
  tmux-resurrect、tmux-continuum）全部被装上，避免 `Ctrl+A I` 交互式快捷键有时只装一个插件的问题。
  `02-wsl2-setup.md` 同步补充该排错说明与命令行验证步骤。

### 移除

- **03-embedded-setup.pdf**（2026-06-23）：删除未被任何地方引用的 4.35 MB 渲染副本；
  源文件 `03-embedded-setup.md` 仍保留在仓库中。
