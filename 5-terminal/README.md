# 终端环境配置（WezTerm + tmux + zsh + starship）

> **适用场景**：在 [2-wsl](../2-wsl/README.md) / [4-dev](../4-dev/README.md) 之上，把 WSL 终端配成统一的 Catppuccin Mocha 深色主题、Nerd Font 图标、starship 提示符，并加上 tmux 的会话保存/分屏与 zsh 的灰字补全/命令高亮。这一层是可选的美化与效率层，不影响任何开发工具的功能。
>
> **前置条件**：先完成 [2-wsl](../2-wsl/README.md) 的 WSL2 安装。[4-dev §1.7](../4-dev/README.md) 的 tmux 和现代 CLI（zoxide / fzf / eza / bat）装好最佳；没装也不报错，只是少接几样（tmux 没装时，复用器层的脚本会兜底装上）。

**代码块标记**（同 [2-wsl](../2-wsl/README.md) / [4-dev](../4-dev/README.md)）：📋 整块复制粘贴执行 · ✂️ 逐条执行（前一条会改环境、后续依赖它）· 📝 贴进编辑器的文件内容。

**这一层做什么**：

1. 终端模拟器 WezTerm：Catppuccin Mocha 主题、Nerd Font、半透明背景、默认启动进 WSL、GPU 加速。
2. 复用器 tmux：会话保存/恢复、一键分屏（含 Agent Team 布局）、方向键 + 鼠标操作、广播输入与多格监控。
3. shell：交互 shell 换成 zsh + oh-my-zsh（灰字补全、命令高亮），并把 4-dev §1.7 装的 zoxide / fzf / eza / bat 接进 bash 和 zsh，提示符换成 starship。

本目录（`5-terminal/`）按角色分成三个文件夹，每个文件夹放该角色的配置和它自己的安装脚本：

```
5-terminal/
├── README.md                  本文档
├── cheatsheet.md              快捷键 / 命令速查卡
├── terminal-emulator/         终端模拟器（自带安装脚本，可独立配置）
│   ├── wezterm.lua            Catppuccin Mocha 主题、Nerd Font、半透明毛玻璃、默认启动 WSL、GPU 加速、快捷键
│   └── setup.sh               下载 Nerd Font + 部署 ~/.wezterm.lua（自动填 default_domain）
├── multiplexer/               复用器（自带安装脚本，可独立配置）
│   ├── tmux.conf              方向键 pane 切换、广播/监控、Catppuccin 状态栏(CPU/电池)、Agent Team 布局、会话保存/恢复
│   ├── ta                     tmux 快捷命令：创建/连接/关闭会话，自动分屏
│   └── setup.sh               tmux 本体兜底 + 部署 ~/.tmux.conf + TPM/插件 + ta + win32yank
└── shell/                     shell（自带安装脚本，可独立配置）
    ├── shell.bash             把 4-dev §1.7 的 zoxide/fzf/eza/bat 接进 bash + 大历史/多 pane 共享
    ├── shell.zsh              同上的 zsh 版（接线对称）+ zsh 专属灰字补全/命令高亮
    ├── zshrc                  ~/.zshrc 模板：oh-my-zsh 引导（内置插件）→ 末尾 source shell.zsh
    ├── starship.toml          starship 提示符（Catppuccin Mocha：git 分支状态、语言版本、命令耗时）
    └── setup.sh               装 zsh + oh-my-zsh + starship + 部署接线 + 切默认 shell
```

> 文件夹用角色名（terminal-emulator / multiplexer / shell）而不是工具名：tmux 只是复用器的一种，换成 zellij 或 screen 时目录语义不变。配置文件名仍用工具名，因为它就是那个工具的配置。

下表汇总三个角色的程序和安装位置，逐个配置见后面三节：

| 角色 | 程序 | 装在哪 |
|------|------|--------|
| 终端模拟器 | WezTerm | Windows 侧 `winget`——三个角色里只有它在 Windows（见 §1） |
| 复用器 | tmux | 一般在 [4-dev §1.7](../4-dev/README.md) 用 `apt` 装；没装则本层脚本兜底装上（见 §2） |
| shell | zsh + oh-my-zsh + starship | 由 shell 层脚本自动安装（见 §3） |
| shell | zoxide / fzf / eza / bat | [4-dev §1.7](../4-dev/README.md) 装本体，本目录只把它们接进 shell（见 §3） |

