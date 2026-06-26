# 终端环境配置（WezTerm + tmux + zsh + starship）

> **适用场景**：把 WSL 终端配成统一的 **Catppuccin Mocha** 深色主题 + Nerd Font 图标 + starship 提示符 + tmux 会话保存/恢复与一键分屏（含 Agent Team 布局），日常交互 shell 换成 **zsh + oh-my-zsh**（灰字补全 / 命令高亮），并把 [4-dev §1.7](../4-dev/README.md) 装的现代 CLI（zoxide / fzf / eza / bat）真正接进 shell。三层（终端模拟器 / 复用器 / shell）**各自独立、各带安装脚本**——可整套配，也可只配其中一层。这一步是**可选**的美化与效率提升，不影响任何开发工具的功能。
>
> **前置条件**：先完成 [2-wsl](../2-wsl/README.md) 的 WSL2 安装；[4-dev §1.7](../4-dev/README.md) 的 tmux 与 CLI 工具（zoxide / fzf / eza / bat）装好最佳——缺了也不报错，只是少接几样（tmux 真没装，复用器层的脚本会兜底装上）。

**代码块标记**（同 [2-wsl](../2-wsl/README.md) / [4-dev](../4-dev/README.md)）：📋 整块复制粘贴执行 · ✂️ 逐条执行（前一条会改环境、后续依赖它）· 📝 贴进编辑器的文件内容。

本目录（`5-terminal/`）按**角色**（而非具体工具）分成三个**自包含文件夹**，每个文件夹里放「该角色的配置 + 它自己的安装脚本」：

```
5-terminal/
├── README.md                  本文档
├── cheatsheet.md              快捷键 / 命令速查卡
├── terminal-emulator/         终端模拟器（自带安装脚本，可独立配置）
│   ├── wezterm.lua            Catppuccin Mocha 主题、Nerd Font、半透明毛玻璃、默认启动 WSL、GPU 加速、快捷键
│   └── setup.sh               下载 Nerd Font + 部署 ~/.wezterm.lua（自动填 default_domain）
├── multiplexer/               复用器（自带安装脚本，可独立配置）
│   ├── tmux.conf              Vim 风格 pane 切换、Catppuccin 状态栏、Agent Team 布局、会话保存/恢复
│   ├── ta                     tmux 快捷命令：创建/连接/关闭会话，自动分屏
│   └── setup.sh               tmux 本体兜底 + 部署 ~/.tmux.conf + TPM/插件 + ta + win32yank
└── shell/                     shell（自带安装脚本，可独立配置）
    ├── shell.bash             把 4-dev §1.7 的 zoxide/fzf/eza/bat 接进 bash + 大历史/多 pane 共享
    ├── shell.zsh              同上的 zsh 版（接线对称）+ zsh 专属灰字补全/命令高亮
    ├── zshrc                  ~/.zshrc 模板：oh-my-zsh 引导（内置插件）→ 末尾 source shell.zsh
    ├── starship.toml          starship 提示符（Catppuccin Mocha：git 分支状态、语言版本、命令耗时）
    └── setup.sh               装 zsh + oh-my-zsh + starship + 部署接线 + 切默认 shell
```

> 文件夹用**角色名**（terminal-emulator / multiplexer / shell）而非工具名，因为 tmux 只是复用器的一种实现——换成 zellij/screen 时目录语义不变；配置文件名仍带工具名，因为它就是那个工具的配置。

**三个角色，三种装法、三个落点**——下表先看全貌，再照下面三节逐个配：

| 角色 | 程序 | 装在哪 |
|------|------|--------|
| 终端模拟器 | WezTerm | Windows 侧 `winget`——三个角色里**只有它在 Windows**（见 §1） |
| 复用器 | tmux | 一般在 [4-dev §1.7](../4-dev/README.md) 用 `apt` 装；**没装则本层脚本兜底装上**（见 §2） |
| shell | zsh + oh-my-zsh + starship | 由 shell 层脚本**自动安装**（见 §3） |
| shell | zoxide / fzf / eza / bat | [4-dev §1.7](../4-dev/README.md) 装本体，本目录只把它们**接进 shell**（见 §3） |

