# Clash Verge 配置（存档 / 备用）

> 桌面端目前主用 [Amnezia](../amnezia/)，Clash 这套作为**存档 / 备用**保留。本页说明这个目录里都有什么、怎么用。

## 目录内容

| 子目录 / 文件 | 是什么 |
|------|--------|
| [`docs/`](./docs/) | 配置教程与排错（见下方「配置指南」） |
| `config/` | 现成的 Clash Verge 配置：`verge.yaml`、`config.yaml`、`clash-verge.yaml`、`dns_config.yaml`、订阅 profile（`profiles/`，含防 DNS 泄露 `Script.js`）、GeoIP 数据库（`Country.mmdb` / `geoip.dat` / `geosite.dat`） |
| `releases/` | Clash Verge 各平台安装包（Win / macOS / Linux），可直接用；仅 WebView2 修复版（160+ MB）超 GitHub 上限未入库，见 [`releases/README.md`](./releases/) |

## 配置指南（`docs/`）

| 文档 | 内容 |
|------|------|
| [静态住宅 IP 链式代理完整配置指南](./docs/静态住宅IP链式代理完整配置指南.md) | 链式代理（落地静态住宅 IP）的完整配置 |
| [电脑迁移时遇到的问题](./docs/电脑迁移时遇到的问题.md) | 换电脑 / 迁移 Clash 配置时的常见问题 |
| [网址](./docs/网址.md) | 常用网址 / 订阅相关 |

> 配置界面截图见 `docs/Figures/`。

## 和 WSL 的关系

Clash 装在 Windows 侧；WSL 里怎么接入它的代理（apt / 环境变量代理 / DNS / 排错），与具体用哪个梯子无关，统一见 [`../../wsl-network.md`](../../wsl-network.md)。
