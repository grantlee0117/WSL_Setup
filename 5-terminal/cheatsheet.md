# 终端工具链速查卡

## 安装步骤

三层各自独立、各带安装脚本，按需配；要整套就三层都跑（顺序 §1→§2→§3）。

命令整块复制粘贴执行；`winget` 那行在 Windows PowerShell 里跑，其余在 WSL 里。

```bash
# 1. 终端模拟器（WezTerm）
winget install wez.wezterm --source winget          # 在 Windows 的 PowerShell 里装
cd ~/projects/WSL_Setup/5-terminal/terminal-emulator # 再回 WSL 跑本层脚本
chmod +x setup.sh && ./setup.sh                      # 下载字体 + 部署 ~/.wezterm.lua
#    → 装字体：全选 Windows 字体目录里的 .ttf → 右键 → 为所有用户安装
#      （只下载不算装上；图标显示成方框 □ 就是这步没做）

# 2. 复用器（tmux）：tmux 兜底 + 配置 + 插件 + ta + win32yank
cd ~/projects/WSL_Setup/5-terminal/multiplexer
chmod +x setup.sh && ./setup.sh

# 3. shell：zsh + oh-my-zsh + starship + 接线
cd ~/projects/WSL_Setup/5-terminal/shell
chmod +x setup.sh && ./setup.sh

# 4. 关闭 WezTerm 重新打开 → 默认进 zsh，灰字补全/命令高亮/starship 即生效
#    （想先在当前 bash 窗口试：source ~/.bashrc）
#    zsh/oh-my-zsh、tmux 插件、win32yank、starship 均由各层脚本自动装，无需手动
#    脚本仍走 bash：本仓脚本都带 bash shebang，与登录 shell 无关
```

## tmux 快捷键 (前缀: Ctrl+A)

> 前缀 `Ctrl+A` 和 shell 里「跳到行首」的 `Ctrl+A`（readline）撞键。要给 shell 送一个真正的行首 `Ctrl+A`，**连按两下** `Ctrl+A`（第二下被 `send-prefix` 原样转发给 shell），行首功能没丢、只是多按一下。

### 日常操作
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A %` | 左右分屏 |
| `Ctrl+A "` | 上下分屏 |
| `Ctrl+A h/j/k/l` | Vim 风格切换 pane |
| `Ctrl+A Ctrl+Q` | 显示各 pane 编号，按数字直接跳过去 |
| `Alt+h/j/k/l` | 调整 pane 大小 (不需要前缀) |
| `Ctrl+A d` | 后台挂起 (detach) |
| `Ctrl+A s` | 选择会话 (树状预览、可缩放) |
| `Ctrl+A c` | 新窗口 |
| `Ctrl+A 1-9` | 切换窗口 |
| `Ctrl+A r` | 重载配置 |
| `Ctrl+A Enter` | 进入复制模式 (vi 键位) |

### Agent Team 布局
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A a` | 三格布局 (1 大 + 2 小) |
| `Ctrl+A q` | 田字格 (4 等分) |

### 会话保存/恢复
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A Ctrl+S` | 保存 session |
| `Ctrl+A Ctrl+R` | 恢复 session |
| `Ctrl+A I` | 补装插件 (setup.sh 已自动装；仅装不全时兜底，大写 I 是 TPM 硬编码) |

### tmux 自带默认键（没写进配置、出厂就有）