> 为什么不全搬来这里装：tmux 和那几个 CLI 是 [4-dev](../4-dev/README.md) 的开发基础设施，纯 bash、零主题时也照用；本目录是**可选**的美化/接线层，不重复承担安装。所以「装工具」在 4-dev、「配主题/接线」在这里。

**三层互相独立**：每个角色文件夹里都自带 `setup.sh`，想配哪层就进哪层跑它的脚本；要整套就三层都跑（建议按 §1 → §2 → §3 的顺序）。**唯一的跨层依赖是 Nerd Font 图标**——由终端模拟器层（§1）下载（装字体仍需手动），shell 的 starship、tmux 的状态栏都靠它显示图标；只配 shell/tmux 不配 §1 的话，图标会显示成方框（单独补字体见 §1 的「装字体」步骤）。除此之外三层互不依赖。

下面按 **终端模拟器 → 复用器 → shell** 的顺序（由外到内：终端模拟器是窗口，tmux 跑在里面，shell 跑在 tmux 里）逐个讲清，每节都从「装在哪」讲到「配了什么」、再到「怎么验证」。

---

## 1. 终端模拟器：WezTerm

**是什么**：WezTerm 是终端模拟器——你看到的那个窗口本身（画字、管标签页、连进 WSL）。三个角色里只有它装在 **Windows 侧**，其余都在 WSL 里。

**装它**（Windows 侧 PowerShell，已装可跳过）。📋 执行：

```powershell
winget install wez.wezterm --source winget
```

**配它**（在 WSL 里跑本层脚本）。📋 执行：

```bash
cd ~/projects/WSL_Setup/5-terminal/terminal-emulator
chmod +x setup.sh && ./setup.sh
```

脚本做了什么：

1. 下载 JetBrainsMono Nerd Font 到 Windows 字体目录（**装字体还得手动**，见下一步）。
2. 部署 `wezterm.lua` → Windows 的 `~/.wezterm.lua`，按本机 `WSL_DISTRO_NAME` 自动填好 `default_domain`（原配置备份为 `.bak`）。

**装字体**：脚本只把字体**下载**到 Windows 字体目录，**安装还得手动**——在 Windows 资源管理器地址栏输入 `C:\Users\你的用户名\AppData\Local\Microsoft\Windows\Fonts`，全选所有 `.ttf` → 右键 → **为所有用户安装**。（只下载不算装上；图标显示成方框就是这步没做。）

**`wezterm.lua` 配了什么**：

- 配色 Catppuccin Mocha；字体 JetBrainsMono Nerd Font（带中文回退 Noto Sans CJK SC），字号 12。
- 半透明毛玻璃背景（`window_background_opacity = 0.5` + Acrylic，**有意为之，不是 bug**）。
- 开窗直接进 WSL 的 Ubuntu（`default_domain`，脚本已按本机发行版名填好）。
- WebGpu 渲染加速、关掉编程连字、滚动缓冲 10 万行、右键粘贴。
- 开了 `automatically_reload_config`：**改 `~/.wezterm.lua` 存盘即时生效，不用重开**（只有装字体、切默认 shell 这类才需重开终端）。

**重开并自查**：关闭、重新打开 WezTerm（重开才会加载新配置、自动进 WSL Ubuntu）。然后花 10 秒照下表自查——都对，这层就成了：

| 看哪里 | 正常应是 | 不对时怎么弄 |
|--------|----------|--------------|
| 提示符 / `ll` 输出里的图标 | 文件夹、git 分支等小图标正常显示 | 显示成方框 `□` / `�` = 字体没装成功，回「装字体」把 `.ttf`「为所有用户安装」 |
| 开窗落在哪 | 直接进 WSL 的 Ubuntu | 报 `domain not found` / 没进 WSL = 发行版名对不上（一般只在你有多个发行版时发生），改 `~/.wezterm.lua` 的 `config.default_domain`，`wsl.exe -l -q` 查实际名 |
| 窗口背景 | 半透明毛玻璃（有意为之，不是 bug） | 看不惯就改 `~/.wezterm.lua` 的 `window_background_opacity`（`1.0` = 完全不透明） |

