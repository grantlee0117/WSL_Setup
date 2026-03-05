# WSL2 完整安装配置指南

> **适用场景**：一台全新 Windows 电脑，从零开始搭建 WSL2 开发环境。
> 基于实际配置经验整理，适用于 Windows 11 + Ubuntu 24.04 (Noble)。
>
> **前置条件**：请先完成 [01-windows-setup.md](./01-windows-setup.md) 中的 Windows 基础配置（Git、SSH Key、代理工具等）。

**这份文档做什么**：

1. 在 Windows 上安装 WSL2（Linux 子系统），配好网络和代理
2. 装上 Claude Code 及其所有 skill 需要的底层依赖——WSL 默认是个极简系统，缺很多东西
3. 装上常用编程语言环境（Python、Node.js、Java、Rust、Go）
4. 装上 Codex CLI、Gemini CLI、Docker 等开发工具

**为什么要装这些底层依赖**：

Claude Code 的 skill（docx、pptx、xlsx、pdf、latex 等）在生成文件时会调用系统工具。比如 docx skill 需要 `soffice --headless` 做格式转换，pdf skill 需要 `poppler-utils` 提取文本，latex skill 需要 `xelatex` 编译。这些工具在 WSL 里默认都没有，不提前装好 skill 就会报错。

**预估耗时和空间**：

| 阶段 | 耗时（取决于网速） | 磁盘占用 |
|------|:---:|:---:|
| 一~二（WSL 安装配置） | 15-30 分钟 | ~2 GB |
| 三（依赖 + 工具） | 30-60 分钟 | ~8-10 GB |
| 其中 texlive-full | 10-20 分钟 | ~5 GB |

**风险等级说明**（第三节使用）：

| 等级 | 含义 |
|:---:|------|
| 🟢 | **无风险**：纯库/工具，不改系统配置，卸载干净 |
| 🟡 | **低风险**：会拉少量依赖，但都是成熟稳定包 |
| 🟠 | **需注意**：依赖链较长，不会破坏系统但要了解影响 |

**关于代码块的执行方式**：

本文中每个代码块都会标注执行方式，一共三种情况：

- 📋 **整块复制粘贴执行**：从第一行到最后一行全选，一次性粘贴到终端回车即可。包括：单条命令、带 `\` 续行符的多行命令、`&&` 连接的命令、多条独立命令写在同一个代码块中。
- ✂️ **逐条复制粘贴执行**：前一条命令会改变环境（如 `source ~/.bashrc`），后续命令依赖这个变更，所以必须一条一条来。文中会拆成**独立的代码块**，并明确标注"**逐条执行**"。
- 📝 **粘贴到编辑器中的配置内容**：不是在终端执行的命令，而是要粘贴到 nano、notepad 等编辑器中的文件内容。

---

## 一、WSL2 安装与全局配置

### 1.1 创建 .wslconfig（安装 WSL2 之前先配好）

> **为什么先配**：`.wslconfig` 控制 WSL2 虚拟机的资源和网络行为，装完 WSL 再改也行，但先配好可以避免首次启动时默认设置不合适。

打开 **PowerShell**（不是 Git Bash），📋 执行：

```powershell
notepad C:\Users\你的用户名\.wslconfig
```

> **注意**：把 `你的用户名` 替换成你的 Windows 用户名。不知道用户名的话，在 PowerShell 里执行 `echo $env:USERNAME` 即可查看。提示文件不存在是否新建，点"是"。

📝 写入以下内容：

```ini
[wsl2]
# 资源分配（根据你的实际内存和 CPU 调整，见下方建议）
memory=24GB
swap=8GB
processors=12