下面这些没写进 `tmux.conf`，但 tmux 默认就绑了、本配置也没动，直接能用。

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A z` | 当前 pane 全屏放大 / 还原（最常用之一，看长输出时很顺手） |
| `Ctrl+A x` | 关掉当前 pane（会先让你确认 y/n） |
| `Ctrl+A n` / `p` | 下一个 / 上一个窗口（补 `1-9` 直接跳之外的顺序切换） |
| `Ctrl+A ,` | 给当前窗口改名（名字显示在底部状态栏） |
| `Ctrl+A &` | 关掉当前窗口（会先让你确认 y/n） |

## ta 快捷命令

```bash
ta              # 列出/attach 会话
ta nn           # 创建或 attach 到 "nn" 会话（nn 只是会话名）
ta nn 3         # 创建 "nn" 会话 + 3 个 pane
ta kill nn      # 关闭 "nn" 会话
ta kill-all     # 关闭所有
ta help         # 完整速查卡
```

## shell 层（`source ~/.bashrc` 后生效）

把 4-dev §1.7 装的工具接进 bash，并换上 starship 提示符。

| 快捷键 / 命令 | 功能 |
|--------------|------|
| `Ctrl+R` | fzf 模糊搜命令历史 |
| `Ctrl+T` | fzf 选当前目录文件，插入命令行 |
| `Alt+C` | fzf 选子目录并 cd 进去 |
| `z 关键字` | zoxide 跳到最常去的匹配目录 |
| `ll` / `la` / `lt` | eza：详情(带 git) / 含隐藏 / 树形 |
| `bat 文件` | 带语法高亮的 cat |
| `fd 模式` | 更快的 find |

> 历史已放大到 10 万条，并在多个 tmux pane / 终端间实时共享。

## zsh 专属（重开终端默认就进 zsh）

上面那套（z / Ctrl+R / 别名 / starship）在 zsh 里同样有；下面是 zsh 才多出来的：

| 快捷键 / 命令 | 功能 |
|--------------|------|
| `→` / `End` | 接受整条灰字补全（autosuggestions） |
| `Alt+F` | 只接受灰字补全的一个词 |
| 命令绿/红 | syntax-highlighting：合法绿、拼错红，回车前就看出来 |
| `Esc` `Esc` | 给当前/上条命令前面补 `sudo`（sudo 插件） |
| `extract 包名` | 解任意压缩包（.tar.gz/.zip/.7z…），不用记参数 |
| `gst` / `gco` / `gp` | oh-my-zsh git 别名（`alias \| grep git` 看全部） |

> 提示符仍是 starship（`ZSH_THEME` 留空），bash/zsh 同款。脚本照旧走 bash——本仓脚本都带 bash shebang，与登录 shell 无关。
> 想退回 bash 当默认：`chsh -s $(command -v bash)` 后重开终端。

## 挂长任务的典型用法

```bash
ta nn           # 开一个专属会话（nn 只是会话名，随便起）
<你的长命令>     # 跑起来（作者用 Night-Night: nn 15 60，该工具非本仓提供）
# Ctrl+A d      # 断开去睡觉
ta nn           # 回来 attach 看结果
```

## Agent Team 监控

```bash
ta agents 4     # 开一个 4-pane 布局
# 或进入 tmux 后按 Ctrl+A q 创建田字格
# 每个 pane 跑一个 Claude Code 实例
```

## WezTerm 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+T` | 新 Tab |
| `Ctrl+Shift+W` | 关闭 Tab |
| `Ctrl+Shift+F` | 搜索 |
| `Ctrl+Shift+C/V` | 复制/粘贴 |
| `Ctrl+Shift+↑/↓` | 调整字体大小 |
| `Alt+1-5` | 切换 Tab |
| 选中文本 | 松开鼠标即复制到剪贴板（WezTerm 默认行为） |
| 右键 | 粘贴 |

### WezTerm 内置默认键（没写进配置、自带就有）

这三个键没写进 `wezterm.lua` 的 `config.keys`，但 WezTerm 出厂默认就绑了，本配置也没禁用默认键，所以直接能用。

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+Shift+Space` | **Quick Select**：把屏幕上的 URL / 路径 / git hash 标上字母，按字母直接复制，比鼠标划选快得多 |
| `Ctrl+Shift+P` | **Command Palette**：命令面板，搜得到 WezTerm 所有动作 |
| `Ctrl+Shift+X` | **Copy Mode**：键盘式（vim 键位）选择并复制 |

> Copy Mode 日常用得少——你在 tmux 里会用 tmux 自己的复制模式（`Ctrl+A Enter`），WezTerm 的 Copy Mode 主要用在不开 tmux 的纯 WezTerm 窗口里。
