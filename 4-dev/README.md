# WSL2 开发环境搭建

> **适用场景**：已按 [2-wsl](../2-wsl/README.md) 装好并配置好 WSL2（Ubuntu 24.04），在其基础上搭建开发环境。
>
> **前置条件**：先完成 [2-wsl](../2-wsl/README.md)（WSL2 安装、`wsl.conf`、网络），再回到本文。

**这份文档做什么**：

1. 装上 Claude Code 及其所有 skill 需要的底层依赖——WSL 默认是个极简系统，缺很多东西
2. 装上常用编程语言环境（Python、Node.js、Java、Rust、Go、C/C++）
3. 装上 Codex CLI、Gemini CLI、Docker 等开发工具
4. 补齐「运行时之上」的一层：数据库客户端、性能分析、本地 HTTPS / 环境变量、安全与质量门禁、云原生工具链（k8s / IaC），以及（可选）NVIDIA GPU / CUDA

目标是装完之后，大部分项目 clone 下来就能直接跑——把这套环境当成「基础设施」来用。

**为什么要装这些底层依赖**：

Claude Code 的 skill（docx、pptx、xlsx、pdf、latex 等）在生成文件时会调用系统工具。比如 docx skill 需要 `soffice --headless` 做格式转换，pdf skill 需要 `poppler-utils` 提取文本，latex skill 需要 `xelatex` 编译。这些工具在 WSL 里默认都没有，不提前装好 skill 就会报错。

**预估耗时和空间**：依赖 + 工具约 70–110 分钟、占用 ~10–13 GB（其中 texlive-full 约 10–20 分钟、~5 GB）。可选的 NVIDIA CUDA Toolkit 另算（约 3–4 GB）——没有 N 卡可整节跳过。

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
## 一、安装步骤

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

📋 验证（整块复制粘贴执行）：

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

**Git LFS（大文件支持）**：

很多仓库（尤其是机器学习模型、数据集、HuggingFace 上的项目）用 Git LFS 管理大文件。没装 LFS 直接 `git clone` 这类仓库，拉下来的只是几十字节的指针文本，不是真正的文件，加载时会报 `not a valid model file` 之类的错。📋 整块复制粘贴执行：

```bash
sudo apt install -y git-lfs
git lfs install
```

> **做了什么**：第一行装上 `git-lfs`；第二行 `git lfs install` 把 LFS 的钩子写进当前用户的 Git 配置（每个用户只需执行一次）。装好后 `git clone`/`git pull` 会自动处理 LFS 大文件，无需额外操作。

### 1.3 SSH Key 配置

WSL 里需要**单独生成一对**密钥，和 Windows 侧的是独立的。📋 整块复制粘贴执行：

```bash
ssh-keygen -t ed25519 -C "你的邮箱"
```

一路回车（默认路径、不设密码）。

📋 查看公钥（整块复制粘贴执行）：

```bash
cat ~/.ssh/id_ed25519.pub
```

去 GitHub → Settings → SSH and GPG keys → New SSH key，添加这个公钥。Title 写 `WSL-你的电脑名` 方便区分。

> **说明**：GitHub 允许添加多个 SSH key。每台电脑、每个环境（Windows / WSL）各自生成各自的，把公钥都加到 GitHub 即可。

📋 验证（整块复制粘贴执行）：

```bash
ssh -T git@github.com
```

首次连接输入 **yes**，看到 `successfully authenticated` 即成功。

**（可选）用这把 SSH 密钥给提交签名**：

公开仓库里，提交签名能让 GitHub 显示 **Verified** 徽章，证明这条提交确实来自你、防止他人冒用你的名字伪造提交。GitHub 支持用 SSH 密钥签名，不必再单独搞 GPG——直接复用上面这把 ed25519 即可。📋 整块复制粘贴执行：

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

> **还要做一步**：把**同一个公钥**再去 GitHub → Settings → SSH and GPG keys → New SSH key 添加一次，这次 **Key type 选 `Signing Key`**（之前 §1.3 加的那次是 `Authentication Key`，两者是分开的）。否则 GitHub 认不出签名、不会显示 Verified。

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