# 网络配置（镜像模式，共享宿主机网络和代理）
networkingMode=mirrored
dnsTunneling=true
firewall=true
autoProxy=true
```

保存关闭。

**各项含义：**

| 配置项 | 作用 |
|--------|------|
| `memory` | WSL2 虚拟机最大可用内存（不是硬盘空间） |
| `swap` | 交换空间大小 |
| `processors` | 分配的 CPU 核心数 |
| `networkingMode=mirrored` | WSL 共享宿主机网络，Clash 等代理自动生效 |
| `dnsTunneling=true` | DNS 请求通过 Windows 隧道，与 2.2 节的手动 DNS 修复形成双保险 |
| `firewall=true` | 启用 Hyper-V 防火墙 |
| `autoProxy=true` | 自动使用 Windows 的代理设置 |

> **资源分配建议**：
>
> | 你的电脑内存 | memory 建议 | processors 建议 |
> |:---:|:---:|:---:|
> | 16GB | 8GB | 4-6 |
> | 32GB | 16GB | 8 |
> | 48GB+ | 24GB | 12 |
>
> 原则是内存给一半，CPU 核心给一半到三分之二。如果你会同时运行 Claude Code 等 AI 工具和编译任务，建议给多一些，否则可能出现内存不足导致进程被杀。
>
> **多发行版注意**：`.wslconfig` 是全局配置（对所有 WSL 发行版生效），但后续 2.1 节的 `wsl.conf` 和 2.2 节的 DNS 修复是**每个发行版独立的**。如果你装了多个 WSL 发行版（如 Ubuntu + Debian），每个都需要单独配置。

### 1.2 安装 WSL2

PowerShell（**管理员**模式）中 📋 执行：

```powershell
wsl --install
```

> **这条命令做了什么**：
> 1. 启用 WSL 功能和虚拟机平台
> 2. 安装 WSL2 内核
> 3. 默认安装一个 Ubuntu 发行版

安装完成后**必须重启电脑**。

重启后，再次打开 PowerShell（管理员模式），📋 执行以下命令安装指定版本的 Ubuntu：

```powershell
wsl --install -d Ubuntu-24.04
```

> **为什么要再执行一次？** 第一条 `wsl --install` 主要是启用 WSL 功能和安装内核，默认安装的 Ubuntu 版本不一定是你想要的。第二条命令明确指定安装 Ubuntu 24.04（当前的 LTS 长期支持版本），确保版本可控。
>
> **版本选择**：建议安装最新的 LTS 版本。可以用 `wsl --list --online` 查看所有可安装的发行版。截至目前推荐 `Ubuntu-24.04`。

安装完成后会自动弹出 Ubuntu 窗口，要求你设置 Linux 用户名和密码。

> **注意**：
> - 这个用户名密码是 Linux 系统的，和 Windows 账户无关
> - 密码输入时屏幕不会显示任何字符（包括星号），这是 Linux 的安全设计，不是卡住了，直接输完回车即可
> - 用户名建议用小写英文，不要有空格

---

## 二、WSL2 内部配置

从这里开始，所有操作都在 WSL 终端里。打开方式有两种：

- **方式一**：打开 PowerShell，输入 `wsl` 回车
- **方式二**：在开始菜单中找到 Ubuntu 应用，点击打开

### nano 编辑器基础操作

后续多次需要用 `nano` 编辑配置文件，这里先说明基本操作（第一次用 Linux 终端编辑器的同学必看）：

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| 保存 | `Ctrl+O` 然后按回车 | 屏幕底部会显示文件名，直接回车确认 |
| 退出 | `Ctrl+X` | 如果有未保存的修改，会问你是否保存 |
| 移动光标 | 方向键 ↑↓←→ | 和普通编辑器一样 |
| 跳到文件末尾 | `Ctrl+End` | 一步到底 |
| 粘贴 | 鼠标右键 | 在终端中，右键等于粘贴（不是 Ctrl+V） |
| 全选删除 | `Ctrl+6` → `Ctrl+End` → `Ctrl+K` | 标记起点 → 跳到文末全选 → 剪切删除 |

> **提示**：编辑器底部会显示快捷键提示，`^O` 表示 `Ctrl+O`，`^X` 表示 `Ctrl+X`。

### 2.1 配置 wsl.conf

📋 编辑配置文件：

```bash
sudo nano /etc/wsl.conf
```

> **提示**：`sudo` 会要求输入密码，就是 1.2 步设置的那个 Linux 密码。密码同样不会显示任何字符。

**手把手操作步骤**：

1. **先清空旧内容**（如果文件里已经有东西）：
   - 按 `Ctrl+6`（标记选择起点）
   - 按 `Ctrl+End`（跳到文件末尾，此时从开头到末尾全部被选中）
   - 按 `Ctrl+K`（剪切/删除选中内容）
   - 现在文件应该是空的了

2. **粘贴新内容**：在 Windows 浏览器里选中下面这整段配置复制，然后回到终端窗口**鼠标右键**粘贴（📝 这是粘贴到 nano 编辑器里的内容，不是终端命令）：

```ini
[boot]
systemd=true
command=rm -f /etc/resolv.conf && printf 'nameserver 223.5.5.5\nnameserver 8.8.8.8\n' > /etc/resolv.conf

[automount]
enabled=true
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=true

[network]
generateHosts=true
generateResolvConf=false
```

3. **保存退出**：按 `Ctrl+O` 然后按回车保存，按 `Ctrl+X` 退出编辑器。

**各项含义：**

| 配置项 | 作用 |
|--------|------|
| `systemd=true` | 启用 systemd 服务管理器，Docker 等服务需要它 |
| `command=rm -f ... && printf ...` | 每次 WSL 启动时自动写入正确的 DNS 配置（详见 2.2 节） |
| `metadata` | 让 Linux 正确处理 Windows 文件权限，SSH key 不会报权限错误 |
| `appendWindowsPath=true` | WSL 里能直接调用 Windows 程序（如 `code .` 打开 VSCode） |
| `generateResolvConf=false` | 禁止 WSL 自动生成 DNS 配置（由 boot command 接管） |

> **注意**：`[boot]` 段只能有一条 `command=`。如果你已经有其他 boot command，用分号合并，例如：`command=rm -f /etc/resolv.conf && printf '...' > /etc/resolv.conf; /path/to/other-script`

退出并重启 WSL 使配置生效。以下三条命令 ✂️ **逐条执行**（先退出 WSL，再在 PowerShell 中关闭，最后重新进入）：

```bash
exit
```

```powershell
wsl --shutdown
```

```powershell
wsl
```

### 2.2 配置代理与 DNS

> **好消息**：如果你按 2.1 节配了 `wsl.conf`（包含 boot command 和 `generateResolvConf=false`），DNS 的核心修复**已经完成了**。每次 WSL 启动时，boot command 会自动写入正确的 DNS 配置。

本节做两件事：**配置代理**（让各种工具都能科学上网）和**验证网络**。最后附有 DNS 原理说明供了解。

#### 代理配置（使用 Clash 等代理工具的用户）

如果你不用代理，可以跳过这整个"代理配置"部分，直接看后面的"验证"。

虽然 `.wslconfig` 里配了 `autoProxy`，但很多 Linux 命令行工具并不会自动读取系统代理设置，需要手动配置。如果 Windows 侧 Clash 开了 **TUN 模式**，TUN 会在网络层兜底拦截所有流量，但下面的配置仍然建议做——这样即使关了 TUN 模式，工具也能正常走代理，形成双保险。

**① apt 代理**

> **apt 是什么？** apt 是 Ubuntu 的包管理器，相当于手机上的"应用商店"。后续所有 `sudo apt install xxx` 命令都通过它下载软件。apt 有自己独立的代理配置，不读 `http_proxy` 环境变量，所以必须单独配。

📋 执行：

```bash
sudo nano /etc/apt/apt.conf.d/proxy.conf
```

📝 写入以下两行（端口改成你的 Clash 端口，常见的是 7890 或 7897）：

```
Acquire::http::Proxy "http://127.0.0.1:7897";
Acquire::https::Proxy "http://127.0.0.1:7897";
```

`Ctrl+O` 回车保存，`Ctrl+X` 退出。

**② 全局代理（让 curl、wget、pip、npm、docker pull 等命令行工具都走代理）**

📋 以下 5 行整块复制粘贴执行：

```bash
echo 'export http_proxy=http://127.0.0.1:7897' >> ~/.bashrc
echo 'export https_proxy=http://127.0.0.1:7897' >> ~/.bashrc
echo 'export all_proxy=http://127.0.0.1:7897' >> ~/.bashrc
echo 'export no_proxy=localhost,127.0.0.1' >> ~/.bashrc
source ~/.bashrc
```

> **注意**：`7897` 是 Clash Verge 的默认代理端口，根据你实际使用的代理工具修改。

**③ Git SSH 代理（可选）**

上面的 `http_proxy` 环境变量只对 HTTP/HTTPS 协议生效。如果 `git clone git@github.com:...` 仍然很慢或超时（说明你的网络直连 github.com:22 被阻断），需要给 SSH 单独配代理。📋 以下整块复制粘贴执行：

```bash
mkdir -p ~/.ssh
cat >> ~/.ssh/config << 'EOF'
Host github.com
    ProxyCommand nc -X connect -x 127.0.0.1:7897 %h %p