**微调**（都在 Windows 的 `~/.wezterm.lua`，存盘即生效）：想要编程连字就把 `harfbuzz_features` 里的 `liga=0` / `clig=0` / `calt=0` 改成 `=1`。

> WezTerm 快捷键（新标签页 / 搜索 / 复制粘贴 / 调字号…）见 [cheatsheet.md](./cheatsheet.md)。

---

## 2. 复用器：tmux

**是什么**：tmux 是终端复用器——在一个窗口里开多个 pane / 会话、断开连接（detach）后台不丢、重启后还能恢复会话。它跑在 WezTerm 里面、shell 外面。

**装它 + 配它**（在 WSL 里跑本层脚本）。📋 执行：

```bash
cd ~/projects/WSL_Setup/5-terminal/multiplexer
chmod +x setup.sh && ./setup.sh
```

脚本做了什么：

1. **tmux 本体**：一般已在 [4-dev §1.7](../4-dev/README.md) 用 `apt` 装好；脚本第一步会探测，**没装就 `apt install` 兜底装上**。
2. 部署 `tmux.conf` → `~/.tmux.conf`（原有的备份为 `.bak`）。
3. 装 TPM（tmux 插件管理器）及它管理的 3 个插件 `tmux-sensible` / `tmux-resurrect` / `tmux-continuum`（用命令行 `install_plugins` 装，比进 tmux 按 `Ctrl+A I` 可靠；连 TPM 本体，`~/.tmux/plugins/` 下共 4 个）。
4. 装 `ta` 命令到 `~/.local/bin/`。
5. 装 `win32yank`（修 WSL 默认 `clip.exe` 复制中文乱码）。

**`tmux.conf` 配了什么**：

- 前缀键从 `Ctrl+B` 改成 **`Ctrl+A`**（更顺手）。
- Catppuccin Mocha 状态栏（左 session 名、右日期时间）。
- Vim 风格 pane 切换、鼠标支持（点选 / 滚轮翻页 / 拖边框调大小）。
- 一键 Agent Team 布局：三格（1 大 + 2 小）、田字格（4 等分）。
- 复制走 `win32yank`（修中文乱码）。
- 会话保存/恢复：resurrect + continuum，每 10 分钟自动存，重启 WSL 后可恢复（含 pane 内容）。
- 滚动缓冲 10 万行（接 Claude Code 长输出）。

**`ta` 命令**：把「建会话 / 连会话 / 自动分屏」收成一条命令：

| 命令 | 作用 |
|------|------|
| `ta` | 列出会话 / 只有一个就直接连 |
| `ta 名称` | 创建或连接到该会话 |
| `ta 名称 N` | 创建会话 + 自动开 N 个 pane（如 `ta dev 3`） |
| `ta kill 名称` | 关闭指定会话 |
| `ta kill-all` | 关闭所有会话 |
| `ta help` | 完整速查卡 |

**验证**：📋 执行 `ta test`——应创建名为 `test` 的会话并自动连入。`Ctrl+A` 然后按 `d` 退出，`ta kill test` 关闭。

**排错**（少见）：

- 插件没装全（只装上 `tpm` 自身或一个）：`Ctrl+A` 然后大写 `I` 的交互式安装有时会漏装，**最可靠是用命令行**。📋 在 WSL 终端（不必进 tmux）执行，再 `ls ~/.tmux/plugins/` 应看到 4 个：

  ```bash
  ~/.tmux/plugins/tpm/bin/install_plugins
  ```

- `win32yank` 没装上（脚本提示「下载失败」，复制中文会乱码）：📋 手动补装：

  ```bash
  curl -fsSL -o /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -o /tmp/win32yank.zip -d /tmp/win32yank
  sudo cp /tmp/win32yank/win32yank.exe /usr/local/bin/
  ```

> tmux 与 `ta` 的完整键位 / 命令速查见 [cheatsheet.md](./cheatsheet.md)（或终端里 `ta help`）。

---

## 3. shell：bash + zsh + starship

**是什么**：shell 是你每天敲命令的交互层。[4-dev §1.7](../4-dev/README.md) 装了 zoxide / fzf / eza / bat，但 Ubuntu 出厂的 bash/zsh **不会自动接它们——装了等于没用**；这一层就是补上接线，并把提示符换成 starship。日常交互用 **zsh**，**脚本仍走 bash**（见末尾「为何不受影响」）。

