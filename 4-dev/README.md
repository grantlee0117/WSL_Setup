# WSL2 开发环境搭建

> **适用场景**：已按 [2-wsl](../2-wsl/README.md) 装好并配置好 WSL2（Ubuntu 24.04），在其基础上搭建开发环境。
>
> **前置条件**：先完成 [2-wsl](../2-wsl/README.md)（WSL2 安装、`wsl.conf`、网络），再回到本文。

**这份文档做什么**：

1. 装上 Claude Code 及其所有 skill 需要的底层依赖——WSL 默认是个极简系统，缺很多东西
2. 装上常用编程语言环境（Python、Node.js、Java、Rust、Go、C/C++）
3. 装上 Codex CLI、Gemini CLI、Docker 等开发工具

**为什么要装这些底层依赖**：

Claude Code 的 skill（docx、pptx、xlsx、pdf、latex 等）在生成文件时会调用系统工具。比如 docx skill 需要 `soffice --headless` 做格式转换，pdf skill 需要 `poppler-utils` 提取文本，latex skill 需要 `xelatex` 编译。这些工具在 WSL 里默认都没有，不提前装好 skill 就会报错。

**预估耗时和空间**：依赖 + 工具约 30–60 分钟、占用 ~8–10 GB（其中 texlive-full 约 10–20 分钟、~5 GB）。

**风险等级说明**：

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
## 一、开发环境搭建

> **安装顺序说明**：以下按依赖关系和风险从低到高排列。每一步标注了风险等级，先装最安全的，有争议的放到最后"按需再加"。
>
> **如果安装中途某个包下载失败**（常见报错：`502 Bad Gateway`），是代理临时抽风，已下载的不会重复下载，在原命令后面加 `--fix-missing` 重试即可。例如：`sudo apt install -y --fix-missing texlive-full`

### 1.1 系统更新与基础工具

📋 整块复制粘贴执行：

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential wget unzip git
```

> **说明**：`build-essential` 包含 gcc、g++、make 等编译工具链。`wget` 是下载工具，`unzip` 后续部分安装脚本会用到，`git` 后续 §1.2/§1.4/§1.7 都要用（WSL 精简镜像不一定预装，这里一并装上）。`curl` 在 Ubuntu 24.04 通常已预装。

**配置中文 locale**：

WSL 默认 locale 是 `C.UTF-8`，中文内容复制粘贴容易乱码。📋 整块复制粘贴执行：

```bash
sudo apt install -y locales
sudo locale-gen zh_CN.UTF-8
grep -qF 'export LANG=zh_CN.UTF-8' ~/.bashrc || echo 'export LANG=zh_CN.UTF-8' >> ~/.bashrc
source ~/.bashrc
```

📋 验证：

```bash
echo $LANG
# 应输出 zh_CN.UTF-8
```

### 1.2 Git 配置

WSL 和 Windows 是隔离的两个系统，需要在 WSL 里**重新配置一遍** Git。📋 以下 6 行整块复制粘贴执行：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
git config --global core.autocrlf input
git config --global init.defaultBranch main
git config --global credential.helper store
git config --global core.quotepath false
```

> 把 `你的名字` 和 `你的邮箱` 替换成你自己的。`user.name` 是提交记录里显示的作者名，中/英/日/韩文都可以；`user.email` 建议填 GitHub 账号使用的邮箱。

> `credential.helper store` 会把 HTTPS 凭据明文存到 `~/.git-credentials`。本文主用 SSH（§1.3）和 `gh`（§1.4），一般用不到它；介意明文的话可改用 `credential.helper cache`（只在内存里缓存、超时即清）。

### 1.3 SSH Key 配置

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

### 1.4 GitHub CLI 🟢 无风险

**为什么要装**：`gh` 是 GitHub 官方命令行工具，可以在终端直接创建 PR、管理 Issue、查看 CI 状态等。Claude Code 执行 GitHub 相关操作时也会调用 `gh`。

**第一步：添加 GitHub CLI apt 源**

📋 整块复制粘贴执行：

```bash
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
```

**第二步：安装**

📋 执行：

```bash
sudo apt update && sudo apt install -y gh
```

**第三步：登录认证**

📋 执行：

```bash
gh auth login
```

按提示操作：

