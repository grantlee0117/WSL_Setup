# WSL2 安装与配置

> **适用场景**：一台全新 Windows 电脑，从零安装并配置 WSL2。
> 基于实际配置经验整理，适用于 Windows 11 + Ubuntu 24.04 (Noble)。
>
> **前置条件**：请先完成 [1-windows](../1-windows/README.md) 中的 Windows 基础配置（Git、SSH Key、代理工具等）。

**这份文档做什么**：在 Windows 上安装 WSL2，配好 `wsl.conf`、systemd、DNS / 网络等基础。装完之后，开发环境（编程语言、命令行工具、Docker 等）见 👉 [4-dev](../4-dev/README.md)。

**预估耗时**：WSL 安装 + 内部配置约 15–30 分钟、占用 ~2 GB。

**关于代码块的执行方式**：

本文中主要操作的代码块都会标注执行方式，一共三种情况（条件性的排障 / FAQ 代码块按上下文判断）：

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
# 资源分配：下面三个值是 48GB+ 内存机型的示例，请按你的内存档位改（见下方建议表）：
#   16GB 内存 → memory=8GB、processors=4-6
#   32GB 内存 → memory=16GB、processors=8
#   48GB+ 内存 → 即下面的默认值
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
| `networkingMode=mirrored` | WSL 复用宿主机网络栈，宿主机上工作在网络层的代理（Amnezia / Clash 的 TUN 模式等）自动对 WSL 生效 |
| `dnsTunneling=true` | DNS 请求通过 Windows 隧道解析。镜像模式下这通常已让 WSL 的 DNS 开箱即用；§2.1.2 写死公共 DNS 的 boot command 只是它失效时的兜底（二选一，不是叠加保险） |
| `firewall=true` | 让 Windows 防火墙规则（含 Hyper-V 流量专用规则）对 WSL 网络流量生效 |
| `autoProxy=true` | 向 WSL 注入 Windows 的 HTTP(S) 代理设置；但很多命令行工具（`apt`/`curl`/`git`）并不读它、仍需手动配置，详见 [3-network/wsl-network.md](../3-network/wsl-network.md) |

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
> **多发行版注意**：`.wslconfig` 是全局配置（对所有 WSL 发行版生效），但后续 §2.1 的 `wsl.conf`（含 DNS 相关配置）是**每个发行版独立的**。如果你装了多个 WSL 发行版（如 Ubuntu + Debian），每个都需要单独配置。

### 1.2 安装 WSL2

**第一步：安装**

以**管理员身份**打开 PowerShell，📋 执行：

```powershell
wsl --install -d Ubuntu-24.04
```

> **这条命令做了什么**：
> 1. 启用 WSL 功能和虚拟机平台
> 2. 安装 WSL2 内核
> 3. 安装 Ubuntu 24.04 发行版

**第二步：重启**

按提示**重启电脑**（首次启用 WSL / 虚拟化平台需要重启；若系统未提示重启，可直接继续）。

**第三步：初始化并验证**

重启后会自动弹出 Ubuntu 窗口（若没弹出，从开始菜单打开 Ubuntu，或在 PowerShell 里运行 `wsl`），按提示**设置 Linux 用户名和密码**。进入 Linux 提示符后，📋 验证版本：

```bash
cat /etc/os-release   # 看到 VERSION_ID="24.04" 即成功，进入第二节
```

> **设置用户名密码时注意**：
> - 这是 Linux 系统的账号，和 Windows 账户无关
> - 密码输入时屏幕不显示任何字符（包括星号），这是 Linux 的安全设计，不是卡住，输完回车即可
> - 用户名用小写英文、不要空格

正常情况到这里 WSL2 就装好了。下面两条为**两种特殊情况**：

> **① `wsl --install` 只显示帮助文本，或卡在 `0.0%` / Microsoft Store 下载异常**：说明 WSL 入口已存在但还没装发行版，或 WSL 需要更新。依次尝试：
>
> ```powershell
> wsl --list --online                            # 确认列表里有 Ubuntu-24.04
> wsl --update --web-download                     # 列表里没有 24.04 时，先更新 WSL
> wsl --install --web-download -d Ubuntu-24.04    # 卡在 0.0% / Store 异常时，绕开 Store 下载
> ```
>
> 若更新后仍没有 `Ubuntu-24.04`，可先装列表里的 `Ubuntu`，进系统用 `cat /etc/os-release` 看版本；若不是 24.04，再从 Microsoft Store 安装 `Ubuntu 24.04 LTS`。