EOF
chmod 600 ~/.ssh/config
```

> **大多数情况下不需要这步**。DNS 修好后直连就行，只有直连 github.com:22 被网络阻断时才需要。

**④ Tailscale 用户（如果你装了 Tailscale）**

Tailscale 的 MagicDNS 会覆盖 `/etc/resolv.conf`，把 DNS 指向 `100.100.100.100`，导致 2.1 节 boot command 写入的正确 DNS 被改掉。必须禁止它。📋 执行：

```bash
sudo tailscale set --accept-dns=false
```

> 没装 Tailscale 的跳过这步。

#### 验证网络

代理和 DNS 全部配置完毕，现在集中验证。以下命令**逐条执行**：

```bash
# 1. 检查 DNS 配置文件内容
cat /etc/resolv.conf
# 应该只有两行：nameserver 223.5.5.5 和 nameserver 8.8.8.8
```

```bash
# 2. 检查 DNS 解析是否正常
getent hosts github.com
# 应返回 IP 地址
```

```bash
# 3. 检查代理是否生效（需要代理的用户）
curl -I https://www.google.com
# 看到 HTTP/2 200 即成功
```

```bash
# 4. 检查 apt 是否能正常更新
sudo apt update
# 应该能正常获取软件包列表，没有超时报错
```

> **如果验证不通过**：先在 PowerShell 中 `wsl --shutdown` 重启（让 boot command 重新执行），再检查。详见第五节"网络健康检查"和第六节"常见问题"。

**代理覆盖范围总结**：

本文的代理配置思路很简单：`apt`、`curl`/`wget`、`git SSH` 这几个系统级工具不会自动读取系统代理，所以手动给它们单独配上；其余所有程序的流量，通过镜像模式（`networkingMode=mirrored`）走 Windows 网络栈，被 Windows 侧 Clash 的 TUN 模式在网络层统一拦截（前提是 Windows 侧开启了 Clash TUN 模式）。

| 配置 | 覆盖范围 |
|------|---------|
| `/etc/apt/apt.conf.d/proxy.conf` | `apt` 命令 |
| `~/.bashrc` 中的环境变量 | `curl`、`wget`、`pip`、`npm`、`docker pull` 等所有读取 `http_proxy` 的工具 |
| `~/.ssh/config` 中的 ProxyCommand | `git clone git@...` 等 SSH 连接（如已配置） |
| Windows 侧 TUN 模式（如开启） | 兜底拦截所有未被上述覆盖的流量 |

至此代理已全部配好，后续安装的工具不需要再单独配代理。

#### DNS 原理说明（可跳过，排错时再看）

> 这部分解释为什么 2.1 节的 boot command 是必要的。如果你的网络验证全部通过了，可以直接跳到第三节。

镜像模式下 WSL 的 DNS 可能不通（无论是否使用代理）。症状：`getent hosts github.com` 无返回、`ssh -T git@github.com` 报 `Temporary failure in name resolution`，但 Windows 侧一切正常。

**根因**：`/etc/resolv.conf` 这个文件决定了 WSL 里的程序去问谁解析域名。问题是有多个"写手"会争抢这个文件：

| 写手 | 写入内容 | 能不能解析 |
|------|---------|-----------|
| systemd-resolved | `nameserver 127.0.0.53`（本地 stub） | 镜像模式下通常不能 |
| WSL 自动生成 | `nameserver 10.255.255.254`（虚拟网关） | 不经过 Clash，通常不能 |
| Tailscale | `nameserver 100.100.100.100`（MagicDNS） | 不经过 Clash，通常不能 |
| boot command 手动写 | `nameserver 223.5.5.5`（公共 DNS） | 经过 Windows 网络栈 → 正常 |

**常见触发场景**（配好后突然又坏了）：

- **在 Windows 侧切换 Clash 模式**（规则模式 ↔ 全局模式）：改变 Clash 对 DNS 的拦截方式，可能导致 WSL 内 DNS 路径断裂
- **WSL 重启**后 Tailscale 或 WSL 重新覆盖 `resolv.conf`
- **Tailscale 更新或重启**后重新接管 DNS

**2.1 节的 boot command 做了什么**：

1. `rm -f /etc/resolv.conf` — 断开可能存在的 symlink（指向 systemd-resolved 的 stub 文件）
2. `printf 'nameserver 223.5.5.5\n...' > /etc/resolv.conf` — 写入正确的公共 DNS
3. 配合 `generateResolvConf=false` — 阻止 WSL 覆盖

这三者协同工作，确保每次 WSL 启动后 DNS 都指向正确的地址。

---

## 三、WSL2 开发环境搭建

> **安装顺序说明**：以下按依赖关系和风险从低到高排列。每一步标注了风险等级，先装最安全的，有争议的放到最后"按需再加"。
>
> **如果安装中途某个包下载失败**（常见报错：`502 Bad Gateway`），是代理临时抽风，已下载的不会重复下载，在原命令后面加 `--fix-missing` 重试即可。例如：`sudo apt install -y --fix-missing texlive-full`

### 3.1 系统更新与基础工具

📋 整块复制粘贴执行：

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential wget
```