**装它 + 配它**（在 WSL 里跑本层脚本）。📋 执行：

```bash
cd ~/projects/WSL_Setup/5-terminal/shell
chmod +x setup.sh && ./setup.sh
```

脚本做了什么（按执行先后）：

1. 装 starship 提示符（到 `~/.local/bin`）。
2. 部署 bash 接线：`shell.bash` → `~/.config/wsl-setup/`、`starship.toml` → `~/.config/`，并在 `~/.bashrc` 末尾 source。
3. 装 zsh + oh-my-zsh，含两个外部插件 `zsh-autosuggestions`（灰字补全）、`zsh-syntax-highlighting`（命令高亮）。
4. 部署 zsh 接线：`shell.zsh` → `~/.config/wsl-setup/`、`zshrc` → `~/.zshrc`。
5. 把默认登录 shell 切到 zsh（重开终端生效）。

> zoxide / fzf / eza / bat 的**本体来自 [4-dev §1.7](../4-dev/README.md)**，这一层只负责把它们接进 shell；缺了也不报错，少接几样而已。图标依赖 Nerd Font（由 §1 下载安装）——只配本层、没配 §1 的话，starship 图标会显示成方框，单独补字体见 §1。

**看效果**：关闭重开终端，默认就进 **zsh**——直接有灰字补全、命令绿/红高亮、starship 提示符、`z` 跳目录、`Ctrl+R` 模糊搜历史、`ll`/`eza` 别名。想先在当前 bash 会话试 bash 层：📋 `source ~/.bashrc`（只对当前 bash 窗口生效；zsh 那套要重开才进）。

**bash 层做了什么**（`shell.bash`，`source ~/.bashrc` 后生效）：

- **starship 提示符**：当前目录、git 分支与状态、项目语言版本、命令耗时（>2s 才显示），配色与 WezTerm/tmux 同为 Catppuccin Mocha。
- **zoxide**：`z 关键字` 按访问频率跳到最常去的目录，不用再敲长路径。
- **fzf 键位**：`Ctrl+R` 搜命令历史、`Ctrl+T` 选文件、`Alt+C` 跳子目录（Ubuntu 的 fzf 默认不挂键位，这里显式接上）。
- **现代别名**：`ls`/`ll`/`la`/`lt` 走 eza（图标、git 状态、树形），`bat` = 带高亮的 cat，`fd` = 更快的 find。
- **历史**：放大到 10 万条，并在多个 tmux pane / 终端间实时共享。

**zsh 额外做了什么**（重开终端后默认就进 zsh）：`shell.zsh` 与 `shell.bash` **责任对称**——上面那套（z / fzf / 别名 / starship / 大历史）zsh 里一样有；额外多出：

- **灰字补全（autosuggestions）**：边敲边给灰色历史建议，`→` / `End` 接受整条、`Alt+F` 接受一个词。
- **命令高亮（syntax-highlighting）**：合法命令显绿、拼错显红，回车前就看出问题。
- **oh-my-zsh 内置插件**：`git`（海量 git 别名/补全）、`sudo`（连按两下 `Esc` 补 `sudo`）、`extract`（一条命令解任意压缩包）、`colored-man-pages`、`command-not-found`（提示该装哪个 apt 包）。
- **提示符仍是 starship**（`ZSH_THEME` 留空），与 bash 同款；历史靠 zsh 原生 `SHARE_HISTORY` 实时多 pane 共享，同样 10 万条。

**脚本为何不受影响**：`chsh` 只换**交互式**登录 shell；脚本跑哪个解释器由它的 shebang 决定（本仓脚本都带 bash shebang），跟登录 shell 无关——`./xxx.sh`、`bash xxx.sh` 永远走 bash。所以「日常 zsh、脚本 bash」是默认效果，无需额外设置。想退回 bash 当默认：`chsh -s $(command -v bash)` 后重开终端，`~/.bashrc` 与 `shell.bash` 一直原样保留。

> shell / zsh 的完整键位速查见 [cheatsheet.md](./cheatsheet.md)。