> **② 进系统后版本不是 24.04（例如弹出的是 26.04）**：后续 [4-dev](../4-dev/README.md) 的 Docker、第三方 apt 源、依赖验证都以 Ubuntu 24.04 为基准，建议装回 24.04（刚初始化的系统没有重要数据，可放心重来）。退出当前发行版，在 PowerShell 重装并清理多余发行版：
>
> ```bash
> exit
> ```
>
> ```powershell
> wsl --install -d Ubuntu-24.04        # 安装 24.04
> wsl --list --verbose                 # 确认 24.04 已就绪，并看清多余发行版的名字
> wsl --unregister Ubuntu              # 删掉多余的发行版（会清空其所有文件，确认无数据再删）
> wsl --set-default Ubuntu-24.04       # 设为默认
> ```

---

## 二、WSL2 内部配置

从这里开始，所有操作都在 WSL 终端里。打开方式有两种：

- **方式一**：打开 PowerShell，输入 `wsl` 回车
- **方式二**：在开始菜单中找到 **Ubuntu 24.04** 应用，点击打开（别点通用的 Ubuntu 应用，否则可能多注册一个发行版，见 §三）

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

> **提示**：编辑器底部会显示快捷键提示，`^O` 表示 `Ctrl+O`，`^X` 表示 `Ctrl+X`。若 `Ctrl+End` 在你的终端跳不到文件末尾，用 nano 原生的 `Alt+/`（按 `Esc` 再按 `/` 也等效）。

### 2.1 配置 wsl.conf

📋 编辑配置文件：

```bash
sudo nano /etc/wsl.conf
```

> **提示**：`sudo` 会要求输入密码，就是 §1.2 设置的那个 Linux 密码。密码同样不会显示任何字符。

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

[automount]
enabled=true
options="metadata,umask=22,fmask=11"

[interop]
enabled=true
appendWindowsPath=true

