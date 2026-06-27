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
| `Alt+←↓↑→` | 切换 pane（不用前缀，按住 Alt 连点；`前缀+方向键`也能切） |
| `Ctrl+A Ctrl+Q` | 显示各 pane 编号，按数字直接跳过去 |
| 鼠标拖边框 | 调整 pane 大小（键盘党用 `前缀 + Alt+方向键`，tmux 自带） |
| `Ctrl+A d` | 后台挂起 (detach) |
| `Ctrl+A s` | 选择会话 (树状预览、可缩放) |
| `Ctrl+A c` | 新窗口 |
| `Ctrl+A 1-9` | 切换窗口 |
| `Ctrl+A g` | 浮动终端：临时敲命令，不打乱当前分屏（`exit` / `Ctrl+D` 关） |
| `Ctrl+A r` | 重载配置 |
| `Ctrl+A Enter` | 进入复制模式 (vi 键位) |

### Agent Team 布局
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A a` | 三格布局 (1 大 + 2 小) |
| `Ctrl+A q` | 田字格 (4 等分) |

### 多格协同 / 监控

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A e` | 广播输入开/关：一条命令同时发给**当前窗口所有 pane**（状态栏亮红色 `SYNC`） |
| `Ctrl+A M` | 给当前 pane 设静默告警：安静 N 秒就提醒（长任务跑完通知你；输 `0` 关闭） |
| （自动） | 别的窗口有新输出 / 响铃 → 底部该窗口标签自动高亮（黄=新输出、红=响铃） |
| （自动） | 每个 pane 顶部标题栏显示「编号 命令」，多格监控时分清谁是谁（活动 pane 蓝色） |

> 盯长任务的**主力是 `Ctrl+A M`**（抓"跑完安静下来"那一刻）：多格各跑一个 agent、一直在刷输出时，活动高亮会几乎全亮、信号被稀释，只当辅助。
>
> 状态栏指示灯：按下前缀 `Ctrl+A` 时左侧亮黄色 `PREFIX`（提醒 tmux 在等下一个键）；开广播时亮红色 `SYNC`。右侧常驻 `CPU 占用` / `BAT 电池` / 日期时间（纯文字，不靠 Nerd Font）。`BAT` 在台式机 / 无电池透传的 WSL 上会是空白（非故障，删法见 README）。

### 会话保存/恢复

> 存/恢复的是**会话骨架**（窗口数、分屏布局、各 pane 工作目录 + 屏幕文字快照），**不是正在跑的进程**。tmux 真退出后（`wsl --shutdown` / 重启 / server 被杀）那些命令已经结束，恢复出来是新 shell、只是长得一样。想让长任务不丢，靠的是**只 detach、不关机**（`Ctrl+A d`，进程在后台真还跑着），不是这套插件。

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A Ctrl+S` | 存会话骨架（布局+文字、非进程） |
| `Ctrl+A Ctrl+R` | 手动恢复会话骨架（其实下次启动 tmux 已自动恢复，此键备用） |
| `Ctrl+A I` | 补装插件 (setup.sh 已自动装；仅装不全时兜底，大写 I 是 TPM 硬编码) |

### tmux 自带默认键（没写进配置、出厂就有）

下面这些没写进 `tmux.conf`，但 tmux 默认就绑了、本配置也没动，直接能用。

| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A z` | 当前 pane 全屏放大 / 还原（最常用之一，看长输出时很顺手） |
| `Ctrl+A x` | 关掉当前 pane（会先让你确认 y/n） |
| `Ctrl+A n` / `p` | 下一个 / 上一个窗口（补 `1-9` 直接跳之外的顺序切换） |
| `Ctrl+A l` | 跳回上一个用过的窗口（来回切两个；去掉 hjkl 后这个默认键回来了） |
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

> 前提是**别关机、别 `wsl --shutdown`**——任务不丢靠的是进程在后台真还跑着（detach），不是会话保存插件。机器真重启了，进程就结束了，插件也只找回布局、不会让命令续跑。

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