- 选择 **GitHub.com**
- 协议选择 **SSH**（已在 1.3 配好密钥）
- 登录方式选择 **Login with a web browser**，复制终端显示的一次性代码，在浏览器中打开链接粘贴即可

📋 验证：

```bash
gh auth status
```

> **说明**：`gh` 通过 apt 管理，更新只需 `sudo apt upgrade`。认证信息存在 `~/.config/gh/` 下。

### 1.5 通用 C/C++ 编译库与工具链 🟢 无风险

这些大多是 `-dev` 头文件包（外加 gfortran 编译器），不改系统行为、互不冲突、卸载干净。这里覆盖面铺得尽量广，让大部分项目的依赖都能直接从源码编译过。

**为什么要装**：后续编译 Python C 扩展、Node.js 原生模块、任何开源项目时都需要这些头文件。

📋 整块复制粘贴执行（每行末尾的 `\` 是续行符，shell 会自动拼成一条命令）：

```bash
sudo apt install -y \
    libssl-dev libffi-dev libcurl4-openssl-dev \
    zlib1g-dev libbz2-dev liblzma-dev libzstd-dev liblz4-dev libb2-dev \
    libreadline-dev libncurses-dev libpcre2-dev libyaml-dev libxml2-dev libxslt1-dev \
    libsqlite3-dev libgdbm-dev libdb-dev libpq-dev default-libmysqlclient-dev unixodbc-dev \
    libjpeg-dev libpng-dev libfreetype-dev libtiff-dev libwebp-dev \
    libgmp-dev libmpfr-dev libpcap-dev uuid-dev tk-dev \
    gfortran libopenblas-dev liblapack-dev \
    pkgconf
```

各包说明：

| 包 | 说明 |
|---|------|
| `libssl-dev` | OpenSSL 头文件，编译任何涉及 TLS 的程序必需 |
| `libffi-dev` | 外部函数接口，Python ctypes 依赖 |
| `libcurl4-openssl-dev` | curl 开发头文件 |
| `zlib1g-dev` `libbz2-dev` `liblzma-dev` `libzstd-dev` `liblz4-dev` `libb2-dev` | zlib/bzip2/xz/zstd/lz4/blake2 压缩与哈希库，编译 Python 及大量项目依赖 |
| `libreadline-dev` | 行编辑库，Python / Node REPL 需要 |
| `libncurses-dev` | 终端 UI 库，htop / vim 等 TUI 的基础 |
| `libpcre2-dev` | PCRE2 正则库，很多程序编译依赖 |
| `libyaml-dev` | YAML 解析，PyYAML 的 C 加速依赖 |
| `libxml2-dev` `libxslt1-dev` | XML 解析，lxml 等库编译需要 |
| `libsqlite3-dev` `libgdbm-dev` `libdb-dev` | SQLite / GDBM / Berkeley DB，Python `sqlite3`/`dbm` 等需要 |
| `libpq-dev` | PostgreSQL 客户端头，编译 `psycopg2` 必需 |
| `default-libmysqlclient-dev` | MySQL/MariaDB 客户端头，编译 `mysqlclient` 必需 |
| `unixodbc-dev` | ODBC 头，`pyodbc` 等通用数据库连接需要 |
| `libjpeg-dev` `libpng-dev` `libfreetype-dev` `libtiff-dev` `libwebp-dev` | 图像库头，Pillow 及图像处理库从源码编译必需 |
| `libgmp-dev` `libmpfr-dev` | 高精度整数/浮点（gmpy2、密码学、数值计算） |
| `libpcap-dev` | 抓包库头，scapy 等网络库编译需要 |
| `uuid-dev` | libuuid 头，生成 UUID 的库需要 |
| `tk-dev` | Tk 头（GUI，与 §1.8 的 `python3-tk` 配套） |
| `gfortran` `libopenblas-dev` `liblapack-dev` | Fortran 编译器 + BLAS/LAPACK，从源码编译 numpy/scipy 需要 |
| `pkgconf` | 库路径查找工具，编译时 `pkg-config --cflags/--libs` 需要 |

**构建与调试工具**：覆盖 GCC / Clang 两套编译器、CMake / Ninja / Meson / Autotools 几种构建系统，以及调试、静态分析工具。📋 整块复制粘贴执行：

```bash
sudo apt install -y \
    cmake ninja-build meson \
    clang llvm lld lldb \
    clang-format clang-tidy clangd \
    gdb valgrind strace ltrace \
    autoconf automake libtool m4 \
    ccache bear
