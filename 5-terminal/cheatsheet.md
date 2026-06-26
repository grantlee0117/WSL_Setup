# 终端工具链速查卡

## 安装步骤

```bash
# 1. Windows 端安装 WezTerm (如果还没装)
winget install wez.wezterm --source winget

# 2. WSL 里运行配置脚本
cd ~/projects/WSL_Setup/5-terminal
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. 安装字体 (脚本会提示路径，全选 .ttf → 右键 → 为所有用户安装)
# 4. 关闭 WezTerm 重新打开
# 5. source ~/.bashrc（或重开终端）让 shell 层生效（starship/z/Ctrl+R/别名）
#    tmux 插件、win32yank、starship 均由 setup.sh 自动装，无需手动
```

## tmux 快捷键 (前缀: Ctrl+A)

### 日常操作
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+A %` | 左右分屏 |
| `Ctrl+A "` | 上下分屏 |
| `Ctrl+A h/j/k/l` | Vim 风格切换 pane |
| `Alt+h/j/k/l` | 调整 pane 大小 (不需要前缀) |
| `Ctrl+A d` | 后台挂起 (detach) |
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

## ta 快捷命令

```bash
ta              # 列出/attach 会话
ta nn           # 创建或 attach 到 "nn" 会话（nn 只是会话名）
ta nn 3         # 创建 "nn" 会话 + 3 个 pane
ta kill nn      # 关闭 "nn" 会话
ta kill-all     # 关闭所有
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
| 右键 | 粘贴 |