[network]
generateHosts=true
generateResolvConf=true
```

3. **保存退出**：按 `Ctrl+O` 然后按回车保存，按 `Ctrl+X` 退出编辑器。

> **关于 DNS——取决于你 Windows 侧的代理方案**：
>
> 上面这套基线（`generateResolvConf=true`、不写死 DNS）针对的是**全局 TUN 接管**的方案：Windows 侧跑 Amnezia、或 Clash Verge 开了 TUN 模式时，会有一个虚拟网卡在网络层接管所有出网流量（含 DNS）；WSL 镜像模式直接共享 Windows 这套网络栈，再配合 `dnsTunneling=true`（§1.1），WSL 的 DNS 经隧道地址 `10.255.255.254` 交给 Windows 解析——**开箱即用，什么都不用额外配**。本机正是这种方案。此时别再画蛇添足写死公共 DNS，那会把 DNS 从隧道里拽出来。
>
> 反过来，如果你用的是**普通系统代理**（Clash Verge 只在 Windows 设了 HTTP/SOCKS 系统代理、没开 TUN），网络层没有全局接管，WSL 的隧道 DNS 多半不通——这才需要按 §2.1.2 手动接管：加一条 `[boot] command=...` 写死公共 DNS，并把 `generateResolvConf` 设成 `false`。
>
> 拿不准属于哪种？别猜，按下面 §2.1.1 跑一条命令验证：**通了就保持基线，不通再做 §2.1.2**。两者二选一，不叠加。

**各项含义：**

| 配置项 | 作用 |
|--------|------|
| `systemd=true` | 启用 systemd 服务管理器，Docker 等服务需要它 |
| `metadata` | 让 Linux 在 `/mnt` 挂载的 Windows 文件上正确保存/识别权限位（`chmod` 生效），不致挂载后权限全是固定值 |
| `appendWindowsPath=true` | WSL 里能直接调用 Windows 程序（如 `code .` 打开 VSCode） |
| `generateHosts=true` | 让 WSL 自动生成 `/etc/hosts` |
| `generateResolvConf=true` | 让 WSL 自动生成 `/etc/resolv.conf`（默认值，写出来是为了和 §2.1.2 的 `false` 对照） |

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

#### 2.1.1 验证 DNS

重新进入 WSL 后，📋 执行：

```bash
getent hosts github.com
```

- 返回 IP（如 `20.27.177.113  github.com`）：DNS 正常，无需额外配置；开发环境搭建见 [4-dev](../4-dev/README.md)。镜像模式下正常配好的机器即为此状态——`/etc/resolv.conf` 指向 WSL 自动生成的文件，内容为 `nameserver 10.255.255.254`。
- 无输出或报错：DNS 不通，按 2.1.2 手动接管。

#### 2.1.2 手动接管 DNS（仅 2.1.1 不通过时）

典型症状：`getent hosts github.com` 无输出、`ssh -T git@github.com` 报 `Temporary failure in name resolution`，但 Windows 侧网络正常。

重新执行 `sudo nano /etc/wsl.conf`，在 `[boot]` 段增加一条 `command`，并在 `[network]` 段设置 `generateResolvConf=false`（其余不变）。📝 完整内容如下（粘贴进 nano 编辑器）：

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

`command` 在每次启动时以 root 执行：先 `rm -f /etc/resolv.conf` 断开软链接，再写入两行公共 DNS（`223.5.5.5`、`8.8.8.8`，分别是阿里和 Google 的公共 DNS）。`generateResolvConf=false` 阻止 WSL 重新生成该文件。

| 配置项 | 作用 |
|--------|------|
| `command=rm -f ... && printf ...` | 每次启动先断开 symlink 再写入公共 DNS |
| `generateResolvConf=false` | 禁止 WSL 自动生成 DNS（改由 boot command 接管）。注意：这只阻止 WSL 写入，不会删已有的 symlink（`/etc/resolv.conf` 视版本可能指向 `/mnt/wsl/resolv.conf` 或 systemd stub），所以 `rm -f` 仍必要 |

> **注意**：`[boot]` 段只能有一条 `command=`。如已有其他 boot command，用分号合并，例如：`command=rm -f /etc/resolv.conf && printf '...' > /etc/resolv.conf; /path/to/other-script`。命令较复杂时，建议把它们写进一个脚本文件、让 `command=` 只调用该脚本，避免 `&&`/`>`/`;` 混排在某些 WSL 版本里被解析出错。

修改后在 PowerShell 执行 `wsl --shutdown` 重启生效。DNS 的完整原理与排查见 [3-network/wsl-network.md](../3-network/wsl-network.md)。

### 2.2 配置代理与 DNS （非必要）

> **如果你是上文主线方案，本节直接跳过**：Windows 侧跑 Amnezia、或 Clash Verge 开了 TUN 模式做全局接管时，WSL 镜像模式已经直接共享了 Windows 的网络与代理，`apt`/`curl`/`git` 等流量都被网络层 TUN 兜底拦截，**WSL 侧不需要任何额外的代理/DNS 配置**——配好 §2.1 的 `wsl.conf` 即可；开发环境搭建见 [4-dev](../4-dev/README.md)。本机即是如此。
>
> **只有这种情况才需要往下看**：你用的是**普通系统代理**（Clash Verge 只设了 HTTP/SOCKS 系统代理、没开 TUN）。此时 `apt`、`curl`/`wget`、`git SSH` 不会自动走系统代理，要手动配。完整步骤（apt 代理 / 全局环境变量 / SSH ProxyCommand / Tailscale / 网络验证 / DNS 原理）见 👉 [3-network/wsl-network.md](../3-network/wsl-network.md)「一、WSL 侧代理与 DNS」。

---

## 三、常见问题

> 网络健康检查（一键诊断）与网络 / 代理 / DNS 故障排查都已移到 👉 [3-network/wsl-network.md](../3-network/wsl-network.md)（分别见其「二、网络健康检查」与「三、网络故障排查 FAQ」）。DNS / 代理反复出问题时去那里一键诊断；下面只保留与网络无关的常见问题。

---

### Q：`.wslconfig` 中 `autoMemoryReclaim` 或 `sparseVhd` 报"键未知"

你的 WSL 版本不支持这些实验性选项，删掉即可。

---

### Q：SSH key 的公钥和私钥是什么关系？

公钥（锁）放到 GitHub 上，私钥（钥匙）留在本地电脑。每台电脑各生成一对，把公钥都加到 GitHub 就行。私钥永远不要发给别人。

---

### Q：PowerShell 中 `curl` 提示要输入 Uri？

PowerShell 的 `curl` 是 `Invoke-WebRequest` 的别名，不是真正的 curl。用 `curl.exe` 代替。

---

### Q：修改 `.wslconfig` 后没有生效？

必须在 PowerShell 中执行 `wsl --shutdown` 完全关闭 WSL，再重新 `wsl` 进入才能生效。

---

### Q：PowerShell 中 `wsl` 正常，但开始菜单里的 Ubuntu 应用又显示 `Installing...`？

开始菜单里的通用 **Ubuntu** 应用可能会注册一个名叫 `Ubuntu` 的新发行版；如果你已经按本文安装并设定了 `Ubuntu-24.04`，再点这个应用就容易多出一个重复环境。日常建议从 PowerShell / Windows Terminal 执行 `wsl`，或明确执行：

```powershell
wsl -d Ubuntu-24.04
```

如果不小心又生成了额外的 `Ubuntu`，先确认 `Ubuntu-24.04` 仍然存在并是默认项：

```powershell
wsl --list --verbose
```

确认无误后可以删除多出来的通用 `Ubuntu`：

```powershell
wsl --terminate Ubuntu
wsl --unregister Ubuntu
wsl --set-default Ubuntu-24.04
```

`wsl --unregister Ubuntu` 会删除这个额外发行版里的所有文件；只在确认里面没有需要保留的数据时执行。

---

### Q：Linux 密码输入时屏幕没有任何反应？

这是正常的。Linux 终端输入密码时不会显示任何字符（包括星号），直接输完回车即可。
