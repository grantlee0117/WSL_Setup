# WSL 侧网络接入（备用：手动代理 · DNS · 排错）

本机用 Amnezia 全局 TUN（网络层接管）+ WSL2 镜像模式：WSL 与 Windows 共用网卡和路由，流量自动经隧道出网。实测（2026-06）DNS、SSH、curl 全部开箱即用，**WSL 侧无需任何代理或 DNS 配置**（WireGuard、OpenVPN、Tailscale Exit Node 等全局 VPN / TUN 级工具同理）。

所以本文是**备用手册**——只有改回 Clash 这类「需在 WSL 内手动配代理」的工具时才用得上。先跑下面四条自检，全过就保持现状、整篇跳过：

> 前置（仅手动配代理时）：先完成 [2-wsl](../2-wsl/README.md) 的 WSL2 安装与 §2.1 `wsl.conf`。

```bash
getent hosts github.com
curl -I https://www.google.com
curl -I https://github.com
sudo apt update
```

四条都正常 = WSL 流量已走全局隧道，此时再去配 Clash 风格的 `127.0.0.1:7897` 反而会引入错误。

只有以下情况才需要继续往下配：

- **`curl` / `apt` 直连失败，但 Windows 浏览器正常**：检查 Amnezia 是否启用了全局模式、是否把 WSL/Hyper-V/vEthernet 流量排除在隧道之外——这是 Amnezia 全局模式下 WSL 不通最常见的根因。
- **Amnezia 提供了本地 HTTP/SOCKS 代理端口，且你明确想让命令行工具走它**：按它的实际端口，参照下面「一」配 `http_proxy` 和 apt 代理。
- **`getent hosts github.com` 失败**：优先检查 [2-wsl §2.1](../2-wsl/README.md) 的 `wsl.conf` 和 `/etc/resolv.conf`，不要先配代理。

## 一、WSL 侧代理与 DNS（仅手动代理工具需要）

本节做两件事：手动配代理 + 验证网络，末尾附 DNS 原理说明。

### 代理配置（仅"系统代理、未开全局 TUN"时需要）

虽然 `.wslconfig` 配了 `autoProxy`，但 `apt`、`curl`、`git SSH` 等不会自动读系统代理，需手动配。

> **二选一，别叠加**：若已开**全局 TUN**（Amnezia，或 Clash 的 TUN 模式），网络层已兜底接管所有流量，本节整块跳过——这是本机主线。只有用**系统代理、没开 TUN** 时才往下配。（Clash 用户若常开关 TUN，可顺手配上做备份，但非必需。）

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

> **大多数情况下不需要这步**。DNS 修好后直连就行，只有直连 github.com:22 被网络阻断时才需要。**注意**：如果你用的是**全局 TUN 模式**的梯子（流量已在网络层被接管），这条 ProxyCommand 反而会把 SSH 强行塞进可能不存在的本地代理端口，导致连接失败——这种情况**不要配**，直连即可。

**④ Tailscale 用户（如果你装了 Tailscale）**

Tailscale 的 MagicDNS 会覆盖 `/etc/resolv.conf`，把 DNS 指向 `100.100.100.100`，导致 [2-wsl §2.1.2](../2-wsl/README.md) boot command 写入的正确 DNS 被改掉。必须禁止它。📋 执行：

```bash
sudo tailscale set --accept-dns=false
```

> 没装 Tailscale 的跳过这步。

### 验证网络

代理和 DNS 全部配置完毕，现在集中验证。以下命令**逐条执行**：