> **说明**：`build-essential` 包含 gcc、g++、make 等编译工具链。`wget` 是下载工具。`git`、`curl`、`unzip` 在 Ubuntu 24.04 中已预装。

### 3.2 Git 配置

WSL 和 Windows 是隔离的两个系统，需要在 WSL 里**重新配置一遍** Git。📋 以下 6 行整块复制粘贴执行：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
git config --global core.autocrlf input
git config --global init.defaultBranch main
git config --global credential.helper store
git config --global core.quotepath false
```

> 把 `你的名字` 和 `你的邮箱` 替换成你自己的即可。

### 3.3 SSH Key 配置

WSL 里需要**单独生成一对**密钥，和 Windows 侧的是独立的。📋 执行：

```bash
ssh-keygen -t ed25519 -C "你的邮箱"
```

一路回车（默认路径、不设密码）。

📋 查看公钥：

```bash
cat ~/.ssh/id_ed25519.pub
```

去 GitHub → Settings → SSH and GPG keys → New SSH key，添加这个公钥。Title 写 `WSL-你的电脑名` 方便区分。

> **说明**：GitHub 允许添加多个 SSH key。每台电脑、每个环境（Windows / WSL）各自生成各自的，把公钥都加到 GitHub 即可。

📋 验证：

```bash
ssh -T git@github.com
```

首次连接输入 **yes**，看到 `successfully authenticated` 即成功。

### 3.4 C/C++ 编译基础库 🟢 无风险

这些全是 `-dev` 包，只提供头文件（`.h`）和静态库（`.a`），对应的运行时 `.so` 是 Ubuntu 预装的。不会修改任何系统行为，不会互相冲突，卸载干净。

**为什么要装**：后续编译 Python C 扩展、Node.js 原生模块、任何开源项目时都需要这些头文件。

📋 整块复制粘贴执行（每行末尾的 `\` 是续行符，shell 会自动拼成一条命令）：

```bash
sudo apt install -y \
    libssl-dev \
    libffi-dev \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libreadline-dev \
    libncurses-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    pkgconf
```

各包说明：

| 包 | 说明 |
|---|------|
| `libssl-dev` | OpenSSL 头文件，编译任何涉及 TLS 的程序必需 |
| `libffi-dev` | 外部函数接口，Python ctypes 依赖 |
| `zlib1g-dev` | zlib 压缩，几乎所有编译都隐式依赖 |
| `libbz2-dev` / `liblzma-dev` | bzip2 / xz 压缩库，编译 Python 必需 |
| `libreadline-dev` | 行编辑库，Python / Node REPL 需要 |
| `libncurses-dev` | 终端 UI 库，htop / vim 等 TUI 的基础 |
| `libsqlite3-dev` | Python 的 `import sqlite3` 需要 |
| `libxml2-dev` / `libxslt1-dev` | XML 解析，lxml 等库编译时需要 |
| `libcurl4-openssl-dev` | curl 的开发头文件 |
| `pkgconf` | 库路径查找工具，编译时 `pkg-config --cflags/--libs` 需要 |

### 3.5 命令行工具 🟢 无风险

独立的二进制工具，互相之间无依赖关系，每个都可以单独装或卸。

**为什么要装**：Claude Code 的各个 skill 在处理文件时会调用这些工具。

📋 整块复制粘贴执行：

```bash
sudo apt install -y \
    poppler-utils \
    pandoc \
    qpdf \
    graphviz \
    ffmpeg \
    jq tree zip unzip