```

| 包 | 说明 |
|---|------|
| `cmake` `ninja-build` `meson` | 主流 C/C++ 构建系统（CMake 事实标准，Ninja/Meson 现代项目常用） |
| `clang` `llvm` `lld` | LLVM/Clang 编译器与链接器（GCC 之外的另一套，不少项目指定用 clang） |
| `clang-format` `clang-tidy` `clangd` | 格式化、静态检查、`clangd` 语言服务器（IDE 补全/跳转）。`clangd` 在 24.04 是独立包，装它即可；`clang-tools` 是另一个包（提供 scan-build/clang-check 等，不含 clangd），二者可共存、互不冲突 |
| `gdb` `lldb` `valgrind` | GNU/LLVM 调试器与内存检测 |
| `strace` `ltrace` | 跟踪系统调用 / 库调用 |
| `autoconf` `automake` `libtool` `m4` | autotools，编译 `./configure` 类老项目用 |
| `ccache` | 编译缓存，重复编译大幅提速 |
| `bear` | 生成 `compile_commands.json`，喂给 clangd/IDE |

### 1.6 命令行工具 🟢 无风险

独立的二进制工具，互相之间无依赖关系，每个都可以单独装或卸。

**为什么要装**：Claude Code 的各个 skill 在处理文件时会调用这些工具。

📋 整块复制粘贴执行：

```bash
sudo apt install -y \
    poppler-utils \
    pandoc \
    qpdf \
    graphviz \
    librsvg2-bin \
    ffmpeg \
    jq tree zip unzip
```

| 包 | Claude Code 怎么用它 |
|---|------|
| `poppler-utils` | pdf skill 用 `pdftoppm` 把 PDF 转图片预览，用 `pdftotext` 提取文字 |
| `pandoc` | docx skill 用它做 markdown / docx / html / latex 格式互转 |
| `qpdf` | pdf skill 用它合并、拆分、解密 PDF |
| `graphviz` | 画流程图、架构图时需要 `dot` 命令 |
| `librsvg2-bin` | `rsvg-convert`：把 SVG 转成 PNG/PDF，处理含矢量图的文档时用 |
| `ffmpeg` | 多媒体处理（视频转码、音频处理、截图） |
| `jq` | JSON 处理 |
| `tree` / `zip` / `unzip` | 目录展示和压缩解压 |

### 1.7 CLI 效率工具 🟢 无风险

📋 整块复制粘贴执行：

```bash
sudo apt install -y \
    ripgrep fd-find fzf bat git-delta eza zoxide \
    tmux htop ncdu dos2unix \
    neovim httpie sqlite3 p7zip-full rsync pv rename
