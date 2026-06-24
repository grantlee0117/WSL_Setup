# 终端工具链速查卡

## 安装步骤

```bash
# 1. Windows 端安装 WezTerm (如果还没装)
winget install wez.wezterm --source winget

# 2. WSL 里运行配置脚本
cd ~/projects/WSL_Setup/5-terminal
chmod +x setup.sh
./setup.sh

# 3. 安装字体 (脚本会提示路径，全选 .ttf → 右键 → 为所有用户安装)
# 4. 关闭 WezTerm 重新打开
# 5. 首次进入 tmux 后按 Ctrl+A I 安装插件
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
ta nn           # 创建或 attach 到 "nn" 会话
ta nn 3         # 创建 "nn" 会话 + 3 个 pane
ta kill nn      # 关闭 "nn" 会话
ta kill-all     # 关闭所有
```

## Night-Night 典型用法

```bash
ta nn           # 开一个专属会话
nn 15 60        # 跑 Night-Night
# Ctrl+A d      # 断开去睡觉
ta nn           # 第二天回来看结果
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