```bash
# 1. 检查 DNS 配置文件内容
cat /etc/resolv.conf
# 手动兜底模式：应为 nameserver 223.5.5.5 / 8.8.8.8 两行
# 基线模式（Amnezia/镜像，未手动接管）：为 nameserver 10.255.255.254，同样正常
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

> **如果验证不通过**：先在 PowerShell 中 `wsl --shutdown` 重启（让 boot command 重新执行），再检查。详见下方「二、网络健康检查」和「三、网络故障排查 FAQ」。

**代理覆盖范围总结**：

> 本节（手动配代理）只适用于一种情况：**Windows 侧用的是系统代理、没有全局 TUN**。此时 `apt`、`curl`/`wget`、`git SSH` 不会自动走代理，需按上面 ①②③ 手动配；没手动配的程序则走直连，**这种场景下没有"全局兜底"**。

| 配置 | 覆盖范围 |
|------|---------|
| `/etc/apt/apt.conf.d/proxy.conf` | `apt` 命令 |
| `~/.bashrc` 中的环境变量 | `curl`、`wget`、`pip`、`npm`、`docker pull` 等所有读取 `http_proxy` 的工具 |
| `~/.ssh/config` 中的 ProxyCommand | `git clone git@...` 等 SSH 连接（如已配置） |

配好以上后，后续安装的工具不需要再单独配代理。

### DNS 原理说明（可跳过，排错时再看）

> 这部分解释 [2-wsl §2.1.2](../2-wsl/README.md) 的 boot command 的解决思路和原理。如果你的网络验证全部通过，可以跳过。
>
> 本机现状：`generateResolvConf=true`、`resolv.conf` 为 WSL 自动生成的 `nameserver 10.255.255.254`（虚拟网关），DNS 仍正常——查询经共用网卡走 Amnezia 隧道解析。下面这套 boot command 是 Clash 时代的兜底方案，仅在镜像模式下 DNS 确实失效时才需要；下表中「不经过 Clash 通常不能」的判断也只适用于 Clash 场景。

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

**[2-wsl §2.1.2](../2-wsl/README.md) 的 boot command 做了什么**：

1. `rm -f /etc/resolv.conf` — 断开可能存在的 symlink（指向 `/run/systemd/resolve/stub-resolv.conf`）。**必须先断开 symlink**：如果直接 `printf > /etc/resolv.conf`，实际修改的是 symlink 的目标文件，systemd-resolved 重启后会覆盖回 `127.0.0.53`
2. `printf 'nameserver 223.5.5.5\n...' > /etc/resolv.conf` — 写入正确的公共 DNS
3. 配合 `generateResolvConf=false` — 阻止 WSL 覆盖

这三者协同工作，确保每次 WSL 启动后 DNS 都指向正确的地址。

---

## 二、网络健康检查（一键诊断）

DNS 和代理问题反复出现时，用以下命令一键定位。📋 整块复制粘贴到 WSL 终端执行：

```bash
echo "=== WSL 网络健康检查 ==="
echo ""

# 总判定：DNS 能否解析（这才是健康与否的根本标准）
if getent hosts github.com >/dev/null 2>&1; then DNS_OK=1; else DNS_OK=0; fi
NS=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | head -1 | awk '{print $2}')

echo "--- 1. DNS 解析（总判定）---"
if [ "$DNS_OK" = 1 ]; then
  echo "OK: github.com → $(getent hosts github.com | awk '{print $1}')"
else
  echo "!! PROBLEM: getent hosts github.com 失败 — 下面各项用于定位原因"
fi
echo ""

echo "--- 2. /etc/resolv.conf 形态与 DNS 模式 ---"
if [ -L /etc/resolv.conf ]; then
  echo "INFO: symlink → $(readlink -f /etc/resolv.conf)；nameserver=$NS"
else
  echo "INFO: 普通文件；nameserver=$NS"
fi
case "$NS" in
  10.255.255.254)
    if [ "$DNS_OK" = 1 ]; then
      echo "  → 基线模式：镜像+dnsTunneling 的隧道 DNS；解析正常即健康，无需 boot command、不要设 generateResolvConf=false"
    else
      echo "  → 隧道 DNS 没解析成功：按 2-wsl §2.1.2 手动接管（写 223.5.5.5/8.8.8.8 + generateResolvConf=false）"
    fi ;;
  223.5.5.5|8.8.8.8|8.8.4.4|1.1.1.1)
    echo "  → 手动兜底模式（公共 DNS）" ;;
  127.0.0.53)
    if [ "$DNS_OK" = 1 ]; then echo "  → systemd-resolved stub，解析正常即可"; else echo "  → systemd-resolved stub 且解析失败：按 §2.1.2 手动接管 DNS"; fi ;;
  100.100.100.100)
    echo "  → Tailscale MagicDNS；如解析异常：sudo tailscale set --accept-dns=false" ;;
  "")
    echo "  → 未读到 nameserver" ;;
  *)
    echo "  → 非预期 DNS：$NS" ;;
esac
echo ""

echo "--- 3. SSH 连接 ---"
SSH_RESULT=$(ssh -T -o ConnectTimeout=5 git@github.com 2>&1)
if echo "$SSH_RESULT" | grep -q "successfully authenticated"; then
  echo "OK: $SSH_RESULT"
elif echo "$SSH_RESULT" | grep -q "name resolution"; then
  echo "!! PROBLEM: DNS 解析失败 — 先按第 1/2 项修 DNS"
elif echo "$SSH_RESULT" | grep -q "Connection timed out\|Connection refused"; then
  echo "!! PROBLEM: 连接超时/被拒 — 可能需要 SSH ProxyCommand"
else
  echo "?? OTHER: $SSH_RESULT"
fi
echo ""

echo "--- 4. HTTP 代理（仅手动代理用户关心）---"
if [ -n "$http_proxy" ]; then
  echo "OK: http_proxy=$http_proxy"
else
  echo "INFO: http_proxy 未设置（Amnezia 全局 / 不用代理时这是正常的）"
fi
echo ""

echo "--- 5. wsl.conf DNS 模式 ---"
if grep -q 'generateResolvConf=false' /etc/wsl.conf 2>/dev/null; then
  echo "INFO: 手动兜底模式（generateResolvConf=false）"
  if grep -q 'rm -f /etc/resolv.conf' /etc/wsl.conf 2>/dev/null; then
    echo "  OK: boot command 含 rm -f"
  else
    echo "  !! 注意: 设了 false 但 boot command 缺 rm -f，symlink 重启后可能恢复"
  fi
