# WSL 侧网络接入（备用：手动代理 · DNS · 排错）

当前本机的网络方案是 Amnezia 全局 TUN（网络层接管）+ WSL2 镜像模式：WSL 与 Windows 共用网卡和路由表，所有流量自动经 Amnezia 隧道出网。实测（2026-06）DNS、SSH、curl 全部开箱即用，WSL 侧不需要任何代理或 DNS 配置，与 [2-network 总览](./README.md) 的描述一致。

因此本文是备用手册：只有当你改回 Clash 等「需要在 WSL 内手动配代理」的工具时，才需要执行下面的步骤。Amnezia 方案下整篇都可以跳过。

> 前置（仅手动配代理时）：先完成 [3-wsl](../3-wsl/README.md) 的 WSL2 安装与 §2.1 `wsl.conf`。

## 一、WSL 侧代理与 DNS（仅手动代理工具需要）

本节做两件事：配置代理（apt、curl、git SSH 等不会自动读系统代理的工具需单独配）和验证网络，末尾附 DNS 原理说明。使用 Amnezia 等网络层全局接管的工具时，本节整节跳过。

### 代理配置（使用 Clash 等代理工具的用户）

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

> **大多数情况下不需要这步**。DNS 修好后直连就行，只有直连 github.com:22 被网络阻断时才需要。**注意**：如果你用的是**全局 TUN 模式**的梯子（流量已在网络层被接管），这条 ProxyCommand 反而会把 SSH 强行塞进可能不存在的本地代理端口，导致连接失败——这种情况**不要配**，直连即可。

**④ Tailscale 用户（如果你装了 Tailscale）**

Tailscale 的 MagicDNS 会覆盖 `/etc/resolv.conf`，把 DNS 指向 `100.100.100.100`，导致 [3-wsl §2.1](../3-wsl/README.md) boot command 写入的正确 DNS 被改掉。必须禁止它。📋 执行：

```bash
sudo tailscale set --accept-dns=false
```

> 没装 Tailscale 的跳过这步。

### 验证网络

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

> **如果验证不通过**：先在 PowerShell 中 `wsl --shutdown` 重启（让 boot command 重新执行），再检查。详见下方「二、网络健康检查」和「三、网络故障排查 FAQ」。

**代理覆盖范围总结**：

本文的代理配置思路很简单：`apt`、`curl`/`wget`、`git SSH` 这几个系统级工具不会自动读取系统代理，所以手动给它们单独配上；其余所有程序的流量，通过镜像模式（`networkingMode=mirrored`）走 Windows 网络栈，被 Windows 侧 Clash 的 TUN 模式在网络层统一拦截（前提是 Windows 侧开启了 Clash TUN 模式）。

| 配置 | 覆盖范围 |
|------|---------|
| `/etc/apt/apt.conf.d/proxy.conf` | `apt` 命令 |
| `~/.bashrc` 中的环境变量 | `curl`、`wget`、`pip`、`npm`、`docker pull` 等所有读取 `http_proxy` 的工具 |
| `~/.ssh/config` 中的 ProxyCommand | `git clone git@...` 等 SSH 连接（如已配置） |
| Windows 侧 TUN 模式（如开启） | 兜底拦截所有未被上述覆盖的流量 |

至此代理已全部配好，后续安装的工具不需要再单独配代理。

### DNS 原理说明（可跳过，排错时再看）

> 这部分解释 [3-wsl §2.1](../3-wsl/README.md) 的 boot command 的解决思路和原理。如果你的网络验证全部通过，可以跳过。
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

**[3-wsl §2.1](../3-wsl/README.md) 的 boot command 做了什么**：

1. `rm -f /etc/resolv.conf` — 断开可能存在的 symlink（指向 `/run/systemd/resolve/stub-resolv.conf`）。**必须先断开 symlink**：如果直接 `printf > /etc/resolv.conf`，实际修改的是 symlink 的目标文件，systemd-resolved 重启后会覆盖回 `127.0.0.53`
2. `printf 'nameserver 223.5.5.5\n...' > /etc/resolv.conf` — 写入正确的公共 DNS
3. 配合 `generateResolvConf=false` — 阻止 WSL 覆盖

这三者协同工作，确保每次 WSL 启动后 DNS 都指向正确的地址。

---

## 二、网络健康检查（一键诊断）

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

先区分是 DNS 问题还是连通性问题。如果报 `Temporary failure in name resolution`，是 DNS 坏了（见上方「一、WSL 侧代理与 DNS · DNS 原理说明」）。如果 DNS 正常但连接超时，说明直连 github.com:22 被阻断，需要在 `~/.ssh/config` 里配 ProxyCommand（见上方「一、WSL 侧代理与 DNS · ③ Git SSH 代理」）。`http_proxy` 只对 HTTPS 协议生效，SSH 不读这个变量。

---

### Q：关掉 Clash 后所有命令都报代理错误？

因为代理写在了 `~/.bashrc` 和 apt 配置里。临时关闭代理可以执行 `unset http_proxy https_proxy all_proxy`，但下次开终端又会恢复。如果要永久去掉，需要编辑 `~/.bashrc` 和 `/etc/apt/apt.conf.d/proxy.conf` 删除相关行。

---

### Q：DNS 突然不通了（之前一直好好的）？

终极排查流程：

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

---

### Q：Claude Code 能正常使用，但 `git push git@github.com` 报 DNS 解析失败？

两者走的网络路径不同：

| 工具 | 协议 | DNS 解析在哪里 | 是否依赖 resolv.conf |
|------|------|-------------|:---:|
| Claude Code / curl | HTTPS → `http_proxy` | 代理端（Windows 侧） | 否 |
| git push git@ | SSH | WSL 系统 DNS | **是** |

**解法**：修好 resolv.conf 即可（见上一个 Q）。DNS 修好后 SSH 直连 github.com 正常工作，不需要额外配置 SSH ProxyCommand。

**误区**：以为需要给 SSH 配 ProxyCommand 走代理。实际测试发现：1) 很多代理（包括 Clash 的 autoProxy）不支持 CONNECT 到端口 22（SSH），会报 `Connection closed by UNKNOWN port 65535`；2) DNS 修好后直连就行，加 ProxyCommand 反而引入不必要的复杂度。ProxyCommand 只在直连 github.com:22 被网络阻断时才需要。一句话：**DNS 修好是根本解法，ProxyCommand 是绕路方案**。

---

### Q：在 Windows 里切换了 Clash 的代理模式后，WSL 的 DNS 突然不通了？

`wsl --shutdown` 重启即可恢复（boot command 会重新写入正确 DNS）。

---

### Q：为什么用 `getent hosts` 而不是 `nslookup` 验证 DNS？

`nslookup` 属于 `dnsutils` 包，WSL 最小安装中默认不存在。`getent hosts` 是系统自带的，且直接使用系统 DNS 配置（`/etc/resolv.conf`），验证结果更准确。本文全程使用 `getent hosts`。