```

| 包 | Claude Code 怎么用它 |
|---|------|
| `poppler-utils` | pdf skill 用 `pdftoppm` 把 PDF 转图片预览，用 `pdftotext` 提取文字 |
| `pandoc` | docx skill 用它做 markdown / docx / html / latex 格式互转 |
| `qpdf` | pdf skill 用它合并、拆分、解密 PDF |
| `graphviz` | 画流程图、架构图时需要 `dot` 命令 |
| `ffmpeg` | 多媒体处理（视频转码、音频处理、截图） |
| `jq` | JSON 处理 |
| `tree` / `zip` / `unzip` | 目录展示和压缩解压 |

### 3.6 CLI 效率工具 🟢 无风险

📋 整块复制粘贴执行：

```bash
sudo apt install -y ripgrep fd-find fzf tmux htop ncdu dos2unix
```

| 包 | 说明 |
|---|------|
| `ripgrep` | 更快的 grep 替代品，Claude Code 内部也在用 |
| `fd-find` | 更快的 find 替代品 |
| `fzf` | 模糊搜索工具，配合 `Ctrl+R` 搜索命令历史 |
| `tmux` | 终端复用器，可以在一个窗口里分屏、后台运行任务。运行 Claude Code 等长时间任务时，tmux 可以防止意外断开导致任务中断 |
| `htop` | 交互式进程查看器，比 `top` 好用 |
| `ncdu` | 磁盘空间分析工具 |
| `dos2unix` | 修复 Windows/Linux 换行符差异 |

> **tmux 入门**：在终端中输入 `tmux` 进入一个新会话。`Ctrl+B` 然后按 `D` 可以离开会话（后台继续运行），`tmux attach` 重新连接。更多用法可以搜索"tmux 入门教程"。

### 3.7 Python 环境 🟡 低风险

**为什么要装**：Claude Code 的 pdf、xlsx 等 skill 的脚本是 Python 写的，需要 pip 安装依赖（如 pypdf、openpyxl）。

📋 整块复制粘贴执行：

```bash
sudo apt install -y python3 python3-pip python3-venv python3-dev
```

| 包 | 说明 |
|---|------|
| `python3` | Ubuntu 24.04 预装，这步只是确保完整 |
| `python3-pip` | pip 包管理器 |
| `python3-venv` | 虚拟环境支持 |
| `python3-dev` | Python.h 头文件，编译 C 扩展需要 |

### 3.8 Node.js 环境 🟡 低风险

**为什么要装**：Claude Code 本体不再需要 Node.js（已改为原生安装器），但 skill 中的 npm 包（pptxgenjs 做 PPT、docx-js 做 Word、pdf-lib 做 PDF）仍然需要 Node.js 运行。Codex CLI 和 Gemini CLI 也通过 npm 安装。

✂️ 以下三条命令必须**逐条复制粘贴执行**，不能一起粘贴。第一条装完 nvm 后，必须 `source ~/.bashrc` 加载 nvm，否则第三条会报 `nvm: command not found`。

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
```

```bash
source ~/.bashrc
```

```bash
nvm install --lts
```

| 工具 | 说明 |
|---|------|
| `nvm` | Node 版本管理器，装在 `~/.nvm/` 下，不碰系统目录 |
| `node` (via nvm) | 装在用户目录下，不影响系统 |

> **为什么不用 `sudo apt install nodejs`**：Ubuntu 源里的 Node.js 版本通常偏老，且会装到系统目录和 nvm 冲突。用 nvm 管理是业界标准做法。

### 3.9 Java 环境 🟡 低风险

**为什么要装**：很多工具链（如 Gradle、Maven、部分 IDE 功能）依赖 JDK。LibreOffice 也会拉入 OpenJDK，但这里显式安装确保版本可控。

📋 执行：

```bash
sudo apt install -y default-jdk
```

📋 验证（整块粘贴执行）：

```bash
java --version
javac --version
```

> **说明**：`default-jdk` 在 Ubuntu 24.04 上安装 OpenJDK 21。如果需要其他版本（如 JDK 17），可以用 `sudo apt install openjdk-17-jdk`。

### 3.10 Rust 环境 🟡 低风险

**为什么要装**：很多现代 CLI 工具（如 ripgrep、fd、bat）和系统工具都用 Rust 编写。部分 Python 包（如 pydantic-core）也需要 Rust 编译。

✂️ 以下命令**逐条复制粘贴执行**：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

安装过程中会提示选择安装方式，直接回车选择默认（选项 1）。

```bash
source "$HOME/.cargo/env"
```

📋 验证（整块粘贴执行）：

```bash
rustc --version
cargo --version
```

> **说明**：Rust 通过 rustup 安装，所有文件在 `~/.rustup/` 和 `~/.cargo/` 下，不碰系统目录，卸载只需 `rustup self uninstall`。

### 3.11 Go 环境 🟡 低风险

**为什么要装**：很多云原生工具（如 Docker、Kubernetes 相关工具）和开发工具用 Go 编写。

✂️ 以下命令**逐条复制粘贴执行**：

```bash
curl -fsSL https://go.dev/dl/go1.24.1.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -
```

```bash
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc && source ~/.bashrc
```

📋 验证：

```bash
go version
```