else
  echo "INFO: 基线模式（generateResolvConf=true 或默认，由 WSL 自动生成 resolv.conf）"
  echo "  → 基线模式无需 boot command；只要第 1 项解析 OK 即健康"
fi
echo ""
echo "=== 检查完毕：以第 1 项「DNS 解析」为准；基线模式与手动兜底模式都算正常 ==="
```

判定以第 1 项「DNS 解析」为准：显示 `OK` 即网络健康。第 2/5 项的 `INFO` 只是表明当前处于哪种 DNS 模式（基线 / 手动兜底），两种都正常。只有出现 `!! PROBLEM` 才需要按其后的指引处理。

---

## 三、网络故障排查 FAQ

### Q：启动 WSL 时提示"检测到 localhost 代理配置，但未镜像到 WSL"

`.wslconfig` 中的 `networkingMode=mirrored` 没生效。在 PowerShell 中执行 `wsl --shutdown` 后重新进入。

---

### Q：`apt update` 超时（Connection timed out）

apt 没走代理。检查 `/etc/apt/apt.conf.d/proxy.conf` 是否正确配置了代理地址和端口。

---

### Q：安装过程中某个包下载失败（502 Bad Gateway）

代理临时抽风。已下载的不会重复下载，在原命令后面加 `--fix-missing` 重试即可。例如 `sudo apt install -y --fix-missing texlive-full`。

---

### Q：`git clone git@github.com:...` 超时或报 DNS 错误，但 `git clone https://...` 正常？

先区分是 DNS 问题还是连通性问题。如果报 `Temporary failure in name resolution`，是 DNS 坏了（见上方「一、WSL 侧代理与 DNS · DNS 原理说明」）。如果 DNS 正常但连接超时，说明直连 github.com:22 被阻断，需要在 `~/.ssh/config` 里配 ProxyCommand（见上方「一、WSL 侧代理与 DNS · ③ Git SSH 代理」）。`http_proxy` 只对 HTTP/HTTPS 协议生效，SSH 不读这个变量。

---

### Q：关掉 Clash 后所有命令都报代理错误？

因为代理写在了 `~/.bashrc` 和 apt 配置里。临时关闭代理可以执行 `unset http_proxy https_proxy all_proxy`，但下次开终端又会恢复。如果要永久去掉，需要编辑 `~/.bashrc` 和 `/etc/apt/apt.conf.d/proxy.conf` 删除相关行。

---

### Q：DNS 突然不通了（之前一直好好的）？

终极排查流程（下面针对**手动兜底模式**；若你是**基线模式**——`resolv.conf` 为指向 `10.255.255.254` 的软链、平时靠隧道解析——突然不通多半是 Windows 侧 VPN / Clash 状态变了，先 `wsl --shutdown` 重启或查 Windows 侧网络，**不要**改成公共 DNS）：

```bash
# 1. 检查 resolv.conf 有没有被覆盖
cat /etc/resolv.conf
# 手动兜底模式：应为 nameserver 223.5.5.5 / 8.8.8.8 两行（基线模式是 10.255.255.254，也正常）

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

---

### Q：Claude Code 能正常使用，但 `git push git@github.com` 报 DNS 解析失败？

两者走的网络路径不同：

| 工具 | 协议 | DNS 解析在哪里 | 是否依赖 resolv.conf |
|------|------|-------------|:---:|
| Claude Code / curl | HTTPS → `http_proxy` | 代理端（Windows 侧） | 否 |
| git push git@ | SSH | WSL 系统 DNS | **是** |

**解法**：修好 resolv.conf 即可（见上一个 Q）。DNS 修好后 SSH 直连 github.com 正常工作，不需要额外配置 SSH ProxyCommand。

**误区**：以为要给 SSH 配 ProxyCommand 走代理。实际上 DNS 修好后直连就行；很多代理（含 Clash autoProxy）还不支持 CONNECT 到 22 端口（会报 `Connection closed by UNKNOWN port 65535`）。ProxyCommand 只在直连 github.com:22 被网络阻断时才需要——**DNS 修好是根本解法，ProxyCommand 是绕路。**

---

### Q：在 Windows 里切换了 Clash 的代理模式后，WSL 的 DNS 突然不通了？

`wsl --shutdown` 重启即可恢复（boot command 会重新写入正确 DNS）。

---

### Q：为什么用 `getent hosts` 而不是 `nslookup` 验证 DNS？

`nslookup` 属于 `dnsutils` 包，WSL 最小安装中默认不存在。`getent hosts` 是系统自带的，且直接使用系统 DNS 配置（`/etc/resolv.conf`），验证结果更准确。本文全程使用 `getent hosts`。