```

| 包 | 说明 |
|---|------|
| `ripgrep` | 更快的 grep 替代品（命令 `rg`），Claude Code 内部也在用 |
| `fd-find` | 更快的 find 替代品（命令 `fdfind`，见下方软链） |
| `fzf` | 模糊搜索工具，配合 `Ctrl+R` 搜索命令历史 |
| `bat` | 带语法高亮的 cat（命令 `batcat`，见下方软链） |
| `git-delta` | 更好看的 git diff / 分页器（命令 `delta`） |
| `eza` | 现代 ls 替代（图标、git 状态、树形） |
| `zoxide` | 智能 cd，按访问频率跳目录 |
| `tmux` | 终端复用器，可以在一个窗口里分屏、后台运行任务。运行 Claude Code 等长时间任务时，tmux 可以防止意外断开导致任务中断 |
| `htop` | 交互式进程查看器，比 `top` 好用 |
| `ncdu` | 磁盘空间分析工具 |
| `neovim` | 现代化的 vim（nano 之外的进阶编辑器） |
| `httpie` | 人性化 HTTP 客户端（`http GET ...`），调试 API 用 |
| `sqlite3` | SQLite 命令行（配合 §1.5 的 `libsqlite3-dev`） |
| `p7zip-full` | 7z 压缩/解压（比 zip 通用） |
| `rsync` | 高效增量文件同步 / 拷贝 |
| `pv` | 查看管道传输进度 |
| `rename` | 用正则批量重命名文件 |
| `dos2unix` | 修复 Windows/Linux 换行符差异 |

> **命令名注意**：Debian/Ubuntu 为避免冲突给几个工具改了名——`fd-find` 的命令是 `fdfind`、`bat` 的命令是 `batcat`（`ripgrep`→`rg`、`git-delta`→`delta` 则是正常名）。想用惯用名 `fd`/`bat`，建个软链即可（`~/.local/bin` 已在 PATH）：
>
> ```bash
> mkdir -p ~/.local/bin
> ln -sf "$(command -v fdfind)" ~/.local/bin/fd
> ln -sf "$(command -v batcat)" ~/.local/bin/bat
> ```

> **tmux 入门**：在终端中输入 `tmux` 进入一个新会话。原生 tmux 的前缀键是 `Ctrl+B`——按 `Ctrl+B` 再按 `D` 可以离开会话（后台继续运行），`tmux attach` 重新连接。（装了下面 [5-terminal](../5-terminal/README.md) 的配置后，前缀键会改成 `Ctrl+A`。）那套完整的 tmux + WezTerm 主题化配置（Catppuccin 配色、Vim 风格操作、会话自动保存）也在 [5-terminal](../5-terminal/README.md)。

**清理 Zone.Identifier 垃圾文件**：

从 Windows 复制或下载的文件带到 WSL 时，Windows 会给每个文件附带一个 `Zone.Identifier` 标记文件（"此文件来自互联网"的安全标记）。这些文件在 WSL 里完全没用，还会污染 `git status` 和目录结构。WSL 用户几乎必然会碰到这个问题。

本仓库 `4-dev/scripts/` 提供了 `fuck-zone` 一键清理脚本。

> **前提：先把本仓库 clone 到 WSL 里**（任意目录，下面以 `~/projects/WSL_Setup` 为例；放别处就把后面命令里的路径换成你的实际位置）。SSH 已在 §1.3 / §1.4 配好：
>
> ```bash
> mkdir -p ~/projects
> git clone git@github.com:你的GitHub账号/WSL_Setup.git ~/projects/WSL_Setup
> ```

📋 安装（只需一次，路径按你实际 clone 位置调整）：

```bash
bash ~/projects/WSL_Setup/4-dev/scripts/install-fuck-zone.sh
source ~/.bashrc
```

之后在任意目录执行 `fuck-zone` 即可扫描并清理当前目录下所有 `Zone.Identifier` 文件（会先列出找到的文件，按 Enter 确认删除）。

> **说明**：脚本安装到 `~/.local/bin/`，不需要 sudo。如果已经在本章中配置过 `PATH="$HOME/.local/bin:$PATH"`（如 1.16 Claude Code 安装），则不需要重复添加——安装脚本会自动判断 `~/.bashrc` 是否已写入，不会重复追加。

**终端环境配置（WezTerm + tmux 主题化）**：

> 完整的 WezTerm + tmux 主题化配置（Catppuccin 主题、Nerd Font 图标、tmux 会话保存/恢复、一键分屏与 Agent Team 布局、win32yank 中文剪贴板修复、ta 快捷命令、插件安装）已迁移到 👉 [5-terminal](../5-terminal/README.md)。

### 1.8 Python 环境 🟡 低风险

**为什么要装**：Claude Code 的 pdf、xlsx 等 skill 的脚本是 Python 写的，需要 pip 安装依赖（如 pypdf、openpyxl）。

📋 整块复制粘贴执行：

```bash
sudo apt install -y python3 python3-pip python3-venv python3-dev pipx python3-tk ipython3 python-is-python3
```

| 包 | 说明 |
|---|------|
| `python3` | Ubuntu 24.04 预装，这步只是确保完整 |
| `python3-pip` | pip 包管理器 |
| `python3-venv` | 虚拟环境支持 |
| `python3-dev` | Python.h 头文件，编译 C 扩展需要 |
| `python-is-python3` | 让 `python` 指向 `python3`（很多脚本/教程直接调 `python`，不装会 not found） |
| `pipx` | 隔离安装 Python 命令行应用（24.04 的推荐方式，见下方） |
| `python3-tk` | tkinter 运行模块（matplotlib 弹窗、GUI 脚本需要） |
| `ipython3` | 增强版交互式 Python shell |

> **Ubuntu 24.04 的 `pip install` 限制（重要）**：系统 Python 受 PEP 668 保护，直接 `pip3 install xxx` 会报 `error: externally-managed-environment`。正确做法二选一：
> - 装**命令行工具**（ruff、httpie、awscli 等要全局用的）→ 用 `pipx install xxx`，自动隔离、不污染系统。
> - 做**项目开发** → 进项目目录建虚拟环境：`python3 -m venv .venv && source .venv/bin/activate`，之后 `pip install` 一切照常。
>
> （实在要系统级强装可加 `pip3 install --break-system-packages xxx`，但不推荐。）

### 1.9 Node.js 环境 🟡 低风险

**为什么要装**：Claude Code 本体不再需要 Node.js（已改为原生安装器），但 skill 中的 npm 包（pptxgenjs 做 PPT、docx 做 Word、pdf-lib 做 PDF）仍然需要 Node.js 运行。Codex CLI 和 Gemini CLI 也通过 npm 安装。

✂️ 以下三条命令必须**逐条复制粘贴执行**，不能一起粘贴。第一条装完 nvm 后，必须 `source ~/.bashrc` 加载 nvm，否则第三条会报 `nvm: command not found`。

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
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
>
> **版本号**：上面的 `v0.40.5` 为写文档时的 nvm 版本，安装前可去 [nvm releases](https://github.com/nvm-sh/nvm/releases) 查看最新 tag 替换。

### 1.10 Java 环境 🟡 低风险

**为什么要装**：Java 工具链（Maven、Gradle、部分 IDE 功能）依赖 JDK。这里显式装 JDK 和常用构建工具 Maven；LibreOffice 虽也会拉入 OpenJDK，但显式安装确保版本可控。

📋 执行：

```bash
sudo apt install -y default-jdk maven
```

📋 验证（整块粘贴执行）：

```bash
java --version
javac --version
mvn -version
```

> **说明**：`default-jdk` 在 Ubuntu 24.04 上安装 OpenJDK 21；需要其他版本（如 JDK 17）用 `sudo apt install openjdk-17-jdk`。`maven` 是常用的 Java 构建工具，apt 版（3.8.x）可用。
>
> **Gradle 不要用 apt 装**：apt 里的 Gradle 是 4.x（2017 年的老版本），跑不了现代项目。用项目自带的 `./gradlew`（wrapper，自动下载匹配版本），或用 [sdkman](https://sdkman.io/) 装最新：`sdk install gradle`。

### 1.11 Rust 环境 🟡 低风险

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

### 1.12 Go 环境 🟡 低风险

**为什么要装**：很多云原生工具（如 Docker、Kubernetes 相关工具）和开发工具用 Go 编写。

✂️ 以下命令**逐条复制粘贴执行**。⚠️ **先去 [Go 官网下载页](https://go.dev/dl/) 看一眼当前最新版本号**，把下面命令里的 `go1.26.4` 换成它——版本号会过期，写了不存在的版本会直接 404；ARM64 的 Windows/WSL 还要把 `linux-amd64` 换成 `linux-arm64`：

```bash
curl -fL# https://go.dev/dl/go1.26.4.linux-amd64.tar.gz | sudo tar -C /usr/local -xzf -
```

> 这个包约 150MB+，命令里的 `-#` 会显示进度条；慢网 / 走隧道时下载较久，**进度条走完才算完成**（别因为屏幕没动静就以为卡死）。