📋 整块复制粘贴执行：

```bash
sudo apt update && sudo apt install -y gh
```

**第三步：登录认证**

📋 整块复制粘贴执行：

```bash
gh auth login
```

按提示操作：

- 选择 **GitHub.com**
- 协议选择 **SSH**（已在 1.3 配好密钥）
- 登录方式选择 **Login with a web browser**，复制终端显示的一次性代码，在浏览器中打开链接粘贴即可

📋 验证（整块复制粘贴执行）：

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
    libhdf5-dev libsnappy-dev \
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
| `libhdf5-dev` `libsnappy-dev` | HDF5（h5py、Keras `.h5` 权重）与 Snappy（Parquet/Arrow 压缩）头文件，数据/ML 项目从源码编译常用 |
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

**性能分析与额外静态检查**：编译、调试都有了，「度量」这一环也得补上。以下都是独立工具，互不冲突、apt 一发即得。📋 整块复制粘贴执行：

```bash
sudo apt install -y \
    hyperfine heaptrack mold \
    cppcheck universal-ctags \
    linux-tools-generic
```

| 包 | 说明 |
|---|------|
| `hyperfine` | 命令行基准测试（带统计、自动预热），量「这条命令到底快了多少」的标准工具 |
| `heaptrack` | 堆内存分析器，比 valgrind 的 massif 快很多，定位内存分配热点的主力。`heaptrack_print` 可在无 GUI 下出报告 |
| `mold` | 现代超快链接器，大型 C++/Rust 项目链接比 lld 还快。编译时加 `-fuse-ld=mold` 启用 |
| `cppcheck` | C/C++ 静态分析，补充 clang-tidy 查不到的问题 |
| `universal-ctags` | 生成代码符号索引（tags），编辑器跳转定义用 |
| `linux-tools-generic` | 提供 `perf` 采样分析器（WSL2 上有坑，见下方注意） |

> **WSL2 上的 `perf` 注意**：`perf` 的包装脚本会去找「与当前内核同版本」的 perf 二进制，而 WSL2 跑的是微软定制内核（`uname -r` 形如 `6.18.x-microsoft`），apt 提供的版本号对不上，直接敲 `perf` 可能报找不到。变通：用 `ls /usr/lib/linux-tools/` 看实际装了哪个版本目录，直接调用里面的二进制（如 `/usr/lib/linux-tools/6.8.0-xx/perf record ...`），用户态采样基本可用（会有内核版本不符的警告，可忽略）。要完全严丝合缝得照微软 WSL2-Linux-Kernel 仓库的 `tools/perf` 自行编译。`cargo install flamegraph` 这类火焰图工具底层就靠 `perf`，所以先把 perf 跑通。

> **ASan/UBSan 开箱即用**：地址/未定义行为消毒器的运行时库（`libasan`/`libubsan` 等）已随 `build-essential` 和 clang 一并装好，`gcc -fsanitize=address,undefined ...` 或 clang 的同款参数直接能编能跑，不需要额外装包。

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
    tmux htop ncdu dos2unix wslu \
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
| `wslu` | WSL↔Windows 互通工具集，核心是 `wslview`：把 WSL 里要打开的链接/文件甩给 Windows 默认程序（浏览器、看图等）。见下方说明 |

> **命令名注意**：Debian/Ubuntu 为避免冲突给几个工具改了名——`fd-find` 的命令是 `fdfind`、`bat` 的命令是 `batcat`（`ripgrep`→`rg`、`git-delta`→`delta` 则是正常名）。想用惯用名 `fd`/`bat`，建个软链即可（`~/.local/bin` 已在 PATH）：
>
> ```bash
> mkdir -p ~/.local/bin
> ln -sf "$(command -v fdfind)" ~/.local/bin/fd
> ln -sf "$(command -v batcat)" ~/.local/bin/bat
> ```