> tmux 和那几个 CLI 是 [4-dev](../4-dev/README.md) 的开发基础设施，纯 bash、无主题时照样能用，所以由 4-dev 负责安装、本目录不重复装。本目录只做可选的主题和接线。

三层互不依赖，各跑各的 `setup.sh` 即可；要整套就三层都跑（建议顺序 §1 → §2 → §3）。唯一的跨层依赖是 Nerd Font 图标：由终端模拟器层（§1）下载安装，shell 的 starship 提示符靠它显示图标（tmux 状态栏只用普通字符和框线 `│`，不依赖 Nerd Font，§1 没配也不会变方框）。只配 shell、不配 §1 的话，starship 图标会显示成方框（单独补字体见 §1 的「装字体」）。

下面按 **终端模拟器 → 复用器 → shell** 的顺序讲（由外到内：终端模拟器是窗口，tmux 跑在窗口里，shell 跑在 tmux 里）。

---

## 1. 终端模拟器：WezTerm

WezTerm 是终端模拟器，也就是终端窗口本身。三个角色里只有它装在 Windows 侧，其余都在 WSL 里。

**装它**（Windows 侧 PowerShell，已装可跳过）。📋 整块复制粘贴执行：

```powershell
winget install wez.wezterm --source winget
```

**配它**（在 WSL 里跑本层脚本）。📋 整块复制粘贴执行：

```bash
cd ~/projects/WSL_Setup/5-terminal/terminal-emulator
chmod +x setup.sh && ./setup.sh
```

脚本做了什么：

1. 下载 JetBrainsMono Nerd Font 到 Windows 字体目录（装字体还要手动，见下一步）。
2. 部署 `wezterm.lua` → Windows 的 `~/.wezterm.lua`，按本机 `WSL_DISTRO_NAME` 自动填好 `default_domain`（原配置备份为 `.bak`）。

**装字体**：脚本只把字体下载到 Windows 字体目录，安装还要手动——在 Windows 资源管理器地址栏输入 `C:\Users\你的用户名\AppData\Local\Microsoft\Windows\Fonts`，全选所有 `.ttf` → 右键 → 为所有用户安装。（只下载不算装上；图标显示成方框就是这步没做。）

**`wezterm.lua` 配了什么**：

- 配色 Catppuccin Mocha；字体 JetBrainsMono Nerd Font，字号 12；中文回退默认微软雅黑（所有 Windows 都自带，换任何机器都在）。想换别的中文字形（等线 `DengXian`、黑体 `SimHei`、思源黑体 `Noto Sans SC` 等），把回退改成一只**系统里已装好**的 family 名即可——这几只不一定每台都有，填前先确认装了，改法见 `wezterm.lua` 里字体段的注释。
- 半透明毛玻璃背景（`window_background_opacity = 0.5` + Acrylic，默认如此，想要不透明见下方自查表）。
- 开窗直接进 WSL 的 Ubuntu（`default_domain`，脚本已按本机发行版名填好）。
- WebGpu 渲染加速、关掉编程连字、滚动缓冲 10 万行、右键粘贴。
- 底部 Tab 栏：只有一个 Tab 时自动隐藏，开第 2 个 Tab（`Ctrl+Shift+T`）才在底部显示（Tab 与 tmux 的分工、叠栏现象、关闭办法详见下方微调）。
- 开了 `automatically_reload_config`：改 `~/.wezterm.lua` 存盘即时生效，不用重开（只有装字体、切默认 shell 这类才需重开终端）。

**重开并自查**：关闭、重新打开 WezTerm（重开才会加载新配置、自动进 WSL Ubuntu），照下表自查：