```bash
grep -qF '/usr/local/go/bin' ~/.bashrc || echo 'export PATH=/usr/local/go/bin:$HOME/go/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

📋 验证：

```bash
go version
```

> **说明**：Go 官方推荐的安装方式。所有文件在 `/usr/local/go/` 下；升级时官方要求先 `sudo rm -rf /usr/local/go` 再解压新版本（直接往旧目录上覆盖解压会损坏安装）。`$HOME/go/bin` 是 `go install` 安装的工具的路径。
>
> **如果执行 `go version` 报 `Permission denied`**：检查 `/usr/local/go/bin/go` 的权限，正常应允许普通用户执行。如果异常变成 `-rwx------ root root`，执行 `sudo chmod 755 /usr/local/go/bin/go` 后重新验证。
>
> **不建议用 apt 的 `golang-go`**：它落后官方好几个版本（如本文写时 apt 是 1.22、官方已 1.26），还会把 `go` 放到 `/usr/bin/go` 抢占（即便上面 PATH 已前置也是徒增混乱）。要用官方版就别装它；若之前装过，先 `sudo apt remove golang-go` 再按本节走。

**（可选）装常用 Go 开发工具**（语言服务器 + 调试器，装进 `$HOME/go/bin`）。📋 整块复制粘贴执行：

```bash
go install golang.org/x/tools/gopls@latest          # gopls：语言服务器，IDE 补全/跳转/诊断
go install github.com/go-delve/delve/cmd/dlv@latest  # dlv：delve 调试器
```

> 这俩会用 `go install` 静默拉一堆依赖（和上面下载 Go 一样走隧道、无进度），等一两分钟很正常，别以为卡住。

### 1.13 Tesseract OCR 🟡 低风险（可选）

**为什么要装**：Claude Code 的 pdf skill 处理扫描件 PDF 时需要 OCR 识别文字。如果你不处理扫描件，可以跳过。

📋 整块复制粘贴执行：

```bash
sudo apt install -y tesseract-ocr tesseract-ocr-eng tesseract-ocr-osd tesseract-ocr-chi-sim tesseract-ocr-chi-tra
```

> `eng`/`chi-sim`/`chi-tra` 分别是英文/简体/繁体中文训练模型，`osd` 是页面方向与脚本检测（识别扫描件是否旋转）——都是纯数据文件。需要其他语言再按需加，如 `tesseract-ocr-jpn`（日）、`tesseract-ocr-kor`（韩）。

### 1.14 LibreOffice 🟠 需注意

**为什么要装**：Claude Code 的 docx / pptx / xlsx skill 都依赖 `soffice --headless` 做格式转换（比如 docx → PDF），没有替代品。

📋 整块复制粘贴执行：

```bash
sudo apt install -y libreoffice-core libreoffice-writer libreoffice-impress libreoffice-calc fonts-noto-cjk fonts-noto-color-emoji
```

> **中文文档必须装 CJK 字体**：`soffice` 把含中文的 docx/pptx 转 PDF 时，系统若没 CJK 字体，中文会渲染成方块（`□□□`）。`fonts-noto-cjk` 正是解决这个的；`fonts-noto-color-emoji` 让文档里的 emoji 也正常显示。这套字体对 §1.15 的 xelatex 中文排版同样有益。

> **为什么标 🟠**：
> - 依赖链约 300-500MB，会拉入 Java 运行时（OpenJDK）和 GTK 图形库
> - 但这些依赖不会破坏系统，只是体积大
> - 如果 1.10 已装了 JDK，不会重复安装
>
> **风险是"需要知道"而非"会出问题"**。

### 1.15 TeX Live 🟠 需注意

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

### 1.16 Claude Code 安装

> **来源**：[官方文档](https://docs.claude.com/en/docs/claude-code)
>
> 官方现以**原生安装器**为推荐方式（自动后台更新）；npm 安装（`npm install -g @anthropic-ai/claude-code`）仍可用，但已不再是默认推荐。下面用原生安装器。

✂️ 以下命令**逐条复制粘贴执行**：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

```bash
grep -qF 'HOME/.local/bin' ~/.bashrc || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