> **wslview 怎么用**：装好 `wslu` 后，`wslview https://...` 用 Windows 默认浏览器打开链接，`wslview report.html` / `wslview out.pdf` 则交给 Windows 对应程序——在 WSL 里看 dev server 页面、生成的报告、PDF 都靠它。更重要的是后面 §1.16/§1.17/§1.18 装 Claude Code / Codex / Gemini 时的浏览器登录跳转，有了它就能自动开 Windows 浏览器，不必手动复制链接（§1.4 `gh auth login` 同理）。个别工具认 `$BROWSER` 环境变量，没自动弹出时设一下即可：
>
> ```bash
> grep -qF 'BROWSER=wslview' ~/.bashrc || echo 'export BROWSER=wslview' >> ~/.bashrc
> source ~/.bashrc
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

📋 安装（整块复制粘贴执行，只需一次，路径按你实际 clone 位置调整）：

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

**用 uv 加速 Python 项目（推荐）**：

`uv` 是用 Rust 写的 Python 包/环境管理器，把 `venv` + `pip` 的整套工作流包了进去，依赖解析和下载比 pip 快一到两个数量级——装 numpy/pandas/torch 这种巨型依赖时体感差距明显。它不否定上面 venv 的做法，而是上位替代（venv 的「正确性」全部保留，只是更快）。📋 用 pipx 装（整块复制粘贴执行）：

```bash
pipx install uv
```

之后项目里这样用（替代 `python3 -m venv` + `pip`）：

```bash
uv venv                                     # 建虚拟环境（默认 .venv）
source .venv/bin/activate
uv pip install numpy pandas scikit-learn    # 和 pip 用法一致，但快得多
```

> **conda/miniforge 要不要装**：日常用 uv 就够了。只有当你做地理空间（GDAL/rasterio）、RAPIDS 这类「conda 装起来明显省事」的领域时，再单独装 [miniforge](https://github.com/conda-forge/miniforge)。不建议把 conda 当默认环境管理器——它的 base 环境会抢 PATH，在 WSL 里容易和系统 Python 互相干扰。

**Jupyter / JupyterLab**：

数据/ML 离不开 notebook。JupyterLab 本身用 pipx 全局装一份即可：

```bash
pipx install jupyterlab
```

> **关键一步——注册内核（否则 notebook 里 import 不到你项目的库）**：pipx 把 JupyterLab 装在它自己的隔离环境里，notebook 默认只能 import 那个环境里的包。要在 notebook 里用上某个项目 venv 里的库（torch、pandas 等），必须在**那个 venv 里**装 `ipykernel` 并注册成一个内核：
>
> ```bash
> # 在项目的 venv 激活状态下执行（uv 项目用 `uv pip install ipykernel`）
> pip install ipykernel
> python -m ipykernel install --user --name myproj --display-name "Python (myproj)"
> ```
>
> 之后在 JupyterLab 右上角的内核选择里选 `Python (myproj)`，就能 import 该 venv 里的所有库。几乎每个人第一次都会卡在「notebook 里 import 不到自己装的库」，根因就是没注册内核。

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

**启用 pnpm / yarn（corepack）**：

现代 TypeScript/Node 项目大量用 pnpm 或 yarn（看仓库根目录有没有 `pnpm-lock.yaml` / `yarn.lock`，或 `package.json` 里的 `packageManager` 字段）。这类仓库用 `npm install` 打开会因为 lockfile 不一致、monorepo（workspace）解析失败而出错。好在 nvm 装的 Node 自带 `corepack`，启用一下就有 pnpm/yarn，不必额外装。📋 整块复制粘贴执行：

```bash
corepack enable
corepack prepare pnpm@latest --activate
corepack prepare yarn@stable --activate
```

> **做了什么**：`corepack enable` 把 `pnpm`/`yarn` 的入口软链进 PATH；后两行各自下载并激活一个版本。这是 Node 官方推荐的方式（实际版本会随项目 `packageManager` 字段自动切换）。`bun` 不归 corepack 管，需要时单独装：`curl -fsSL https://bun.sh/install | bash`。

**（按需）Playwright / Puppeteer 的浏览器依赖**：

