# 终端环境配置（WezTerm + tmux + Nerd Font）

> **本域作用**：把 WSL 终端配成统一的 **Catppuccin Mocha** 深色主题 + Nerd Font 图标 + tmux 会话保存/恢复 + 一键分屏布局（含 Agent Team 布局）。
>
> **前置**：先完成 [2-wsl](../2-wsl/README.md) 的 WSL2 安装，并在 [4-dev](../4-dev/README.md) §1.7 装好 tmux。
>
> 这一步是**可选**的美化和效率提升，不影响任何开发工具的功能。但配置后体验会好很多——统一主题、Nerd Font 图标、tmux 会话保存/恢复、一键分屏布局。

本目录（`5-terminal/`）提供了完整的配置文件和一键部署脚本：

| 文件 | 作用 |
|------|------|
| `wezterm.lua` | WezTerm 配置：Catppuccin Mocha 主题、JetBrainsMono Nerd Font、默认启动 WSL、GPU 加速、快捷键 |
| `tmux.conf` | tmux 配置：Vim 风格 pane 切换、Catppuccin 状态栏、Agent Team 快捷布局、会话自动保存/恢复 |
| `ta` | tmux 快捷命令：快速创建/连接/关闭会话，自动分屏 |
| `setup.sh` | 一键部署脚本：部署上述所有配置 + 下载 Nerd Font + 安装 TPM 插件管理器 |
| `cheatsheet.md` | 快捷键速查卡 |

**前提**：Windows 侧已安装 WezTerm。如果还没装，在 PowerShell 中 📋 执行：

```powershell
winget install wez.wezterm
```

**部署配置**（在 WSL 中执行）：

✂️ 逐条执行：

```bash
cd ~/projects/WSL_Setup/5-terminal
chmod +x setup.sh
```

```bash
./setup.sh
```

脚本会自动完成：
1. 下载 JetBrainsMono Nerd Font 到 Windows 字体目录
2. 部署 `tmux.conf` 到 `~/.tmux.conf`
3. 安装 TPM（tmux 插件管理器）
4. 部署 `wezterm.lua` 到 Windows 用户目录 `~/.wezterm.lua`
5. 安装 `ta` 快捷命令到 `~/.local/bin/`

**部署后还需要**：

1. **安装字体**：在 Windows 资源管理器地址栏输入 `C:\Users\你的用户名\AppData\Local\Microsoft\Windows\Fonts`，全选所有 `.ttf` 文件 → 右键 → **为所有用户安装**

2. **安装 win32yank**（修复 tmux 复制中文乱码）：WSL 默认的 `clip.exe` 不支持 UTF-8，复制中文会乱码。📋 整块执行：

```bash
curl -fsSL -o /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
unzip -o /tmp/win32yank.zip -d /tmp/win32yank
sudo cp /tmp/win32yank/win32yank.exe /usr/local/bin/
```

3. **关闭并重新打开 WezTerm**：重启后应自动进入 WSL Ubuntu
4. **安装 tmux 插件**：进入 tmux 后按 `Ctrl+A` 然后按大写 `I`（Install），等待插件安装完成

> ⚠️ **常见问题：`Ctrl+A I` 只装上了一个插件**
> 这个交互式快捷键依赖 TPM 被正确加载，有时只会装上 `tpm` 自身（或第一个插件），其余的 `tmux-sensible`、`tmux-resurrect`、`tmux-continuum` 不会被装上。**更可靠的做法是直接用命令行安装**，📋 在 WSL 终端（不必进 tmux）执行：
>
> ```bash
> ~/.tmux/plugins/tpm/bin/install_plugins
> ```
>
> 📋 验证 4 个插件是否都已装上（应列出 `tpm`、`tmux-continuum`、`tmux-resurrect`、`tmux-sensible`）：
>
> ```bash
> ls ~/.tmux/plugins/
> ```

📋 验证：

```bash
ta test
```

> 应创建一个名为 `test` 的 tmux 会话并自动连接。`Ctrl+A` 然后按 `D` 退出，`ta kill test` 关闭会话。

**常用操作速查**：

| 操作 | 快捷键 / 命令 |
|------|--------------|
| 左右分屏 | `Ctrl+A %` |
| 上下分屏 | `Ctrl+A "` |
| Vim 风格切换 pane | `Ctrl+A h/j/k/l` |
| 后台挂起会话 | `Ctrl+A d` |
| 重新连接会话 | `ta` 或 `ta 会话名` |
| 创建带 N 个 pane 的会话 | `ta 名称 N`（如 `ta dev 3`） |
| 调整 pane 大小 | `Alt+h/j/k/l`（不需要前缀键） |
| 三格布局（1 大 + 2 小） | `Ctrl+A a` |
| 田字格布局（4 等分） | `Ctrl+A q` |
| 保存会话（重启后可恢复） | `Ctrl+A Ctrl+S` |
| 恢复会话 | `Ctrl+A Ctrl+R` |
| 关闭所有会话 | `ta kill-all` |
| 查看完整速查卡 | `ta help` 或查看 [`cheatsheet.md`](./cheatsheet.md) |

> **WezTerm 快捷键**：`Ctrl+Shift+T` 新标签页、`Ctrl+Shift+W` 关闭标签页、`Alt+1-5` 切换标签页、`Ctrl+Shift+F` 搜索、右键粘贴。