> **说明**：Go 官方推荐的安装方式。所有文件在 `/usr/local/go/` 下，升级时下载新版本覆盖即可。`$HOME/go/bin` 是 `go install` 安装的工具的路径。
>
> **版本号**：上面的 `go1.24.1` 是示例版本号，安装前建议去 [Go 官网](https://go.dev/dl/) 查看最新版本号并替换。

### 3.12 Tesseract OCR 🟡 低风险（可选）

**为什么要装**：Claude Code 的 pdf skill 处理扫描件 PDF 时需要 OCR 识别文字。如果你不处理扫描件，可以跳过。

📋 整块复制粘贴执行：

```bash
sudo apt install -y tesseract-ocr tesseract-ocr-chi-sim tesseract-ocr-chi-tra
```

> `chi-sim` 和 `chi-tra` 分别是简体和繁体中文的 OCR 训练模型，纯数据文件。

### 3.13 LibreOffice 🟠 需注意

**为什么要装**：Claude Code 的 docx / pptx / xlsx skill 都依赖 `soffice --headless` 做格式转换（比如 docx → PDF），没有替代品。

📋 整块复制粘贴执行：

```bash
sudo apt install -y libreoffice-core libreoffice-writer libreoffice-impress libreoffice-calc
```

> **为什么标 🟠**：
> - 依赖链约 300-500MB，会拉入 Java 运行时（OpenJDK）和 GTK 图形库
> - 但这些依赖不会破坏系统，只是体积大
> - 如果 3.9 已装了 JDK，不会重复安装
>
> **风险是"需要知道"而非"会出问题"**。

### 3.14 TeX Live 🟠 需注意

**为什么要装**：latex-document-writer skill 需要 `xelatex` 编译 LaTeX 文档（支持中文排版）。

📋 执行（安装需要 10-20 分钟，耐心等待）：

```bash
sudo apt install -y texlive-full
```

> **为什么标 🟠**：
> - 约 5GB，安装需要 10-20 分钟，是整个流程中最大的一个包
> - 但隔离性非常好，所有文件都在 `/usr/share/texlive/` 下，不修改系统配置
> - 装完后 `xelatex`、`latexmk`、ctex 宏包、TikZ、listings、所有字体全部就位，不需要任何后续配置
> - 如果后续想用 [TeX Live 官方安装器](https://tug.org/texlive/) 替代 apt 版本，需要先 `apt remove texlive-*`，两者不能共存
>
> **如果想节省空间**，可以用精简版（约 1.5-2GB）：
> ```bash
> sudo apt install -y texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra texlive-lang-chinese texlive-xetex texlive-science texlive-pictures latexmk
> ```

### 3.15 Claude Code 安装

> **来源**：[官方文档](https://claude.ai/docs/claude-code)
>
> npm 安装方式（`npm install -g @anthropic-ai/claude-code`）已被官方弃用。以下是当前官方推荐的原生安装方式，会自动后台更新。

✂️ 以下命令**逐条复制粘贴执行**：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

> **说明**：第二条是将安装路径加入 PATH。安装脚本把二进制文件放在 `~/.local/bin/claude`，但该路径默认不在 PATH 里，不加这步会报 `command not found`。

📋 验证：

```bash
claude --version
```

📋 安装沙盒依赖（Claude Code 使用 bubblewrap 实现 OS 级沙盒隔离）：

```bash
sudo apt install -y bubblewrap socat
```

> **说明**：bubblewrap + socat 是 Claude Code 沙盒功能的必要依赖。

### 3.16 OpenAI Codex CLI 安装

> **来源**：[官方 GitHub](https://github.com/openai/codex) / [官方文档](https://developers.openai.com/codex/cli/)
>
> Codex CLI 是 OpenAI 的终端编程代理。需要 ChatGPT Plus/Pro/Team 账号或 OpenAI API Key。

📋 执行：

```bash
npm i -g @openai/codex
```

📋 验证：

```bash
codex --version
```

### 3.17 Google Gemini CLI 安装

> **来源**：[官方 GitHub](https://github.com/google-gemini/gemini-cli) / [官方文档](https://geminicli.com/docs/get-started/installation/)
>
> Gemini CLI 是 Google 的开源终端 AI 代理（Apache 2.0）。需要 Google API Key 或 Gemini Code Assist 许可证。

📋 执行：

```bash
npm i -g @google/gemini-cli
```

> **说明**：首次运行需要配置认证。最简单的方式是去 [Google AI Studio](https://aistudio.google.com/apikey) 申请免费 API Key，然后设置环境变量：
>
> ```bash
> echo 'export GOOGLE_API_KEY="你的API Key"' >> ~/.bashrc && source ~/.bashrc
> ```

📋 验证：

```bash
gemini --version
```

### 3.18 Docker Engine 安装

> **来源**：[Docker 官方文档](https://docs.docker.com/engine/install/ubuntu/)
>
> 这里装的是 Docker Engine（纯命令行），不是 Docker Desktop。无商业许可限制。

**第一步：添加 Docker 官方 apt 源**

📋 以下整块复制粘贴执行：

```bash
# 安装前置依赖
sudo apt install -y ca-certificates curl

# 添加 Docker 官方 GPG 密钥
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 添加 Docker apt 源
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**第二步：安装 Docker Engine**

📋 整块复制粘贴执行：

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**第三步：免 sudo 使用 Docker**

📋 执行：

```bash
sudo usermod -aG docker $USER
```

> **注意**：执行后需要**重启 WSL** 才能生效。方法：输入 `exit` 退出，然后在 PowerShell 里执行 `wsl --shutdown`，再重新 `wsl` 进入。不重启的话 `docker` 命令仍然需要加 `sudo`。

📋 验证（整块粘贴执行）：

```bash
docker --version
docker compose version
docker run --rm hello-world
```

> 看到 `Hello from Docker!` 即表示安装成功。

### 3.19 暂不安装（按需再加）

以下工具根据实际需要再装，这里只记录命令备用：

**嵌入式交叉编译**（STM32 开发）🟡：
```bash
sudo apt install -y gcc-arm-none-eabi binutils-arm-none-eabi \
    libnewlib-arm-none-eabi openocd minicom picocom
# 注意：WSL2 连 USB 设备需要 Windows 侧装 usbipd-win
```

**网络调试工具** 🟡：
```bash
sudo apt install -y net-tools dnsutils nmap tcpdump socat netcat-openbsd mtr-tiny
```

**编译调试** 🟡：
```bash
sudo apt install -y cmake ninja-build gdb valgrind strace ccache
```

**明确不装的**：

| 包 | 原因 |
|---|------|
| `imagemagick` | 安全策略（`/etc/ImageMagick-6/policy.xml`）会和 ghostscript 冲突，限制 PDF 处理能力。用 poppler + ffmpeg 可覆盖绝大部分图片处理需求 |
| `wireshark` / `wireshark-common` | 会拉大量 Qt/GTK GUI 依赖到 WSL 里，污染系统。命令行抓包用 `tcpdump` 即可 |
| `yq` | Ubuntu apt 源里的 yq 和 GitHub 上流行的 [mikefarah/yq](https://github.com/mikefarah/yq) 是两个完全不同的东西，API 不兼容。需要时直接下载 GitHub Release 的二进制 |

---

## 四、验证清单

全部配置完成后，逐项验证。✂️ 以下命令**逐条复制粘贴执行**（不要整块粘贴，因为有些命令需要看输出确认结果）：

```bash
# 1. 网络（验证代理或直连）
curl -I https://www.google.com

# 2. apt
sudo apt update

# 3. Git SSH
ssh -T git@github.com

# 4. systemd（Docker 等服务依赖它）
systemctl list-unit-files --type=service | head

# 5. 资源分配（确认内存和 CPU 核心数符合 .wslconfig 配置）
free -h && nproc

# 6. C/C++ 编译基础
pkg-config --cflags openssl

# 7. 命令行工具（Claude Code skill 依赖）
pdftoppm -v && pandoc --version && ffmpeg -version

# 8. Python
python3 --version && pip3 --version

# 9. Node.js
node -v && npm -v

# 10. Java
java --version

# 11. Rust
rustc --version

# 12. Go
go version

# 13. LibreOffice（docx/pptx/xlsx skill 的格式转换引擎）
soffice --version

# 14. TeX Live（latex skill 的编译器）
xelatex --version

# 15. Claude Code
claude --version

# 16. OpenAI Codex CLI
codex --version

# 17. Google Gemini CLI
gemini --version

# 18. Docker
docker --version && docker compose version
```

全部通过即表示 WSL2 环境搭建完成。

---

## 五、网络健康检查（一键诊断）

DNS 和代理问题反复出现时，用以下命令一键定位。📋 整块复制粘贴到 WSL 终端执行：

```bash
echo "=== WSL 网络健康检查 ===" && \
echo "" && \
echo "--- 1. /etc/resolv.conf ---" && \
if [ -L /etc/resolv.conf ]; then \
  echo "!! PROBLEM: /etc/resolv.conf 是 symlink → $(readlink -f /etc/resolv.conf)"; \
  echo "   修复: sudo bash -c 'rm -f /etc/resolv.conf && printf \"nameserver 223.5.5.5\nnameserver 8.8.8.8\n\" > /etc/resolv.conf'"; \
else \
  echo "OK: 普通文件（非 symlink）"; \
fi && \
echo "" && \
echo "--- 2. nameserver 内容 ---" && \
NS=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | head -1 | awk '{print $2}') && \
case "$NS" in \
  223.5.5.5|8.8.8.8|8.8.4.4|1.1.1.1) echo "OK: $NS（公共 DNS）" ;; \
  127.0.0.53) echo "!! PROBLEM: $NS（systemd-resolved stub）— boot command 未生效或缺少 rm -f" ;; \
  100.100.100.100) echo "!! PROBLEM: $NS（Tailscale MagicDNS）— 运行 sudo tailscale set --accept-dns=false" ;; \
  10.255.255.254) echo "!! PROBLEM: $NS（WSL 虚拟网关）— 检查 wsl.conf 中 generateResolvConf=false" ;; \
  *) echo "?? UNKNOWN: $NS — 不在预期列表中" ;; \
esac && \
echo "" && \
echo "--- 3. DNS 解析 ---" && \
if getent hosts github.com >/dev/null 2>&1; then \
  echo "OK: github.com → $(getent hosts github.com | awk '{print $1}')"; \
else \
  echo "!! PROBLEM: getent hosts github.com 失败"; \
fi && \
echo "" && \
echo "--- 4. SSH 连接 ---" && \
SSH_RESULT=$(ssh -T -o ConnectTimeout=5 git@github.com 2>&1) && true; \
if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then \
  echo "OK: $SSH_RESULT"; \
elif echo "$SSH_RESULT" | grep -q "name resolution"; then \
  echo "!! PROBLEM: DNS 解析失败 — 先修 resolv.conf"; \
elif echo "$SSH_RESULT" | grep -q "Connection timed out\|Connection refused"; then \
  echo "!! PROBLEM: 连接超时/被拒 — 可能需要 SSH ProxyCommand"; \
else \
  echo "?? OTHER: $SSH_RESULT"; \
fi && \
echo "" && \
echo "--- 5. HTTP 代理 ---" && \
if [ -n "$http_proxy" ]; then \
  echo "OK: http_proxy=$http_proxy"; \
else \
  echo "!! WARNING: http_proxy 未设置（如果你不用代理，这是正常的）"; \
fi && \
echo "" && \
echo "--- 6. wsl.conf 关键配置 ---" && \
if grep -q 'rm -f /etc/resolv.conf' /etc/wsl.conf 2>/dev/null; then \
  echo "OK: boot command 包含 rm -f"; \
else \
  echo "!! PROBLEM: boot command 缺少 rm -f — symlink 重启后会恢复"; \
fi && \
if grep -q 'generateResolvConf=false' /etc/wsl.conf 2>/dev/null; then \
  echo "OK: generateResolvConf=false"; \
else \
  echo "!! PROBLEM: generateResolvConf 未设为 false"; \
fi && \
echo "" && \
echo "=== 检查完毕 ==="
```

正常输出应该全是 `OK`。任何 `!! PROBLEM` 都附带了修复命令或指引。

---

## 六、常见问题

**Q：启动 WSL 时提示"检测到 localhost 代理配置，但未镜像到 WSL"**
A：`.wslconfig` 中的 `networkingMode=mirrored` 没生效。在 PowerShell 中执行 `wsl --shutdown` 后重新进入。

**Q：`apt update` 超时（Connection timed out）**
A：apt 没走代理。检查 `/etc/apt/apt.conf.d/proxy.conf` 是否正确配置了代理地址和端口。

**Q：安装过程中某个包下载失败（502 Bad Gateway）**
A：代理临时抽风。已下载的不会重复下载，在原命令后面加 `--fix-missing` 重试即可。例如 `sudo apt install -y --fix-missing texlive-full`。

**Q：`.wslconfig` 中 `autoMemoryReclaim` 或 `sparseVhd` 报"键未知"**
A：你的 WSL 版本不支持这些实验性选项，删掉即可。

**Q：SSH key 的公钥和私钥是什么关系？**
A：公钥（锁）放到 GitHub 上，私钥（钥匙）留在本地电脑。每台电脑各生成一对，把公钥都加到 GitHub 就行。私钥永远不要发给别人。

**Q：PowerShell 中 `curl` 提示要输入 Uri？**
A：PowerShell 的 `curl` 是 `Invoke-WebRequest` 的别名，不是真正的 curl。用 `curl.exe` 代替。

**Q：修改 `.wslconfig` 后没有生效？**
A：必须在 PowerShell 中执行 `wsl --shutdown` 完全关闭 WSL，再重新 `wsl` 进入才能生效。

**Q：`docker` 命令报 `permission denied`？**
A：执行 `sudo usermod -aG docker $USER` 后需要重启 WSL（`exit` → `wsl --shutdown` → `wsl`）。

**Q：Linux 密码输入时屏幕没有任何反应？**
A：这是正常的。Linux 终端输入密码时不会显示任何字符（包括星号），直接输完回车即可。

**Q：`git clone git@github.com:...` 超时或报 DNS 错误，但 `git clone https://...` 正常？**
A：先区分是 DNS 问题还是连通性问题。如果报 `Temporary failure in name resolution`，是 DNS 坏了（见 2.2 节 DNS 原理说明）。如果 DNS 正常但连接超时，说明直连 github.com:22 被阻断，需要在 `~/.ssh/config` 里配 ProxyCommand（见 2.2 节 Git SSH 代理）。`http_proxy` 只对 HTTPS 协议生效，SSH 不读这个变量。

**Q：关掉 Clash 后所有命令都报代理错误？**
A：因为代理写在了 `~/.bashrc` 和 apt 配置里。临时关闭代理可以执行 `unset http_proxy https_proxy all_proxy`，但下次开终端又会恢复。如果要永久去掉，需要编辑 `~/.bashrc` 和 `/etc/apt/apt.conf.d/proxy.conf` 删除相关行。

**Q：DNS 突然不通了（之前一直好好的）？**
A：终极排查流程：

```bash
# 1. 检查 resolv.conf 有没有被覆盖
cat /etc/resolv.conf
# 正确内容应该只有两行：nameserver 223.5.5.5 和 nameserver 8.8.8.8

# 2. 如果内容被改了，手动修复
sudo bash -c 'rm -f /etc/resolv.conf && printf "nameserver 223.5.5.5\nnameserver 8.8.8.8\n" > /etc/resolv.conf'

# 3. 验证
getent hosts github.com
```

如果 resolv.conf 内容正确但 DNS 仍然不通，在 PowerShell 中 `wsl --shutdown` 重启 WSL。boot command 会在启动时自动写回正确的 DNS 配置。

常见的覆盖者（根据 resolv.conf 内容判断）：
- `generated by tailscale` + `100.100.100.100` → 运行 `sudo tailscale set --accept-dns=false`
- `10.255.255.254` → 检查 `/etc/wsl.conf` 中 `generateResolvConf=false`
- `127.0.0.53` → `/etc/resolv.conf` 是 symlink，boot command 里缺少 `rm -f`

**Q：Claude Code 能正常使用，但 `git push git@github.com` 报 DNS 解析失败？**

A：两者走的网络路径不同：

| 工具 | 协议 | DNS 解析在哪里 | 是否依赖 resolv.conf |
|------|------|-------------|:---:|
| Claude Code / curl | HTTPS → `http_proxy` | 代理端（Windows 侧） | 否 |
| git push git@ | SSH | WSL 系统 DNS | **是** |

**解法**：修好 resolv.conf 即可（见上一个 Q）。DNS 修好后 SSH 直连 github.com 正常工作，不需要额外配置 SSH ProxyCommand。

**误区**：以为需要给 SSH 配 ProxyCommand 走代理。实际测试发现：1) 很多代理（包括 Clash 的 autoProxy）不支持 CONNECT 到端口 22（SSH），会报 `Connection closed by UNKNOWN port 65535`；2) DNS 修好后直连就行，加 ProxyCommand 反而引入不必要的复杂度。ProxyCommand 只在直连 github.com:22 被网络阻断时才需要。一句话：**DNS 修好是根本解法，ProxyCommand 是绕路方案**。

**Q：在 Windows 里切换了 Clash 的代理模式后，WSL 的 DNS 突然不通了？**
A：`wsl --shutdown` 重启即可恢复（boot command 会重新写入正确 DNS）。

**Q：为什么用 `getent hosts` 而不是 `nslookup` 验证 DNS？**
A：`nslookup` 属于 `dnsutils` 包，WSL 最小安装中默认不存在。`getent hosts` 是系统自带的，且直接使用系统 DNS 配置（`/etc/resolv.conf`），验证结果更准确。本文全程使用 `getent hosts`。