如果你做前端、要跑 Playwright/Puppeteer 的端到端测试，无头 Chromium 需要一大堆系统共享库（libnss3、libgbm 等）。**别手动一个个装**——用官方命令让它自己解决，这样跟你装没装别的东西无关：

```bash
npx playwright install-deps      # 由官方解决所需的 apt 系统库
npx playwright install chromium  # 下载浏览器本体
```

> **为什么单独提**：这些共享库恰好也会被 §1.14 的 LibreOffice 拉进来，所以装了 LibreOffice 时 E2E「碰巧」能跑；但一旦跳过 LibreOffice，`npx playwright test` 就会报 `error while loading shared libraries: libnss3.so`。用上面的官方命令最稳妥。

### 1.10 Java 环境 🟡 低风险

**为什么要装**：Java 工具链（Maven、Gradle、部分 IDE 功能）依赖 JDK。这里显式装 JDK 和常用构建工具 Maven；LibreOffice 虽也会拉入 OpenJDK，但显式安装确保版本可控。

📋 整块复制粘贴执行：

```bash
sudo apt install -y default-jdk maven
```

📋 验证（整块复制粘贴执行）：

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

📋 验证（整块复制粘贴执行）：

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

📋 验证（整块复制粘贴执行）：

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

📋 整块复制粘贴执行（安装需要 10-20 分钟，耐心等待）：

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

📋 验证（整块复制粘贴执行）：

```bash
claude --version
```

> **首次登录**：第一次运行 `claude` 会要求登录——按提示在浏览器完成 OAuth 授权（Pro/Max 订阅）或填入 API Key 即可，之后才能正常使用。

📋 安装沙盒依赖（整块复制粘贴执行，Claude Code 使用 bubblewrap 实现 OS 级沙盒隔离）：

```bash
sudo apt install -y bubblewrap socat
```

> **说明**：bubblewrap + socat 是 Claude Code 沙盒功能的必要依赖。

### 1.17 OpenAI Codex CLI 安装

