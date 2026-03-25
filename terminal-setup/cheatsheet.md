# 终端工具链速查卡

## 安装步骤

```bash
# 1. Windows 端安装 WezTerm (如果还没装)
winget install wez.wezterm --source winget

# 2. WSL 里运行配置脚本
cd ~/terminal-setup
chmod +x setup.sh
./setup.sh

# 3. 安装字体 (脚本会提示路径，全选 .ttf → 右键 → 为所有用户安装)
# 4. 关闭 WezTerm 重新打开
# 5. 首次进入 tmux 后按 Ctrl+B I 安装插件
```

## tmux 快捷键 (前缀: Ctrl+B)

### 日常操作
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+B %` | 左右分屏 |
| `Ctrl+B "` | 上下分屏 |
| `Ctrl+B h/j/k/l` | Vim 风格切换 pane |
| `Ctrl+B H/J/K/L` | 调整 pane 大小 |
| `Ctrl+B d` | 后台挂起 (detach) |
| `Ctrl+B c` | 新窗口 |
| `Ctrl+B 1-9` | 切换窗口 |
| `Ctrl+B r` | 重载配置 |
| `Ctrl+B Enter` | 进入复制模式 (vi 键位) |

### Agent Team 布局
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+B A` | 三格布局 (1 大 + 2 小) |
| `Ctrl+B Q` | 田字格 (4 等分) |

### 会话保存/恢复
| 快捷键 | 功能 |
|--------|------|
| `Ctrl+B Ctrl+S` | 保存 session |
| `Ctrl+B Ctrl+R` | 恢复 session |
| `Ctrl+B I` | 安装插件 (首次需要) |

## ta 快捷命令

```bash
ta              # 列出/attach 会话
ta nn           # 创建或 attach 到 "nn" 会话
ta nn 3         # 创建 "nn" 会话 + 3 个 pane
ta kill nn      # 关闭 "nn" 会话
ta kill-all     # 关闭所有
```

## Night-Night 典型用法

```bash
ta nn           # 开一个专属会话
nn 15 60        # 跑 Night-Night
# Ctrl+B d      # 断开去睡觉
ta nn           # 第二天回来看结果
```

## Agent Team 监控

```bash
ta agents 4     # 开一个 4-pane 布局
# 或进入 tmux 后按 Ctrl+B Q 创建田字格
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
