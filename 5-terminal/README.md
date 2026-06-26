# 终端环境配置（WezTerm + tmux + zsh + starship）

> **适用场景**：把 WSL 终端配成统一的 **Catppuccin Mocha** 深色主题 + Nerd Font 图标 + starship 提示符 + tmux 会话保存/恢复 + 一键分屏布局（含 Agent Team 布局），把日常交互 shell 换成 **zsh + oh-my-zsh**（灰字补全 / 命令高亮），并把 [4-dev](../4-dev/README.md) §1.7 装的现代 CLI 工具（zoxide / fzf / eza / bat）真正接进 shell。脚本不受影响——本仓脚本都带 bash shebang，照旧走 bash。
>
> **前置条件**：先完成 [2-wsl](../2-wsl/README.md) 的 WSL2 安装，并在 [4-dev](../4-dev/README.md) §1.7 装好 tmux 及 CLI 工具（zoxide/fzf/eza/bat——shell 层会接它们；缺了也不报错，只是少接几样）。
>
> 这一步是**可选**的美化和效率提升，不影响任何开发工具的功能。但配置后体验会好很多——统一主题、Nerd Font 图标、tmux 会话保存/恢复、一键分屏布局。

**代码块标记**（同 [2-wsl](../2-wsl/README.md) / [4-dev](../4-dev/README.md)）：📋 整块复制粘贴执行 · ✂️ 逐条执行（前一条会改环境、后续依赖它）· 📝 贴进编辑器的文件内容。

本目录（`5-terminal/`）按「配置 / 脚本」分层，配置再按**角色**（而非具体工具）归类：

```
5-terminal/
├── README.md                  本文档
├── cheatsheet.md              快捷键 / 命令速查卡
├── config/                    配置（被各工具读取的静态文件，按角色归类）
│   ├── terminal-emulator/     终端模拟器
│   │   └── wezterm.lua        Catppuccin Mocha 主题、Nerd Font、默认启动 WSL、GPU 加速、快捷键
│   ├── multiplexer/           复用器
│   │   └── tmux.conf          Vim 风格 pane 切换、Catppuccin 状态栏、Agent Team 布局、会话保存/恢复
│   └── shell/                 shell
│       ├── shell.bash         把 4-dev §1.7 的 zoxide/fzf/eza/bat 接进 bash + 大历史/多 pane 共享
│       ├── shell.zsh          同上的 zsh 版（接线对称）+ zsh 专属灰字补全/命令高亮
│       ├── zshrc              ~/.zshrc 模板：oh-my-zsh 引导（内置插件）→ 末尾 source shell.zsh
│       └── starship.toml      starship 提示符（Catppuccin Mocha：git 分支状态、语言版本、命令耗时）
└── scripts/                   脚本（你来跑的可执行文件）
    ├── setup.sh               一键部署：上述配置 + Nerd Font + TPM 插件 + starship/win32yank + 接好 shell 层
    └── ta                     tmux 快捷命令：创建/连接/关闭会话，自动分屏
```

> 类目用**角色名**（terminal-emulator / multiplexer / shell）而非工具名（wezterm / tmux），因为 tmux 只是复用器的一种实现——换成 zellij/screen 时目录语义不变。文件名仍带工具名，因为它就是那个工具的配置。

**前提**：Windows 侧已安装 WezTerm。如果还没装，在 PowerShell 中 📋 执行：

```powershell
winget install wez.wezterm --source winget
```

**部署配置**（在 WSL 中执行）：

✂️ 逐条执行：

```bash
cd ~/projects/WSL_Setup/5-terminal
chmod +x scripts/setup.sh
```

```bash
./scripts/setup.sh
```

脚本会自动完成：
1. 下载 JetBrainsMono Nerd Font 到 Windows 字体目录
2. 部署 `tmux.conf` 到 `~/.tmux.conf`
3. 安装 TPM（tmux 插件管理器），并自动装好 4 个 tmux 插件（tpm / sensible / resurrect / continuum）
4. 部署 `wezterm.lua` 到 Windows 用户目录 `~/.wezterm.lua`（原有配置自动备份为 `.bak`）
5. 安装 `ta` 快捷命令到 `~/.local/bin/`
6. 安装 `win32yank` 到 `/usr/local/bin/`（tmux 复制绑定依赖它，修复中文乱码）
7. 安装 `starship`，部署 `shell.bash` → `~/.config/wsl-setup/`、`starship.toml` → `~/.config/`，并在 `~/.bashrc` 末尾接好 shell 层
8. 安装 `zsh` + `oh-my-zsh`（含 autosuggestions / syntax-highlighting 两个外部插件），部署 `shell.zsh` → `~/.config/wsl-setup/`、`zshrc` → `~/.zshrc`，并把默认登录 shell 切到 zsh（原有 `~/.zshrc` 备份为 `.bak`）

**部署后还需要**：

1. **安装字体**：在 Windows 资源管理器地址栏输入 `C:\Users\你的用户名\AppData\Local\Microsoft\Windows\Fonts`，全选所有 `.ttf` 文件 → 右键 → **为所有用户安装**