> **来源**：[官方 GitHub](https://github.com/openai/codex) / [官方文档](https://developers.openai.com/codex/cli/)
>
> Codex CLI 是 OpenAI 的终端编程代理。需要 ChatGPT Plus/Pro/Team 账号或 OpenAI API Key。

📋 整块复制粘贴执行：

```bash
npm i -g @openai/codex
```

📋 验证（整块复制粘贴执行）：

```bash
codex --version
```

> **WSL 注意**：如果 `command -v codex` 显示的是 `/mnt/c/Program Files/WindowsApps/...`，那是 Windows 侧 Codex App 暴露进 WSL PATH 的入口，不是上面这条 npm 在 WSL 里装的版本。开发请以 WSL 原生安装的为准，必要时用 `npm ls -g @openai/codex` 确认。

### 1.18 Google Gemini CLI 安装

> **来源**：[官方 GitHub](https://github.com/google-gemini/gemini-cli) / [官方文档](https://geminicli.com/docs/get-started/installation/)
>
> Gemini CLI 是 Google 的开源终端 AI 代理（Apache 2.0）。需要 Google API Key 或 Gemini Code Assist 许可证。

📋 整块复制粘贴执行：

```bash
npm i -g @google/gemini-cli
```

> **说明**：`gemini --version` 能过不代表能用——首次实际运行需要配置认证（未配会报认证失败）。最简单的方式是去 [Google AI Studio](https://aistudio.google.com/apikey) 申请免费 API Key，然后设置环境变量：
>
> ```bash
> grep -qF 'GEMINI_API_KEY' ~/.bashrc || echo 'export GEMINI_API_KEY="你的API Key"' >> ~/.bashrc
> source ~/.bashrc
> ```
>
> （`grep ... ||` 保证只在没写过时才追加，重复执行本节也不会让 `~/.bashrc` 出现重复行。）
>
> （AI Studio 申请的免费 key 对应环境变量 `GEMINI_API_KEY`；`GOOGLE_API_KEY` 是 Google Cloud 的 key，两者别混——同时设置时 `GOOGLE_API_KEY` 会优先、可能走错认证路径。）

📋 验证（整块复制粘贴执行）：

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

📋 整块复制粘贴执行：

```bash
sudo usermod -aG docker $USER
```

> **注意**：执行后需要让 docker 组生效才能免 sudo，两种方式：
> - **当前终端立即生效**：执行 `newgrp docker`（只影响当前这个 shell，适合临时验证）。
> - **彻底生效**：输入 `exit` 退出，在 PowerShell 里执行 `wsl --shutdown`，再重新 `wsl` 进入。
>
> 没生效前 `docker` 命令会报 **`permission denied`**（`Got permission denied while trying to connect to the Docker daemon socket`），得加 `sudo` 才能用。注意 `wsl --shutdown` 会关掉**所有** WSL 发行版（其它正在跑的会话也会一起断），所以只是想验证的话 `newgrp docker` 更省事。

📋 验证（整块复制粘贴执行）：

```bash
docker --version
docker compose version
docker run --rm hello-world
```

> 看到 `Hello from Docker!` 即表示安装成功。

### 1.20 数据库客户端 🟢 无风险

**为什么要装**：§1.5 装的 `libpq-dev`、`default-libmysqlclient-dev` 是**编译用的头文件**（给 psycopg2、mysqlclient 这些驱动从源码编译用），它们**不提供 `psql`/`mysql` 命令行客户端**。要连数据库看表、导出备份、跑迁移，还得单独装客户端。数据库引擎本身（postgres/mysql/redis 服务端）建议用 Docker 按项目起（版本各异、用完即弃、不污染系统），但**客户端 CLI 适合常驻**——轻量，能连任何项目、任何容器里的库。

📋 整块复制粘贴执行：

```bash
sudo apt install -y postgresql-client default-mysql-client redis-tools
```

| 包 | 提供的命令 | 说明 |
|---|------|------|
| `postgresql-client` | `psql` `pg_dump` `pg_restore` | PostgreSQL 客户端、备份/恢复 |
| `default-mysql-client` | `mysql` `mysqldump` | MySQL/MariaDB 客户端、备份（偏好 MariaDB 系可改装 `mariadb-client`） |
| `redis-tools` | `redis-cli` | Redis 客户端 |

> `sqlite3` 命令行已在 §1.7 装过；MongoDB 的 `mongosh` 不在 Ubuntu 默认源，需要时按 [MongoDB 官方文档](https://www.mongodb.com/docs/mongodb-shell/install/) 加源装 `mongodb-mongosh`，只在你用 Mongo 时才需要。

### 1.21 本地开发辅助：direnv + 本地 HTTPS 🟢 无风险

**为什么要装**：

- `direnv`：按目录自动加载/卸载环境变量。进项目目录自动 `source` 那份 `.envrc`（`DATABASE_URL`、`AWS_PROFILE`、`KUBECONFIG` 等），离开自动清空。比手动 `source .env` 安全，能避免上个项目的变量残留串味到别的项目（最典型的事故就是旧 `DATABASE_URL` 没清，往错误的库写数据）。
- `mkcert`：一条命令给 `localhost` 签发**受信任**的 HTTPS 证书。OAuth 回调、Secure Cookie、Service Worker、WebAuthn 等常常要求本地也走 HTTPS；自签证书会被浏览器一路警告，mkcert 把一个本地 CA 装进系统/浏览器信任库，签出来的证书零警告。

📋 整块复制粘贴执行：

```bash
sudo apt install -y direnv mkcert libnss3-tools
```

✂️ 启用 direnv 的 shell 钩子（**逐条执行**，第二条让钩子立即生效）：

```bash
grep -qF 'direnv hook bash' ~/.bashrc || echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
```

```bash
source ~/.bashrc
```

> **mkcert 首次使用**：先 `mkcert -install` 把本地 CA 装进信任库（`libnss3-tools` 是给 Firefox / 基于 NSS 的信任库用的），再 `mkcert localhost 127.0.0.1 ::1` 就会在当前目录生成证书和私钥，喂给你的 dev server 即可。

### 1.22 安全与质量门禁 🟡 低风险

**为什么要装**：这套环境会装多种语言、跑别人的脚本、还往**公开仓库**推代码，所以需要几件「在出问题前拦下来」的工具。`shellcheck` 走 apt，其余几个走各自官方渠道。

**第一层：apt 直装的静态检查**。📋 整块复制粘贴执行：

```bash
sudo apt install -y shellcheck
```

> `shellcheck`：Shell 脚本静态检查，揪出未加引号的变量、危险的 `rm`、漏写的 `set -euo pipefail` 等。本仓库自己的脚本（如 `4-dev/scripts/fuck-zone`）和文档里大量 `curl|bash`、`rm` 操作都值得过一遍。

**第二层：密钥泄露扫描 + 提交前门禁**（公开仓库尤其重要）：

- `gitleaks`：扫描工作区和提交历史里误提交的密钥（API key、`~/.git-credentials`、`.env`、token）。注意「有意公开分享」和「无意泄露」是两回事，gitleaks 防的是后者。
- `pre-commit`：提交前自动跑检查的框架，一份 `.pre-commit-config.yaml` 就能把 gitleaks、shellcheck、行尾/大文件检查串成提交门禁——**手动跑总会忘，钩进 commit 才算真防住**。

📋 安装（整块复制粘贴执行，gitleaks 走 Go、pre-commit 走 pipx，都复用本文已装的工具链，不引入新包管理器）：

```bash
go install github.com/gitleaks/gitleaks/v8@latest   # 装进 $HOME/go/bin（已在 PATH）
pipx install pre-commit
```

> 嫌编译慢也可直接下 [gitleaks Release](https://github.com/gitleaks/gitleaks/releases) 的二进制丢进 `~/.local/bin/`。在某个仓库启用门禁：写好 `.pre-commit-config.yaml` 后执行 `pre-commit install`。
>
> 更深的依赖/代码审计工具（`osv-scanner`、`semgrep`、`bandit`、`trufflehog`）按需再加，命令记在 §1.25；容器镜像漏洞扫描 `trivy` 在下面 §1.23 云原生那节一并装。

### 1.23 云原生工具链（Kubernetes / IaC）🟡 低风险

**为什么要装**：要碰容器编排、基础设施即代码（IaC），这一层绕不开。这些工具更新很快，apt 源里的版本往往落后，所以**优先用官方二进制/官方脚本**而非 apt。下面是「会碰云原生就装」的核心几件；特定云厂商 CLI（aws/gcloud/az）和更多周边工具按需，见 §1.25。

> 以下命令默认 x86_64（amd64）。ARM64 机器把 `amd64`/`x86_64` 相应换成 `arm64`/`aarch64`。

**Kubernetes 客户端**（kubectl + helm + kustomize）。✂️ 逐条执行：

```bash
# kubectl：官方接口总是返回当前稳定版
curl -fsSLO "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
```

```bash
# helm：官方安装脚本
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

```bash
# kustomize：kubectl 内置版本偏旧，单独装新的
curl -fsSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo mv kustomize /usr/local/bin/
```

**本地 Kubernetes 集群**（kind，基于 Docker，最适合本环境）。📋 整块复制粘贴执行：

```bash
curl -fsSLo kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
sudo install -m 0755 kind /usr/local/bin/kind && rm kind
```

> kind 用 Docker 起集群，轻量、不挑驱动，和 §1.19 的 Docker Engine 搭得最顺（minikube 的驱动选择更折腾，放 §1.25 按需）。

**IaC：OpenTofu + Ansible**。✂️ 逐条执行：

```bash
# OpenTofu（Terraform 的 MPL-2.0 开源分叉，命令是 tofu，HCL/用法兼容）
curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
bash /tmp/install-opentofu.sh --install-method standalone
```

```bash
# Ansible：用 pipx 装，不污染系统 Python（PEP 668 环境的正解）
pipx install --include-deps ansible
```

**容器供应链 / 配置安全**（trivy + sops + age）。✂️ 逐条执行：

```bash
# trivy：镜像/文件系统/IaC/密钥/SBOM 一把梭的扫描器，有官方 apt 源（用 .asc 密钥，和 §1.19 Docker 同款写法）
sudo wget -qO /usr/share/keyrings/trivy.asc https://aquasecurity.github.io/trivy-repo/deb/public.key
echo "deb [signed-by=/usr/share/keyrings/trivy.asc] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt update && sudo apt install -y trivy age
```

```bash
# sops：把 secret 加密后安全放进 Git。不在默认源，下官方二进制（版本号会过期，装前去 release 页看最新 tag，把路径和文件名里的版本号一起换掉）
curl -fsSLo sops https://github.com/getsops/sops/releases/download/v3.13.1/sops-v3.13.1.linux.amd64
sudo install -m 0755 sops /usr/local/bin/sops && rm sops
```

> `age` 是 sops 常用的加密后端，一并装上。配合 §1.21 的 `direnv`，就能做到「加密的 secret 进 Git、解密后按目录自动注入环境变量」。

### 1.24 NVIDIA GPU / CUDA（WSL2，可选）🟠 需注意

**什么时候需要**：你的机器有 NVIDIA 显卡、且要用 GPU 跑深度学习（PyTorch/TensorFlow）或 CUDA 程序。没有 N 卡、或只做 CPU 计算，整节跳过。

WSL2 用 GPU 有一套**和原生 Linux 不同的规矩**，照着来才不踩坑。

**第一步（在 Windows 侧，不是 WSL 里）**：装好 NVIDIA 显卡驱动（Game Ready 或 Studio 驱动，较新版本都自带 WSL CUDA 支持）即可。

> ⚠️ **最重要的一条**：**不要在 WSL 里再装 Linux 版 NVIDIA 驱动**（`nvidia-driver-xxx` 那种）。WSL 的 GPU 支持是 Windows 侧驱动通过 `/usr/lib/wsl/lib/` 注入 `libcuda.so` 实现的；在 WSL 里装 Linux 驱动会把它顶掉，反而用不了。WSL 里至多只需要装「CUDA Toolkit」（编译器/库，见第四步），它不含驱动。

**第二步：验证 WSL 能看到 GPU**。📋 整块复制粘贴执行：

```bash
nvidia-smi
```

能列出你的显卡型号和驱动版本就说明通了。（这条命令由 Windows 侧驱动注入，无需在 WSL 里装任何东西。）

**第三步：装框架**。最常见的是 PyTorch——**用官方 index、按 GPU 对应的 CUDA 版本装**，别裸 `pip install torch`（那样常装成 CPU 版，或装到和 GPU 不匹配的 CUDA 版本，运行时报 `no kernel image is available`）。在项目 venv 里执行：

```bash
# cu128 对应 CUDA 12.8；具体选哪个去 pytorch.org 看你显卡支持的最新版本
pip install torch --index-url https://download.pytorch.org/whl/cu128
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

最后一行打印 `True` 和你的显卡名就成功了。

> **较新的显卡要配较新的 CUDA**：太老的 PyTorch/CUDA wheel 不认新架构的卡（会 `no kernel image` 报错），所以上面 index 里的 CUDA 版本别选太低。

**第四步（仅在需要 `nvcc` 时）装 CUDA Toolkit**：自己编译 CUDA 核函数、装 flash-attention 这类要从源码编 GPU 代码的库时才需要，约 3–4 GB。📋 整块复制粘贴执行：

```bash
wget https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb && sudo apt update
sudo apt install -y cuda-toolkit-12-8
```

> ⚠️ 装的是 **`cuda-toolkit-12-8`** 而**不是 `cuda`**——后者会把 Linux 驱动一起拉进来，正是上面警告过的雷。`wsl-ubuntu` 这个源专为 WSL 准备，只给 toolkit、不给驱动。版本号（`12-8`）按你 `nvidia-smi` 显示支持的 CUDA 版本选。

### 1.25 暂不安装（按需再加）

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

**其它语言运行时** 🟡（默认只装了 Python/Node/Java/Rust/Go/C++；下面这些 apt 一发即得，用到再装）：
```bash
sudo apt install -y ruby-full        # Ruby（要多版本再用 rbenv）
sudo apt install -y php-cli          # PHP
sudo apt install -y lua5.4           # Lua
sudo apt install -y dotnet-sdk-8.0   # .NET SDK（24.04 默认源已收录，无需加微软源）
# Haskell：要最新/多版本用 ghcup（https://www.haskell.org/ghcup/）；固定版可 sudo apt install -y ghc cabal-install
# Elixir/Erlang：apt 版偏旧，最新建议 asdf/官方源；固定版可 sudo apt install -y elixir
# Zig / wasmtime / wasm-pack：不在 apt——Zig 下官方 tarball、wasmtime 用官方脚本、wasm-pack 用 cargo install
```

**C/C++ 依赖管理 / WebAssembly** 🟡：
```bash
pipx install conan        # Conan：C/C++ 包管理，CMake 集成方便
# vcpkg：git clone 后 ./bootstrap-vcpkg.sh，按用户目录管理，不走 apt
```

**API 调试补充**（HTTP 之外，复用已装的 Go/Rust，不引入新源）🟢：
```bash
go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest   # gRPC（复用 §1.12 的 Go）
cargo install websocat                                          # WebSocket（复用 §1.11 的 Rust）
```

**深入的安全审计工具** 🟡（§1.22 之外，按审计任务再装）：
```bash
pipx install semgrep      # 多语言 SAST
pipx install bandit       # Python SAST
pipx install pip-audit    # Python 依赖漏洞
go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest   # 跨语言 lockfile 漏洞扫描（v2，路径必须带 /v2，否则 @latest 只会停在旧的 v1）
# grype / syft / trufflehog：下各自 GitHub Release 二进制
```

**云厂商 CLI 与 k8s 周边** 🟡（用哪个云装哪个，别三个全装——gcloud SDK 体积超 1GB）：
```bash
# AWS CLI v2（官方 installer，不是 pip）
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscli.zip && unzip -q /tmp/awscli.zip -d /tmp && sudo /tmp/aws/install
# Azure CLI
curl -fsSL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Google Cloud SDK：见官方文档加 apt 源
# k8s 周边：k9s（集群 TUI）、minikube、skopeo（sudo apt install -y skopeo）、dive、lazydocker、hadolint —— 多为 GitHub Release 二进制
# CI 本地复现：gh extension install nektos/gh-act（本地跑 GitHub Actions，需 Docker）
```

**通用 YAML 处理**（mikefarah 版 yq）🟢：
```bash
sudo curl -fsSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
```

> 这是 [mikefarah/yq](https://github.com/mikefarah/yq)（GitHub 上流行的那个），和下面「明确不装」表里说的 apt 版 yq 不是一个东西，按上面这条下二进制即可。

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

# 7. C/C++ 编译基础（打印 OpenSSL 版本号即说明 pkgconf + 头文件都就位）
pkg-config --modversion openssl

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

# 22. Git LFS
git lfs version

# 23. Python 环境管理 uv
uv --version

# 24. Node 包管理器（corepack/pnpm）
corepack --version && pnpm --version

# 25. 数据库客户端
psql --version && mysql --version && redis-cli --version && sqlite3 --version

# 26. 性能分析工具
hyperfine --version && mold --version

# 27. 本地开发辅助
direnv --version && mkcert -CAROOT

# 28. 安全门禁
shellcheck --version && gitleaks version && pre-commit --version

# 29. Claude Code 沙盒依赖（bubblewrap）
bwrap --version

# 30. 云原生（仅当装了可选的 §1.23）
kubectl version --client && helm version && tofu --version

# 31. GPU（仅当有 N 卡、装了可选的 §1.24）
nvidia-smi
```

全部通过即表示 WSL2 环境搭建完成。带「仅当…」标注的项目（21 Tesseract、30 云原生、31 GPU）按你是否安装了对应可选章节自行取舍。