> **说明**：第二步把安装路径加入 PATH——安装脚本把二进制放在 `~/.local/bin/claude`，该路径默认不在 PATH 里，不加会报 `command not found`。`grep ... ||` 的写法保证只在没写过时才追加：如果 §1.7 fuck-zone 已经写过这行 PATH，这里会自动跳过，不会让 `~/.bashrc` 出现重复行。

📋 验证：

```bash
claude --version
```

> **首次登录**：第一次运行 `claude` 会要求登录——按提示在浏览器完成 OAuth 授权（Pro/Max 订阅）或填入 API Key 即可，之后才能正常使用。

📋 安装沙盒依赖（Claude Code 使用 bubblewrap 实现 OS 级沙盒隔离）：

```bash
sudo apt install -y bubblewrap socat
```

> **说明**：bubblewrap + socat 是 Claude Code 沙盒功能的必要依赖。

### 1.17 OpenAI Codex CLI 安装

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

> **WSL 注意**：如果 `command -v codex` 显示的是 `/mnt/c/Program Files/WindowsApps/...`，那是 Windows 侧 Codex App 暴露进 WSL PATH 的入口，不是上面这条 npm 在 WSL 里装的版本。开发请以 WSL 原生安装的为准，必要时用 `npm ls -g @openai/codex` 确认。