2. **关闭并重新打开 WezTerm**：重启后自动进入 WSL Ubuntu，且默认 shell 已是 **zsh**——直接就有灰字补全（按 `→` 接受）、命令绿/红高亮、starship 提示符、`z` 跳目录、`Ctrl+R` 模糊搜历史、`ll`/`eza` 别名（详见下方「shell 层做了什么 / zsh 层做了什么」）。

   > 想在重开终端前先于当前 bash 会话试一下，可 📋 执行 `source ~/.bashrc`（只对当前 bash 窗口生效；zsh 那套要重开终端才进）。
   > 脚本不受影响：`./xxx.sh`、`bash xxx.sh` 由 shebang 决定解释器，与登录 shell 无关，照旧走 bash。

3. **（一般不用做）补装 tmux 插件**：插件已由 `setup.sh` 自动安装；只有脚本结尾提示「插件自动安装失败」时，才需要手动补装——方法见下方 ⚠️ 框。

> **win32yank 已自动装**：tmux 复制中文用的 `win32yank` 由 `setup.sh` 自动装好（WSL 默认 `clip.exe` 不支持 UTF-8，复制中文会乱码）。若脚本提示「win32yank 下载失败」，再手动补装：
>
> ```bash
> curl -fsSL -o /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
> unzip -o /tmp/win32yank.zip -d /tmp/win32yank
> sudo cp /tmp/win32yank/win32yank.exe /usr/local/bin/
> ```

> ⚠️ **若插件没装全（只装上 `tpm` 自身或一个插件）**
> 交互式快捷键 `Ctrl+A` 然后大写 `I` 依赖 TPM 被正确加载，有时只会装上 `tpm` 自身（或第一个插件），其余的 `tmux-sensible`、`tmux-resurrect`、`tmux-continuum` 不会被装上。**最可靠的做法是直接用命令行安装**，📋 在 WSL 终端（不必进 tmux）执行：
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

> 应创建一个名为 `test` 的 tmux 会话并自动连接。`Ctrl+A` 然后按 `d` 退出，`ta kill test` 关闭会话。

**shell 层做了什么**（`source ~/.bashrc` 后生效）：

4-dev §1.7 把 zoxide / fzf / eza / bat 装进了系统，但 Ubuntu 出厂的 bash 不会自动接它们——装了等于不用。`shell.bash` 补上这层胶水：

- **starship 提示符**：显示当前目录、git 分支与状态、项目语言版本、命令耗时，配色与 WezTerm/tmux 同为 Catppuccin Mocha。
- **zoxide**：`z 关键字` 按访问频率跳到最常去的目录，不用再敲长路径。
- **fzf 键位**：`Ctrl+R` 模糊搜命令历史、`Ctrl+T` 选文件、`Alt+C` 跳子目录（Ubuntu 的 fzf 默认不挂键位，这里显式接上）。
- **现代别名**：`ls`/`ll`/`la`/`lt` 走 eza（图标、git 状态、树形），`bat` = 带高亮的 cat，`fd` = 更快的 find。
- **历史**：放大到 10 万条，并在多个 tmux pane / 终端间实时共享（一个 pane 敲的命令，另一个按 `↑` 就能翻到）。

**zsh 层做了什么**（重开终端后默认就进 zsh）：

日常交互换成 zsh + oh-my-zsh。`shell.zsh` 和上面的 `shell.bash` **责任对称**——zoxide / fzf / 现代别名 / starship 提示符 / 大历史一样不少（zsh 语法版），所以 bash、zsh 两边体验一致、提示符同款。oh-my-zsh 只额外加挂它的内置插件，外加两个 zsh 才有的增强：

- **灰字补全（autosuggestions）**：边敲边按历史给灰色建议，按 `→` 或 `End` 整条接受、`Alt+F` 接受一个词。
- **命令高亮（syntax-highlighting）**：命令合法显绿、拼错显红，回车前就看出问题。
- **oh-my-zsh 内置插件**：`git`（海量 git 别名/补全）、`sudo`（连按两下 `Esc` 给命令补 `sudo`）、`extract`（一个命令解任意压缩包）、`colored-man-pages`（man 上色）、`command-not-found`（提示该装哪个 apt 包）。
- **提示符仍是 starship**：`ZSH_THEME` 留空，prompt 交给 starship，和 bash/tmux/WezTerm 同款 Catppuccin Mocha。
- **历史**：靠 zsh 原生 `SHARE_HISTORY` 实时多 pane 共享，同样放大到 10 万条。

> **为什么脚本不受影响**：`chsh` 只换**交互式**登录 shell。脚本跑哪个解释器由它的 shebang 决定（本仓脚本均 `#!/usr/bin/env bash`），跟登录 shell 无关——`./xxx.sh`、`bash xxx.sh` 永远走 bash。所以「日常 zsh、脚本 bash」是默认效果，无需额外设置。
>
> 想退回 bash 当默认：`chsh -s $(command -v bash)` 后重开终端即可，`~/.bashrc` 与 `shell.bash` 一直原样保留。

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
