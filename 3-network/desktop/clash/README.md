# Clash Verge 配置（备用）

当前桌面端主力是 [Amnezia](../amnezia/)，这套 Clash Verge 配置作为备用保留。

## 目录内容

| 子目录 / 文件 | 说明 |
|------|------|
| `config/` | Clash Verge 配置文件：`verge.yaml`、`config.yaml`、`clash-verge.yaml`、`dns_config.yaml`；订阅 profile 在 `profiles/`（含防 DNS 泄露的 `Script.js`）；GeoIP 数据库 `Country.mmdb`、`geoip.dat`、`geosite.dat` |
| `docs/` | 配置教程与排错文档，配置界面截图在 `docs/Figures/` |
| `releases/` | Clash Verge 各平台安装包（Windows / macOS / Linux）。WebView2 修复版超过 GitHub 100MB 上限，未入库，见 [`releases/README.md`](./releases/) |

## docs/ 文档

| 文档 | 说明 |
|------|------|
| [静态住宅 IP 链式代理完整配置指南](./docs/静态住宅IP链式代理完整配置指南.md) | 链式代理落地静态住宅 IP 的完整配置 |
| [电脑迁移时遇到的问题](./docs/电脑迁移时遇到的问题.md) | 迁移 Clash 配置到新机器时的常见问题 |
| [网址](./docs/网址.md) | 常用网址与订阅信息 |

## 与 WSL 的关系

Clash 运行在 Windows 侧。WSL 接入代理的方式（apt 代理、环境变量、DNS、排错）与使用哪个代理工具无关，统一见 [`../../wsl-network.md`](../../wsl-network.md)。
