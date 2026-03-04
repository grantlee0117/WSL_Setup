# Windows 新电脑配置指南

> **适用场景**：拿到一台全新电脑（或重装系统后），从零配置 Windows 11 开发环境。
>
> **预估耗时**：30-60 分钟（取决于下载速度）。

---

## 一、获取纯净的 Windows 系统

新电脑到手后，系统通常预装了大量厂商捆绑软件。推荐先重置为纯净系统。

### 方法一：系统自带重置（推荐）

1. 按 `Win + I` 打开**设置**
2. 左侧选择**系统** → 右侧点击**恢复**
3. 找到"重置此电脑"，点击**初始化电脑**
4. 选择**删除所有内容**
5. 选择**云下载**（会从微软服务器下载最新镜像，比本地恢复更干净）
6. 按提示操作，等待完成

> **说明**：云下载需要联网，耗时取决于网速。重置后会获得一个干净的 Windows 11 系统，无任何捆绑软件。

### 方法二：远程重装服务

淘宝搜索"远程重装系统"，约 30 元，让店家装一个 Windows 11 专业版。

> **缺点**：可能自带捆绑软件。装完后建议用方法一再重置一次获得纯净系统。

---

## 二、显示器设置

按 `Win + I` → **系统** → **屏幕**。

**单显示器**：设置合适的分辨率和缩放比例即可。

**多显示器**：

1. 选择**扩展这些显示器**（两个屏幕各显示不同内容）
2. 拖动显示器图标调整排列顺序（左右位置要和实际摆放一致）
3. 点击你想作为主屏的显示器，勾选**设为主显示器**
4. 分别设置每个显示器的分辨率

---

## 三、NVIDIA 显卡设置（有 NVIDIA 显卡才需要）

桌面空白处**右键** → **显示更多选项** → **NVIDIA 控制面板**。

### 3.1 图像质量

左侧选择**通过预览调整图像设置** → 选择**使用我的优先选择，侧重于**：拖到**质量**一端。

### 3.2 首选图形处理器

左侧选择**管理 3D 设置** → **全局设置**：

- **首选图形处理器**：从"自动选择"改为**高性能 NVIDIA 处理器**
- **电源管理模式**：改为**最高性能优先**

### 3.3 PhysX 配置

左侧选择**配置 Surround、PhysX** → **PhysX 设置**：

- 处理器选择你的独立显卡（如 `NVIDIA GeForce RTX 5060 Laptop GPU`）

> **说明**：以上设置让系统默认使用独立显卡而非集成显卡，提升图形性能。笔记本用户注意这会增加功耗和发热。

---

## 四、关闭 UAC 弹窗（可选）

UAC（用户账户控制）会在安装软件、修改系统设置时弹出确认窗口。开发场景下频繁弹出较烦，可以关闭。

1. 按 `Win` 键，搜索 **UAC**
2. 点击**更改用户账户控制设置**
3. 滑块拖到最底部**从不通知**
4. 点击**确定**

> **注意**：关闭 UAC 会降低系统安全性。如果你的电脑会接触不可信的软件或网站，建议保持默认。

---

## 五、安装基础软件

以下是开发环境的基础软件，按顺序安装。

### 5.1 浏览器

下载安装 [Google Chrome](https://www.google.com/chrome/)。

> 如果无法访问 Google，先用 Edge 浏览器下载。

### 5.2 代理工具（如需科学上网）

安装 [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev/releases) 或你习惯的代理工具。

> **重要**：后续很多开发工具的下载和使用都依赖网络畅通。如果你的网络环境需要代理，务必先装好代理工具。

### 5.3 Git

下载安装 [Git for Windows](https://git-scm.com/download/win)。安装过程中一路默认即可。

安装完成后打开 **Git Bash**（不是 PowerShell），配置用户信息：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
git config --global core.autocrlf input
```

> **说明**：`core.autocrlf=input` 确保提交代码时将 Windows 的 CRLF 换行符转换为 LF，避免跨平台换行符问题。

### 5.4 配置 SSH Key

仍然在 Git Bash 中，生成密钥对：

```bash
ssh-keygen -t ed25519 -C "你的邮箱"
```

- 路径：直接回车（使用默认路径 `~/.ssh/id_ed25519`）
- 密码：直接回车（不设密码），或设一个自己记得住的

查看公钥并复制：

```bash
cat ~/.ssh/id_ed25519.pub
```

输出类似 `ssh-ed25519 AAAA......` 的一长串字符串，**完整复制**。

去 GitHub → **Settings** → **SSH and GPG keys** → **New SSH key**：

- **Title**：填一个能区分的名字，如 `Windows-我的电脑`
- **Key type**：选 `Authentication Key`
- **Key**：粘贴刚才复制的公钥

验证连接：

```bash
ssh -T git@github.com
```

首次连接会提示 `Are you sure you want to continue connecting`，输入 **yes** 回车。看到 `Hi xxx! You've successfully authenticated` 即成功。

> **SSH Key 是什么**：可以理解为一把"钥匙"（私钥，留在电脑上）和一把"锁"（公钥，放到 GitHub 上）。有了这对钥匙和锁，你的电脑就可以免密码和 GitHub 通信。每台电脑各生成一对，把公钥都加到 GitHub 即可。**私钥永远不要发给别人。**

### 5.5 VSCode

下载安装 [Visual Studio Code](https://code.visualstudio.com/)。

安装时建议勾选：

- **将"通过 Code 打开"操作添加到 Windows 资源管理器文件上下文菜单**
- **将"通过 Code 打开"操作添加到 Windows 资源管理器目录上下文菜单**
- **将 Code 注册为受支持的文件类型的编辑器**
- **添加到 PATH**

> 安装完成后，在 VSCode 的扩展商店中搜索并安装 **WSL** 扩展（由 Microsoft 发布），后续配置 WSL 时会用到。

### 5.6 微信（可选）

下载安装 [微信 for Windows](https://weixin.qq.com/)。

---

## 六、验证清单

全部安装完成后，逐项验证：

| 项目 | 验证方式 |
|------|---------|
| Chrome | 能正常打开网页 |
| 代理工具 | 能访问 Google |
| Git | Git Bash 中执行 `git --version`，显示版本号 |
| SSH Key | Git Bash 中执行 `ssh -T git@github.com`，显示认证成功 |
| VSCode | 能正常打开，左下角能看到 WSL 扩展图标 |

全部通过后，Windows 侧的基础配置就完成了。接下来请参阅 [02-wsl2-setup.md](./02-wsl2-setup.md) 配置 WSL2 开发环境。
