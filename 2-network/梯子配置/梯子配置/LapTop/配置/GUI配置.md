# Clash Verge Rev 链式代理配置 — 迁移说明

> 最后更新：2025-03-10

## 文件清单

| 文件 | 用途 |
|------|------|
| **Script.js** | 全局扩展脚本：节点、策略组、规则、DNS、Sniffer |
| **Merge.yaml** | 全局扩展配置：端口、TUN、性能参数 |
| **verge.yaml** | Clash Verge 应用设置：主题、快捷键、TUN开关等 |

---

## 新电脑迁移步骤

### 第 1 步：安装 Clash Verge Rev + 导入机场订阅

### 第 2 步：放入配置文件

- `Merge.yaml` → 全局扩展配置（类型选「Merge」）
- `Script.js` → 全局扩展脚本（类型选「Script」）
- `verge.yaml` → 替换 `C:\Users\<用户名>\.config\clash-verge-rev\verge.yaml`

### 第 3 步：修改 GUI 的 DNS 覆写（必须手动做）

打开 Clash Verge → DNS 覆写 → 高级模式，改 **4 个字段**：

**① 域名服务器** — 清空，填：

```
https://1.1.1.1/dns-query, https://8.8.8.8/dns-query
```

**② 回退服务器** — 清空，填：

```
https://1.1.1.1/dns-query, https://dns.google/dns-query, https://9.9.9.9/dns-query
```

**③ Fake IP 过滤** — 清空，填：

```
*.lan, *.local, *.arpa, time.*.com, ntp.*.com, time.*.com, +.market.xiaomi.com, localhost.ptlogin2.qq.com, *.msftncsi.com, www.msftconnecttest.com, +.wegame.com.cn, +.wegame.com, +.tgp.qq.com, +.pvp.net, +.riotgames.com, +.valorant.com, +.tencentgames.com
```

**④ 域名服务器策略** — 清空，填：

```
+.arpa=10.0.0.1, geosite:cn=https://doh.pub/dns-query;https://dns.alidns.com/dns-query
```

> 其他所有字段保持默认，不要动。

保存 → 重启内核 → 完成。

---

## 为什么要改这些

| 改动 | 解决什么问题 |
|------|-------------|
| 域名服务器只填海外 DNS | 防止 DNS 泄漏（browserleaks 显示中国） |
| 回退服务器只填海外 DNS | 同上 |
| 域名服务器策略用 `geosite:cn` | 国内域名走国内 DNS 解析，否则 WeGame 等国内服务无法登录 |
| Fake IP 过滤加游戏域名 | 游戏客户端需要真实 IP，fake-ip 返回假地址会导致登录失败 |

---

## 注意事项

1. **GUI 的 DNS 覆写优先级高于 Script.js**，所以 DNS 必须在 GUI 里改才生效
2. Script.js 里的 DNS 配置已与 GUI 保持一致，作为备份/文档用
3. 使用**规则模式**（不是全局模式），国内流量直连、海外流量走链式代理
4. 如果以后新增国产游戏登录失败，在 Fake IP 过滤里加上对应域名即可