| 看哪里 | 正常应是 | 不对时怎么弄 |
|--------|----------|--------------|
| 提示符 / `ll` 输出里的图标 | 文件夹、git 分支等小图标正常显示 | 显示成方框 `□` / `�` = 字体没装成功，回「装字体」把 `.ttf`「为所有用户安装」 |
| 中文（注释、路径里的汉字） | 正常渲染、不缺字 | 变方框 / 乱码 = 中文回退字体没匹配上，改 `~/.wezterm.lua` 字体段末尾那只 family 名（默认微软雅黑、一定在；那段有注释说明换法） |
| 开窗落在哪 | 直接进 WSL 的 Ubuntu | 报 `domain not found` / 没进 WSL = 发行版名对不上（一般只在你有多个发行版时发生），改 `~/.wezterm.lua` 的 `config.default_domain`，`wsl.exe -l -q` 查实际名 |
| 窗口背景 | 半透明毛玻璃（默认如此） | 想要不透明就改 `~/.wezterm.lua` 的 `window_background_opacity`（`1.0` = 完全不透明） |
| 窗口花屏 / 发虚 / 毛玻璃不出效果（只变暗没真透），或启动报 GPU 错 | 半透明毛玻璃、画面干净 | 显卡或驱动和 WebGpu 不对付：把 `~/.wezterm.lua` 的 `config.front_end` 改成 `"OpenGL"` 存盘看是否恢复（仍不行再试 `"Software"`），恢复了就是 WebGpu 的锅 |

**微调**（都在 Windows 的 `~/.wezterm.lua`，存盘即生效）：