### 1.18 Google Gemini CLI 安装

> **来源**：[官方 GitHub](https://github.com/google-gemini/gemini-cli) / [官方文档](https://geminicli.com/docs/get-started/installation/)
>
> Gemini CLI 是 Google 的开源终端 AI 代理（Apache 2.0）。需要 Google API Key 或 Gemini Code Assist 许可证。

📋 执行：

```bash
npm i -g @google/gemini-cli
```

> **说明**：`gemini --version` 能过不代表能用——首次实际运行需要配置认证（未配会报认证失败）。最简单的方式是去 [Google AI Studio](https://aistudio.google.com/apikey) 申请免费 API Key，然后设置环境变量：
>
> ```bash
> echo 'export GEMINI_API_KEY="你的API Key"' >> ~/.bashrc && source ~/.bashrc
> ```
>
> （AI Studio 申请的免费 key 对应环境变量 `GEMINI_API_KEY`；`GOOGLE_API_KEY` 是 Google Cloud 的 key，两者别混——同时设置时 `GOOGLE_API_KEY` 会优先、可能走错认证路径。）

📋 验证：

```bash
gemini --version
```

### 1.19 Docker Engine 安装

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

### 1.20 暂不安装（按需再加）

以下工具根据实际需要再装，这里只记录命令备用：

**嵌入式交叉编译 / 烧录调试** 🟡：
```bash
# ARM（STM32 等）：交叉工具链 + C/C++ 库 + 调试 + 烧录
sudo apt install -y gcc-arm-none-eabi binutils-arm-none-eabi \
    libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib \
    gdb-multiarch openocd stlink-tools dfu-util srecord
# AVR（Arduino / ATmega 等）
sudo apt install -y gcc-avr avr-libc avrdude
# 串口终端 + USB 直通依赖
sudo apt install -y minicom picocom screen libusb-1.0-0-dev
# 注意：WSL2 连 USB/串口设备需要 Windows 侧装 usbipd-win，再 usbipd attach 透传进 WSL
```

**网络调试工具** 🟡：
```bash
sudo apt install -y net-tools dnsutils nmap tcpdump socat netcat-openbsd mtr-tiny
```


**明确不装的**：

| 包 | 原因 |
|---|------|
| `imagemagick` | 安全策略（`/etc/ImageMagick-6/policy.xml`）会和 ghostscript 冲突，限制 PDF 处理能力。用 poppler + ffmpeg 可覆盖绝大部分图片处理需求 |
| `wireshark` / `wireshark-common` | 会拉大量 Qt/GTK GUI 依赖到 WSL 里，污染系统。命令行抓包用 `tcpdump` 即可 |
| `yq` | Ubuntu apt 源里的 yq 和 GitHub 上流行的 [mikefarah/yq](https://github.com/mikefarah/yq) 是两个完全不同的东西，API 不兼容。需要时直接下载 GitHub Release 的二进制 |

---

## 二、验证清单

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

# 6. GitHub CLI
gh --version

# 7. C/C++ 编译基础
pkg-config --cflags openssl

# 8. 命令行工具（Claude Code skill 依赖）
pdftoppm -v && pandoc --version && ffmpeg -version

# 9. Python
python3 --version && pip3 --version

# 10. Node.js
node -v && npm -v

# 11. Java
java --version

# 12. Rust
rustc --version

# 13. Go
go version

# 14. LibreOffice（docx/pptx/xlsx skill 的格式转换引擎）
soffice --version

# 15. TeX Live（latex skill 的编译器）
xelatex --version

# 16. Claude Code
claude --version

# 17. OpenAI Codex CLI
codex --version

# 18. Google Gemini CLI
gemini --version

# 19. Docker
docker --version && docker compose version

# 20. 中文 locale
echo $LANG   # 应为 zh_CN.UTF-8

# 21. Tesseract OCR（仅当装了可选的 §1.13）
tesseract --version
```

全部通过即表示 WSL2 环境搭建完成（第 21 项 Tesseract 若未装 §1.13 可忽略）。