- **字号**：改 `config.font_size = 12.0` 的数值。`Ctrl+Shift+↑/↓` 只是临时缩放、重开复原；想永久改就改这里。
- **配色**：改 `config.color_scheme`，WezTerm 内置数百套，名字见[官方配色表](https://wezterm.org/colorschemes/)。注意 tmux 状态栏和 starship 提示符也配成了 Catppuccin Mocha，只换这一处三者会不一致。
- **透明度 / 毛玻璃**：改 `config.window_background_opacity`（`1.0` = 完全不透明、毛玻璃自动关），见上方自查表。
- **编程连字**：把 `harfbuzz_features` 里的 `liga=0` / `clig=0` / `calt=0` 改成 `=1` 即开启。
- **独显 / 核显**（双显卡笔记本）：WebGpu 默认走低功耗核显（终端够用、省电省热）。想强制独显，取消 `~/.wezterm.lua` 里 `config.webgpu_power_preference = "HighPerformance"` 那行注释——代价是独显常驻、更费电更热，终端一般无必要。
- **中文回退字体**：`config.font` 的 `font_with_fallback` 末尾那只 family 名。默认微软雅黑（最稳、一定有）；想换填一只系统里已装好的 family 名（如等线 `DengXian`、黑体 `SimHei`、思源 `Noto Sans SC`），名字必须和系统登记的完全一致，写错会静默退回 WezTerm 自带兜底，文件内注释有说明。
- **底部 Tab 栏**：WezTerm 的 Tab 是「终端窗口层」的多个独立标签页（`Ctrl+Shift+T` 新建、`Ctrl+Shift+W` 关、`Alt+1~5` 切换），跟 tmux 管的「单个标签页**内部**的 pane 分屏 / 会话恢复」是两套东西、互不冲突。默认单 Tab 时 Tab 栏自动隐藏（`hide_tab_bar_if_only_one_tab = true`），开 ≥2 个 Tab 才在底部出现——此时底部会同时有「WezTerm Tab 栏 + tmux 状态栏」两条叠着，是正常现象、不是 bug。若真不想要 WezTerm 这条 Tab 栏，设 `config.enable_tab_bar = false` 彻底关掉（Tab 功能仍在、只是没有可视栏；本配置默认保留，方便偶尔开个不进 tmux 的纯窗口时也能看到标签页）。
- **光标样式**：本配置用默认的稳定方块。想换在 `~/.wezterm.lua` 取消 `config.default_cursor_style` 那行注释、改成想要的值——可选方块 / 下划线 / 竖条，各有「稳定（不闪）」和「闪烁」两版（`SteadyBlock`、`BlinkingBar` 等，`Steady` = 不闪、`Blinking` = 闪；文件内注释列了全部 6 个取值）。
- **缺字告警（哨兵）**：`warn_about_missing_glyphs` 默认开着——某个字符所有字体都画不出来时，WezTerm 会弹「配置错误」窗提示你字体没配好（图标显示成方框、中文乱码这类问题的源头告警）。本配置特意保留它当哨兵；想静默可在 `~/.wezterm.lua` 取消那行注释设 `false`，但不建议关（关了真缺字也不再吭声）。

> WezTerm 快捷键（新标签页 / 搜索 / 复制粘贴 / 调字号…）见 [cheatsheet.md](./cheatsheet.md)。

---

## 2. 复用器：tmux

tmux 是终端复用器：在一个窗口里开多个 pane 和会话，断开连接（detach）后进程在后台**继续跑**，回来 `attach` 还是原样。它跑在 WezTerm 里面、shell 外面。（注意：detach 让进程不丢的前提是**不关机**；真的重启后进程会随之结束，插件能找回的只是布局而非运行中的任务，详见本节末「会话保存/恢复」。）

**装它 + 配它**（在 WSL 里跑本层脚本）。📋 整块复制粘贴执行：

```bash
cd ~/projects/WSL_Setup/5-terminal/multiplexer
chmod +x setup.sh && ./setup.sh
```

脚本做了什么：

1. tmux 本体：一般已在 [4-dev §1.7](../4-dev/README.md) 用 `apt` 装好；脚本第一步会探测，没装就 `apt install` 兜底装上。
2. 部署 `tmux.conf` → `~/.tmux.conf`（原有的备份为 `.bak`）。
3. 装 TPM（tmux 插件管理器）及它管理的 5 个插件 `tmux-sensible` / `tmux-resurrect` / `tmux-continuum` / `tmux-cpu` / `tmux-battery`（用命令行 `install_plugins` 装，比进 tmux 按 `Ctrl+A I` 可靠；连 TPM 本体，`~/.tmux/plugins/` 下共 6 个）。
4. 装 `ta` 命令到 `~/.local/bin/`。
5. 装 `win32yank`（修 WSL 默认 `clip.exe` 复制中文乱码）。

**`tmux.conf` 配了什么**：

- 前缀键从 `Ctrl+B` 改成 `Ctrl+A`。
- Catppuccin Mocha 状态栏：左侧 session 名 + 指示灯（按下前缀亮 `PREFIX`、开广播亮 `SYNC`），右侧 CPU 占用 + 电池 + 日期时间（纯文字+颜色，不依赖 Nerd Font）。
- 切 pane 用无前缀的 `Alt+方向键`（高频动作，按住 Alt 连点即可；`前缀+方向键` 也仍能切）。调 pane 大小直接用鼠标拖边框（键盘党可用 `前缀+Alt+方向键`，tmux 自带）。不再绑 vim 的 hjkl，顺带把 `前缀+l` 还给默认的"跳上一个窗口"。
- 一键 Agent Team 布局：三格（1 大 + 2 小）、田字格（4 等分）。
- 多格协同 / 监控：`Ctrl+A e` 广播输入（一条命令同时发给当前窗口所有 pane）、别的窗口有新输出/响铃时标签自动高亮、`Ctrl+A M` 给 pane 设"静默 N 秒就提醒"（长任务跑完通知）、每个 pane 顶部标题栏显示「编号 命令」分清谁是谁。
- 浮动弹窗 `Ctrl+A g`：在当前分屏之上浮一个临时终端（落在当前 pane 的目录），临时敲命令 / 跑 lazygit 用完即关，下面的布局原封不动。
- 复制走 `win32yank`（修中文乱码）。
- 会话保存/恢复（resurrect + continuum，每 10 分钟自动存）——**要分清两种情况，别被「恢复」二字误导**：
  - **只 detach、不关机**：进程本来就在后台真跑着，`attach` 回来即可，这是 tmux 本体能力、跟插件无关；挂长任务过夜靠的就是这个。
  - **tmux 真退出后**（`wsl --shutdown`、电脑重启、tmux server 被杀）：这才轮到插件出场，但它**只恢复「会话骨架」**——窗口数、分屏布局、各 pane 的工作目录，外加当时屏幕上的**文字快照**（`capture-pane-contents`）。它**不会让你跑的命令继续跑**：进程早随重启结束了，恢复出来是新 shell，只是布局和文字长得一样。这套骨架在你**下次启动 tmux 时由 continuum 自动恢复**（`@continuum-restore on`，不用手动；想手动恢复按 `Ctrl+A Ctrl+R`）。
- 滚动缓冲 10 万行（接 Claude Code 长输出）。

**按需取舍与调整**（都在 `~/.tmux.conf`，改完 `Ctrl+A r` 重载即可；这是个跨机器复用的仓库，下面几条尤其值得照搬前知道）：

- **状态栏电池段是「本机相关」的，换机器可能是空的。** 右侧 `BAT` 读的是 WSL 透传进来的 `/sys/class/power_supply/BAT*`，这台笔记本能读到。但**台式机本来没电池、或某些 WSL2 内核 / WSLg 版本没把电池透传进来**时，`#{battery_percentage}` 会返回空，状态栏就显示成「`BAT  │`」一截空白——**这不是坏了、也不报错，只是难看**。不需要电池就删两处：① `tmux.conf` 插件区的 `set -g @plugin 'tmux-plugins/tmux-battery'` 这行；② `status-right` 里 `#{battery_color_fg}BAT #{battery_percentage}#[fg=#6c7086] │ ` 这一段。CPU 段读的是 `/proc`，所有机器都正常，不受影响。
- **盯长任务 / 多 agent 时，真正的主力信号是 `Ctrl+A M`（静默告警），不是窗口活动高亮。** `monitor-activity` 的逻辑是「别的窗口一有新输出就高亮标签」——但你多格各跑一个 agent、几乎一直在刷输出时，几乎每个非当前窗口都会**常亮**，信号被稀释、等于没用。而 `Ctrl+A M` 设的「安静 N 秒就提醒」抓的恰是**任务跑完、不再刷屏的那一刻**，才是这个场景对的信号。所以：**`Ctrl+A M` 当主力，活动高亮当辅助**（活动高亮在"偶尔有个后台窗口冒一条输出"时仍有用，故保留）。
- **pane 顶部标题栏每个 pane 吃掉一行。** 田字格 4 格 + 终端不高时，4 条标题占 4 行，会觉得挤。「分清谁是谁」一般值这个代价；嫌挤就把 `tmux.conf` 里 `set -g pane-border-status top` 改成 `off` 关掉，或临时 `Ctrl+A z` 把当前格放大了看。
- **`Ctrl+A C-q` 显示的 pane 编号默认只停 1 秒，已调到 2 秒**（`display-panes-time 2000`，和消息提示时长 `display-time` 对齐），手快想调短就改这个值。

**`ta` 命令**：把「建会话 / 连会话 / 自动分屏」收成一条命令：

| 命令 | 作用 |
|------|------|
| `ta` | 列出会话 / 只有一个就直接连 |
| `ta 名称` | 创建或连接到该会话 |
| `ta 名称 N` | 创建会话 + 自动开 N 个 pane（如 `ta dev 3`） |
| `ta kill 名称` | 关闭指定会话 |
| `ta kill-all` | 关闭所有会话 |
| `ta help` | 完整速查卡 |

**验证**：📋 整块复制粘贴执行 `ta test`，应创建名为 `test` 的会话并自动连入。`Ctrl+A` 再按 `d` 退出，`ta kill test` 关闭。

**排错**（少见）：

- 插件没装全（只装上 `tpm` 自身或一个）：`Ctrl+A` 然后大写 `I` 的交互式安装有时会漏装，命令行最可靠。📋 整块复制粘贴执行（在 WSL 终端，不必进 tmux），再 `ls ~/.tmux/plugins/` 应看到 6 个：

  ```bash
  ~/.tmux/plugins/tpm/bin/install_plugins
  ```

- `win32yank` 没装上（脚本提示「下载失败」，复制中文会乱码）：📋 手动补装，整块复制粘贴执行：

  ```bash
  curl -fsSL -o /tmp/win32yank.zip https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -o /tmp/win32yank.zip -d /tmp/win32yank
  sudo cp /tmp/win32yank/win32yank.exe /usr/local/bin/
  ```

> tmux 与 `ta` 的完整键位 / 命令速查见 [cheatsheet.md](./cheatsheet.md)（或终端里 `ta help`）。

---

## 3. shell：bash + zsh + starship

shell 是命令行的交互层。[4-dev §1.7](../4-dev/README.md) 装了 zoxide / fzf / eza / bat，但 Ubuntu 出厂的 bash/zsh 不会自动接它们，装了也用不上；这一层补上接线，并把提示符换成 starship。日常交互用 zsh，脚本仍走 bash（原因见本节末尾）。

**装它 + 配它**（在 WSL 里跑本层脚本）。📋 整块复制粘贴执行：

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

> zoxide / fzf / eza / bat 的本体来自 [4-dev §1.7](../4-dev/README.md)，本层只负责把它们接进 shell；缺了也不报错，少接几样而已。starship 图标依赖 Nerd Font（由 §1 下载安装）——只配本层、没配 §1 的话，图标会显示成方框，单独补字体见 §1。

**看效果**：关闭重开终端，默认进 zsh，直接就有灰字补全、命令绿/红高亮、starship 提示符、`z` 跳目录、`Ctrl+R` 模糊搜历史、`ll`/`eza` 别名。想先在当前 bash 会话试 bash 层：📋 整块复制粘贴执行 `source ~/.bashrc`（只对当前 bash 窗口生效；zsh 那套要重开才进）。

**bash 层做了什么**（`shell.bash`，`source ~/.bashrc` 后生效）：

- **starship 提示符**：当前目录、git 分支与状态、项目语言版本、命令耗时（>2s 才显示），配色与 WezTerm/tmux 同为 Catppuccin Mocha。
- **zoxide**：`z 关键字` 按访问频率跳到最常去的目录，不用再敲长路径。
- **fzf 键位**：`Ctrl+R` 搜命令历史、`Ctrl+T` 选文件、`Alt+C` 跳子目录（Ubuntu 的 fzf 默认不挂键位，这里显式接上）。
- **现代别名**：`ls`/`ll`/`la`/`lt` 走 eza（图标、git 状态、树形），`bat` = 带高亮的 cat，`fd` = 更快的 find。
- **历史**：放大到 10 万条，并在多个 tmux pane / 终端间实时共享。

**zsh 额外做了什么**（重开终端后默认就进 zsh）：`shell.zsh` 和 `shell.bash` 责任对称——上面那套（z / fzf / 别名 / starship / 大历史）zsh 里一样有；额外多出：

- **灰字补全（autosuggestions）**：边敲边给灰色历史建议，`→` / `End` 接受整条、`Alt+F` 接受一个词。
- **命令高亮（syntax-highlighting）**：合法命令显绿、拼错显红，回车前就看出问题。
- **oh-my-zsh 内置插件**：`git`（海量 git 别名/补全）、`sudo`（连按两下 `Esc` 补 `sudo`）、`extract`（一条命令解任意压缩包）、`colored-man-pages`、`command-not-found`（提示该装哪个 apt 包）。
- **提示符仍是 starship**（`ZSH_THEME` 留空），与 bash 同款；历史靠 zsh 原生 `SHARE_HISTORY` 实时多 pane 共享，同样 10 万条。

**脚本为何不受影响**：`chsh` 只换交互式登录 shell；脚本跑哪个解释器由它的 shebang 决定，跟登录 shell 无关，而本仓脚本都带 bash shebang，所以 `./xxx.sh`、`bash xxx.sh` 始终走 bash。「日常 zsh、脚本 bash」是默认结果，不用额外设置。想退回 bash 当默认：`chsh -s $(command -v bash)` 后重开终端，`~/.bashrc` 和 `shell.bash` 一直原样保留。

> shell / zsh 的完整键位速查见 [cheatsheet.md](./cheatsheet.md)。
