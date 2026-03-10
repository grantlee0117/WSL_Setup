// ════════════════════════════════════════════════════════════════════════════
//
//   Clash Verge Rev 全局扩展脚本
//
//   功能: 链式代理配置 + 规则分流
//   更新: 2025-01-15
//   lichunyuan 
//
//   【执行链路】
//   订阅原始配置 → 全局扩展配置(Merge.yaml) → 本脚本(Script.js) → 最终配置
//
//   【本脚本职责】
//   1. 添加静态住宅节点（二级跳）
//   2. 添加两个自定义策略组
//   3. 在规则最前面插入自定义规则（实现 prepend 效果）
//
// ════════════════════════════════════════════════════════════════════════════

function main(config) {

  // ══════════════════════════════════════════════════════════════════════════
  //
  //                           第一部分：节点定义
  //
  // ══════════════════════════════════════════════════════════════════════════
  //
  // 【如何新增节点】
  // 复制下面的模板，修改参数后添加到 customProxies 数组中即可
  //
  // 模板示例（SOCKS5 类型）:
  // {
  //   "name": "节点名称",
  //   "type": "socks5",
  //   "server": "服务器地址",
  //   "port": 端口号,
  //   "username": "用户名",
  //   "password": "密码",
  //   "dialer-proxy": "一级跳策略组名称",  // 链式代理关键！
  //   "skip-cert-verify": true
  // }
  //
  // ──────────────────────────────────────────────────────────────────────────

  const customProxies = [
    // ┌─────────────────────────────────────────────────────────────────────┐
    // │  原生静态住宅IP - 美国洛杉矶                                          │
    // │  用途: 链式代理的二级跳，提供干净的住宅 IP                              │
    // │  关键: dialer-proxy 指定通过哪个策略组连接此节点                       │
    // └─────────────────────────────────────────────────────────────────────┘
    {
      "name": "原生静态住宅IP-美国洛杉矶",
      "type": "socks5",
      "server": "223.29.147.115",
      "port": 12324,
      "username": "14af68c52b6c3",
      "password": "351d805601",
      "dialer-proxy": "美日自动-链式代理一级跳",  // ← 链式代理的核心！
      "skip-cert-verify": true
    },
    
    {
      "name": "Equaldcdn专属纯净静态住宅节点",
      "type": "vless",
      "server": "64.186.231.160",
      "port": 443,
      "uuid": "C2C0D5B2-73E6-40E3-A24A-AC77E9640289",
      "network": "tcp",
      "udp": true,
      "tls": true,
      "flow": "xtls-rprx-vision",
      "servername": "www.harvard.edu",
      "reality-opts": {
        "public-key": "wuR44y6UYuay6WCq4KtEJ26C6fkaNHsYf145YRPF92c",
        "short-id": "94b048a8fa8ebae4"
      },
      "client-fingerprint": "chrome",
      "dialer-proxy": "美日自动-链式代理一级跳",
      "skip-cert-verify": true
    },



    // ──────────────────────────────────────────────────────────────────────
    // 【用户自定义节点区域】

    // 示例：第二个节点（去掉注释并修改参数即可使用）
    // {
    //   "name": "原生静态住宅IP-节点2",
    //   "type": "socks5",
    //   "server": "8.8.8.8",
    //   "port": 443,
    //   "username": "username",
    //   "password": "password",
    //   "dialer-proxy": "美日自动-链式代理一级跳",
    //   "skip-cert-verify": true
    // },

    // ──────────────────────────────────────────────────────────────────────

  ];


  // ══════════════════════════════════════════════════════════════════════════
  //
  //                          第二部分：策略组定义
  //
  // ══════════════════════════════════════════════════════════════════════════
  //
  // 【策略组类型说明】
  // - select:    手动选择节点
  // - url-test:  自动测速，选延迟最低的
  // - fallback:  故障转移，第一个挂了自动切换
  // - load-balance: 负载均衡
  //
  // 【如何新增策略组】
  // 复制下面的模板，修改参数后添加到 customProxyGroups 数组中即可
  //
  // ──────────────────────────────────────────────────────────────────────────

  const customProxyGroups = [
    // ┌─────────────────────────────────────────────────────────────────────┐
    // │  美日自动-链式代理一级跳                                              │
    // │  用途: 故障转移，优先使用美国/日本可用节点作为第一跳                  │
    // │  类型: fallback（故障转移）                                          │
    // │  注意: 必须排除静态住宅节点本身，防止死循环                            │
    // └─────────────────────────────────────────────────────────────────────┘
    {
      "name": "美日自动-链式代理一级跳",
      "type": "fallback",
      // ─── include-all-proxies ───
      // mihomo 特有字段，自动包含 config.proxies 中的所有节点
      // 注意：必须是 "include-all-proxies"，不是 "include-all"
      "include-all-proxies": true,
      // ─── filter 正则过滤 ───
      // 从所有节点中筛选出美国/日本节点，同时排除静态住宅节点
      // (?!.*原生静态住宅IP) = 负向预查放最前，排除节点名包含"原生静态住宅IP"的节点
      // (?i) = 忽略大小写
      // (美国|US|...) = 匹配包含这些关键词的节点名
      "filter": "^(?!.*静态)(?i).*(美国|US|United States|日本|JP|Japan|🇺🇸|🇯🇵)",
      // ─── url 测速地址 ───
      // 【重要】不能使用 gstatic.com！因为它在规则中被分配到链式代理，会造成死循环：
      //   测速 → gstatic.com → 静态住宅-链式代理 → 需要一级跳 → 需要测速 → 死循环
      // 使用 Cloudflare 的测速地址，该域名不在链式代理规则中
      "url": "http://cp.cloudflare.com/generate_204",
      "interval": 300       // 每 5 分钟健康检查一次
    },

    // ┌─────────────────────────────────────────────────────────────────────┐
    // │  静态住宅-链式代理                                                    │
    // │  用途: 对 IP 要求严格的服务（AI、Google 等）                          │
    // │  类型: select（手动选择，但只有一个节点）                              │
    // │  流量路径: 你的电脑 → 一级跳(机场) → 静态住宅 → 目标网站               │
    // └─────────────────────────────────────────────────────────────────────┘
    {
      "name": "静态住宅-链式代理",
      "type": "select",
      "proxies": ["原生静态住宅IP-美国洛杉矶","Equaldcdn专属纯净静态住宅节点"]
      // 如果以后有多个住宅节点，在这里添加:
      // "proxies": ["原生静态住宅IP-美国洛杉矶", "其他住宅节点"]
    },

    // ──────────────────────────────────────────────────────────────────────
    // 【用户自定义策略组区域】
    // 在此处添加你的自定义策略组，格式参考上方模板
    // ──────────────────────────────────────────────────────────────────────

  ];


  // ══════════════════════════════════════════════════════════════════════════
  //
  //                           第三部分：规则定义
  //
  // ══════════════════════════════════════════════════════════════════════════
  //
  // 【规则匹配原理】
  // 规则从上往下匹配，命中即停止，所以顺序很重要！
  //
  // 【规则类型说明】
  // - DOMAIN:          精确匹配域名
  // - DOMAIN-SUFFIX:   匹配域名后缀（含子域名）
  // - DOMAIN-KEYWORD:  匹配域名中的关键词
  // - GEOSITE:         匹配 GeoSite 数据库中的域名集合
  // - GEOIP:           匹配 IP 地理位置
  // - IP-CIDR:         匹配 IP 地址段
  // - PROCESS-NAME:    匹配进程名
  // - MATCH:           兜底规则，匹配所有
  //
  // 【如何新增规则】
  // 在对应分类的数组中添加规则字符串即可
  // 格式: "规则类型,匹配内容,策略组名称"
  //
  // ──────────────────────────────────────────────────────────────────────────

  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │                                                                         │
  // │  第 1 类规则：必须直连（系统级）                                          │
  // │                                                                         │
  // │  这些地址如果走代理会导致系统异常，必须放在最前面！                        │
  // │                                                                         │
  // └─────────────────────────────────────────────────────────────────────────┘

  const rulesSystemDirect = [
    // ─── 回环地址 / 本机 ───
    // 127.x.x.x 是本机回环地址，用于本地服务通信
    // 如果走代理，本地服务（如数据库、开发服务器）将无法访问
    "IP-CIDR,127.0.0.0/8,DIRECT,no-resolve",        // IPv4 回环地址段，本机通信必须直连
    "DOMAIN,localhost,DIRECT",                     // 本机主机名解析，避免走代理
    // 兼容部分系统/容器对 localhost 的完整域名解析
    "DOMAIN,localhost.localdomain,DIRECT",         // localhost 的完整域名形式
    // IPv6 本机回环地址
    "IP-CIDR6,::1/128,DIRECT,no-resolve",           // IPv6 回环地址，保留本机访问

    // ─── 私有地址 / 局域网 ───
    // 这些是内网 IP 段，代理服务器无法访问你的内网
    // 常见场景：访问路由器 192.168.1.1、NAS、打印机等
    "IP-CIDR,10.0.0.0/8,DIRECT,no-resolve",        // 私有网段 A 类，局域网设备
    "IP-CIDR,172.16.0.0/12,DIRECT,no-resolve",     // 私有网段 B 类，局域网设备
    "IP-CIDR,192.168.0.0/16,DIRECT,no-resolve",    // 私有网段 C 类，最常见家庭/办公网
    "IP-CIDR,100.64.0.0/10,DIRECT,no-resolve",     // CGNAT 段，运营商内网
    "IP-CIDR6,fe80::/10,DIRECT,no-resolve",        // IPv6 链路本地地址
    // IPv6 唯一本地地址（ULA），等同于 IPv6 私有网段
    "IP-CIDR6,fc00::/7,DIRECT,no-resolve",         // IPv6 唯一本地地址段
    "DOMAIN-SUFFIX,local,DIRECT",                  // mDNS/局域网域名后缀
    "GEOSITE,private,DIRECT",                      // GeoSite 私有域名集合
    "GEOIP,private,DIRECT,no-resolve",             // 私有 IP 地理库匹配

    // ─── Windows 网络检测 ───
    // Windows 用这些域名检测网络连通性
    // 如果走代理，Windows 可能误判为"无网络连接"
    "DOMAIN-SUFFIX,msftconnecttest.com,DIRECT",    // Windows 联网检测域名
    "DOMAIN-SUFFIX,msftncsi.com,DIRECT",           // Windows NCSI 检测域名

    // ─── 代理进程本身 ───
    // 代理软件的流量不能再走代理，否则死循环
    "PROCESS-NAME,v2ray,DIRECT",                   // v2ray 进程本身直连
    "PROCESS-NAME,v2ray.exe,DIRECT",               // v2ray Windows 进程直连
    "PROCESS-NAME,xray,DIRECT",                    // xray 进程本身直连
    "PROCESS-NAME,xray.exe,DIRECT",                // xray Windows 进程直连
    "PROCESS-NAME,clash,DIRECT",                   // clash 进程本身直连
    "PROCESS-NAME,clash.exe,DIRECT",               // clash Windows 进程直连
    "PROCESS-NAME,mihomo,DIRECT",                  // mihomo 进程本身直连
    "PROCESS-NAME,mihomo.exe,DIRECT",              // mihomo Windows 进程直连
    "PROCESS-NAME,Clash Verge,DIRECT",             // Clash Verge 进程名（无扩展）
    "PROCESS-NAME,Clash Verge.exe,DIRECT",         // Clash Verge Windows 进程名
    // Clash Verge 新版/不同打包方式的进程名
    "PROCESS-NAME,clash-verge.exe,DIRECT",         // Clash Verge 另一进程名
    // Verge 内置的 mihomo 进程名
    "PROCESS-NAME,verge-mihomo.exe,DIRECT",        // Verge 内置内核进程名



    // ─── OCSP 证书验证服务 ───
    // 必须直连，否则严重影响 HTTPS 握手速度
    "DOMAIN-SUFFIX,digicert.com,DIRECT",           // DigiCert 证书验证
    "DOMAIN-SUFFIX,entrust.net,DIRECT",            // Entrust 证书验证
    "DOMAIN-SUFFIX,globalsign.com,DIRECT",         // GlobalSign 证书验证
    "DOMAIN-SUFFIX,comodoca.com,DIRECT",           // Comodo 证书验证
    "DOMAIN-SUFFIX,usertrust.com,DIRECT",          // UserTrust 证书验证
    "DOMAIN-SUFFIX,sectigo.com,DIRECT",            // Sectigo 证书验证
    "DOMAIN-SUFFIX,letsencrypt.org,DIRECT",        // Let's Encrypt 证书验证


    // ─── 微软系统级服务（必须直连）───
    // Windows 更新相关
    "DOMAIN-SUFFIX,windowsupdate.com,DIRECT",      // Windows 更新主域名
    "DOMAIN-SUFFIX,update.microsoft.com,DIRECT",   // 微软更新服务
    "DOMAIN-SUFFIX,delivery.mp.microsoft.com,DIRECT", // 更新分发服务
    "DOMAIN-SUFFIX,download.windowsupdate.com,DIRECT", // 更新下载
    "DOMAIN-SUFFIX,dl.delivery.mp.microsoft.com,DIRECT", // 分发下载
    "DOMAIN-SUFFIX,emdl.ws.microsoft.com,DIRECT",  // 更新元数据
    "DOMAIN-SUFFIX,wustat.windows.com,DIRECT",     // 更新状态
    "DOMAIN-SUFFIX,ntservicepack.microsoft.com,DIRECT", // 服务包更新
    // 系统激活
    "DOMAIN-SUFFIX,activation.sls.microsoft.com,DIRECT", // 系统激活服务
    "DOMAIN,go.microsoft.com,DIRECT",              // 微软跳转服务
    // 证书吊销
    "DOMAIN-SUFFIX,crl.microsoft.com,DIRECT",      // 微软证书吊销列表
    "DOMAIN-SUFFIX,mscrl.microsoft.com,DIRECT",    // 微软证书吊销列表
    // 微软错误报告
    "DOMAIN-SUFFIX,watson.microsoft.com,DIRECT",   // Windows 错误报告
    "DOMAIN-SUFFIX,watson.telemetry.microsoft.com,DIRECT", // 遥测服务
    // 微软商店下载（大文件，直连更快）
    "DOMAIN-SUFFIX,tlu.dl.delivery.mp.microsoft.com,DIRECT", // 商店下载
    "DOMAIN-SUFFIX,assets1.xboxlive.cn,DIRECT",    // Xbox 国内 CDN
    "DOMAIN-SUFFIX,assets2.xboxlive.cn,DIRECT",    // Xbox 国内 CDN




    // ─── 机场订阅域名 ───
    // 你的机场订阅地址必须直连，否则无法更新订阅
    "DOMAIN-SUFFIX,dg6.me,DIRECT",                 // 机场订阅主域名示例
    "DOMAIN-SUFFIX,cloudfrontcdn.com,DIRECT",      // 订阅可能用到的 CDN 域名
  ];


  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │                                                                         │
  // │  第 2 类规则：国内服务直连                                               │
  // │                                                                         │
  // │  这些是国内网站/服务，走代理反而更慢                                      │
  // │                                                                         │
  // └─────────────────────────────────────────────────────────────────────────┘

  const rulesChinaDirect = [
    // ─── 国内大模型 ───
    "DOMAIN-SUFFIX,deepseek.com,DIRECT",           // DeepSeek 国内服务域名
    "DOMAIN-SUFFIX,moonshot.cn,DIRECT",            // Moonshot 国内服务域名
    "DOMAIN,dashscope.aliyuncs.com,DIRECT",        // 阿里云 DashScope 接口域名
    "DOMAIN-SUFFIX,siliconflow.cn,DIRECT",         // SiliconFlow 国内服务域名
    "DOMAIN-SUFFIX,bigmodel.cn,DIRECT",            // 智谱 BigModel 域名
    "DOMAIN-SUFFIX,minimaxi.com,DIRECT",           // MiniMax 国内服务域名

    // ─── 字节系 ───
    "DOMAIN-SUFFIX,douyin.com,DIRECT",             // 抖音主域名
    "DOMAIN-SUFFIX,douyinpic.com,DIRECT",          // 抖音图片资源域名
    "DOMAIN-SUFFIX,douyincdn.com,DIRECT",          // 抖音 CDN 域名
    "DOMAIN-SUFFIX,bytedance.com,DIRECT",          // 字节跳动主域名
    "DOMAIN-SUFFIX,byteimg.com,DIRECT",            // 字节图片资源域名
    "DOMAIN-SUFFIX,toutiao.com,DIRECT",            // 今日头条主域名

    // ─── B 站 ───
    "GEOSITE,bilibili,DIRECT",                     // B 站相关域名集合

    // ─── 微软中国 ───
    "GEOSITE,microsoft@cn,DIRECT",                 // 微软中国服务域名集合
    "DOMAIN-SUFFIX,bing.com.cn,DIRECT",            // Bing 中国域名

    // ─── 教育网 ───
    "DOMAIN-SUFFIX,edu.cn,DIRECT",                 // 教育网域名后缀
    "GEOSITE,category-scholar-cn,DIRECT",          // 国内学术资源域名集合

    // ─── 国内常用进程 ───
    "PROCESS-NAME,QQ.exe,DIRECT",                  // QQ 客户端直连
    "PROCESS-NAME,WeChat.exe,DIRECT",              // 微信客户端直连
    "PROCESS-NAME,WeChatAppEx.exe,DIRECT",          // 微信辅助进程直连
    "PROCESS-NAME,QQMusic.exe,DIRECT",             // QQ 音乐客户端直连
    "PROCESS-NAME,NeteaseMusic.exe,DIRECT",        // 网易云音乐客户端直连
    "PROCESS-NAME,BaiduNetdisk.exe,DIRECT",        // 百度网盘客户端直连
    "PROCESS-NAME,Thunder.exe,DIRECT",             // 迅雷客户端直连
    "PROCESS-NAME,DingTalk.exe,DIRECT",            // 钉钉客户端直连
    "PROCESS-NAME,wemeetapp.exe,DIRECT",           // 腾讯会议客户端直连

    // ─── 国内兜底 ───
    "GEOSITE,cn,DIRECT",                           // 国内常见域名集合兜底
    "GEOIP,CN,DIRECT,no-resolve",                  // 中国大陆 IP 兜底直连
  ];


  // ┌─────────────────────────────────────────────────────────────────────────┐
  // │                                                                         │
  // │  第 3 类规则：对 IP 要求严格的海外服务 → 静态住宅-链式代理                │
  // │                                                                         │
  // │  这些服务会检测 IP 质量，数据中心 IP 容易被封禁                           │
  // │  通过链式代理使用住宅 IP，降低风控风险                                    │
  // │                                                                         │
  // │  【重要】这部分规则会覆盖原机场订阅中的 AI/Google 规则                    │
  // │                                                                         │
  // └─────────────────────────────────────────────────────────────────────────┘

  const rulesStrictIP = [
    // ══════════════════════════════════════════════════════════════════════
    //                          OpenAI / ChatGPT
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,openai.com,静态住宅-链式代理",         // OpenAI 主域名
    "DOMAIN,api.openai.com,静态住宅-链式代理",            // OpenAI API
    "DOMAIN,platform.openai.com,静态住宅-链式代理",       // OpenAI Platform
    "DOMAIN,chat.openai.com,静态住宅-链式代理",           // ChatGPT Web
    "DOMAIN,auth.openai.com,静态住宅-链式代理",           // OpenAI Auth
    "DOMAIN-SUFFIX,chatgpt.com,静态住宅-链式代理",        // ChatGPT 主域名
    "DOMAIN-SUFFIX,chat.com,静态住宅-链式代理",           // Chat 相关域名
    "DOMAIN-SUFFIX,ai.com,静态住宅-链式代理",             // AI.com 跳转域名
    "DOMAIN-SUFFIX,oaiusercontent.com,静态住宅-链式代理", // OpenAI 用户内容域名
    "DOMAIN-SUFFIX,oaistatic.com,静态住宅-链式代理",      // OpenAI 静态资源域名
    "DOMAIN-SUFFIX,sora.com,静态住宅-链式代理",           // OpenAI Sora 视频模型
    "DOMAIN-KEYWORD,openai,静态住宅-链式代理",           // 关键词匹配 OpenAI
    "DOMAIN-KEYWORD,chatgpt,静态住宅-链式代理",          // 关键词匹配 ChatGPT
    // ─── OpenAI 辅助服务（认证/会话/实验/反作弊/通信闭环）───
    "DOMAIN-SUFFIX,sentry.io,静态住宅-链式代理",          // 错误跟踪服务
    "DOMAIN-SUFFIX,statsig.com,静态住宅-链式代理",        // A/B 测试服务
    "DOMAIN-SUFFIX,statsigapi.net,静态住宅-链式代理",     // Statsig API
    "DOMAIN-SUFFIX,arkoselabs.com,静态住宅-链式代理",     // 人机验证/反作弊服务
    "DOMAIN-SUFFIX,auth0.com,静态住宅-链式代理",          // 认证服务
    "DOMAIN-SUFFIX,okta.com,静态住宅-链式代理",           // Okta identity
    "DOMAIN-SUFFIX,okta-eu.com,静态住宅-链式代理",        // Okta EU
    "DOMAIN-SUFFIX,oktapreview.com,静态住宅-链式代理",    // Okta preview
    "DOMAIN-SUFFIX,oktacdn.com,静态住宅-链式代理",        // Okta CDN
    "DOMAIN-SUFFIX,onelogin.com,静态住宅-链式代理",       // OneLogin identity
    "DOMAIN-SUFFIX,loginradius.com,静态住宅-链式代理",    // LoginRadius identity
    "DOMAIN-SUFFIX,intercom.io,静态住宅-链式代理",        // 客服系统
    "DOMAIN-SUFFIX,intercomcdn.com,静态住宅-链式代理",    // Intercom CDN
    "DOMAIN-SUFFIX,launchdarkly.com,静态住宅-链式代理",   // 特性开关服务
    "DOMAIN-SUFFIX,featuregates.org,静态住宅-链式代理",   // 特性开关服务
    "DOMAIN-SUFFIX,segment.io,静态住宅-链式代理",         // 分析服务
    "DOMAIN-SUFFIX,stripe.com,静态住宅-链式代理",         // 支付服务
    "DOMAIN-SUFFIX,livekit.cloud,静态住宅-链式代理",      // 实时语音服务
    "DOMAIN-SUFFIX,identrust.com,静态住宅-链式代理",      // 证书服务
    "DOMAIN-SUFFIX,algolia.net,静态住宅-链式代理",        // 搜索服务
    "DOMAIN-SUFFIX,observeit.net,静态住宅-链式代理",      // 监控服务
    "DOMAIN-SUFFIX,datadoghq.com,静态住宅-链式代理",      // 监控分析服务

    // ══════════════════════════════════════════════════════════════════════
    //                          Anthropic / Claude
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,anthropic.com,静态住宅-链式代理",      // Anthropic 主域名（含 api.anthropic.com）
    "DOMAIN,api.anthropic.com,静态住宅-链式代理",         // Anthropic API
    "DOMAIN,console.anthropic.com,静态住宅-链式代理",     // Anthropic Console
    "DOMAIN-SUFFIX,claude.ai,静态住宅-链式代理",          // Claude 网页聊天域名
    "DOMAIN-SUFFIX,claude.com,静态住宅-链式代理",         // Claude 开发者平台域名（console 等）
    "DOMAIN-KEYWORD,anthropic,静态住宅-链式代理",        // 关键词匹配 Anthropic
    "DOMAIN-KEYWORD,claude,静态住宅-链式代理",            // 关键词匹配 Claude

    // ══════════════════════════════════════════════════════════════════════
    //                          Google 全系
    // ══════════════════════════════════════════════════════════════════════
    // Google 服务用住宅 IP 可大幅减少人机验证（reCAPTCHA）
    "GEOSITE,google,静态住宅-链式代理",                  // Google 全系域名集合
    "GEOSITE,youtube,静态住宅-链式代理",                 // YouTube 域名集合
    "DOMAIN-SUFFIX,google.com,静态住宅-链式代理",         // Google 主域名
    "DOMAIN-SUFFIX,google,静态住宅-链式代理",             // Google TLD
    "DOMAIN-SUFFIX,goog,静态住宅-链式代理",               // Google TLD
    "DOMAIN-SUFFIX,g.co,静态住宅-链式代理",               // Google short
    "DOMAIN-SUFFIX,goo.gl,静态住宅-链式代理",             // Google shortener
    "DOMAIN-SUFFIX,googleapis.com,静态住宅-链式代理",     // Google API 域名
    "DOMAIN-SUFFIX,googlevideo.com,静态住宅-链式代理",    // YouTube 视频域名
    "DOMAIN-SUFFIX,youtube.com,静态住宅-链式代理",        // YouTube 主域名
    "DOMAIN-SUFFIX,youtu.be,静态住宅-链式代理",           // YouTube 短域名
    "DOMAIN-SUFFIX,ytimg.com,静态住宅-链式代理",          // YouTube 静态资源域名
    "DOMAIN-SUFFIX,ggpht.com,静态住宅-链式代理",          // Google 图片托管域名
    "DOMAIN-SUFFIX,gstatic.com,静态住宅-链式代理",        // Google 静态资源域名
    "DOMAIN-SUFFIX,gmail.com,静态住宅-链式代理",          // Gmail 域名
    "DOMAIN-SUFFIX,googleusercontent.com,静态住宅-链式代理", // Googleusercontent 域名
    "DOMAIN-SUFFIX,recaptcha.net,静态住宅-链式代理",      // reCAPTCHA 验证域名（非 google.com 镜像）
    "GEOIP,google,静态住宅-链式代理,no-resolve",          // Google IP 段

    // ══════════════════════════════════════════════════════════════════════
    //                          xAI / Grok
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,x.ai,静态住宅-链式代理",              // xAI 主域名
    "DOMAIN-SUFFIX,grok.com,静态住宅-链式代理",          // Grok 主域名
    "DOMAIN-KEYWORD,grok,静态住宅-链式代理",             // 关键词匹配 Grok

    // ══════════════════════════════════════════════════════════════════════
    //                          X / Twitter
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,x.com,静态住宅-链式代理",             // X 主域名
    "DOMAIN-SUFFIX,twitter.com,静态住宅-链式代理",       // Twitter 主域名
    "DOMAIN-SUFFIX,t.co,静态住宅-链式代理",              // Twitter 短链域名
    "DOMAIN-SUFFIX,twimg.com,静态住宅-链式代理",         // Twitter 静态资源域名

    // ══════════════════════════════════════════════════════════════════════
    //                          Google Gemini
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN,gemini.google.com,静态住宅-链式代理",         // Gemini AI 助手主域名
    "DOMAIN,gemini.google,静态住宅-链式代理",             // Gemini 项目站点（Google TLD）
    "DOMAIN-SUFFIX,aistudio.google.com,静态住宅-链式代理", // Google AI Studio
    "DOMAIN,generativelanguage.googleapis.com,静态住宅-链式代理", // Gemini API
    "DOMAIN,cloudcode-pa.googleapis.com,静态住宅-链式代理", // Gemini Code Assist 接口
    "DOMAIN-KEYWORD,gemini,静态住宅-链式代理",            // 关键词匹配 Gemini

    // ══════════════════════════════════════════════════════════════════════
    //                          其他海外 AI 服务
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,perplexity.ai,静态住宅-链式代理",      // Perplexity 服务域名
    "DOMAIN-SUFFIX,huggingface.co,静态住宅-链式代理",     // Hugging Face 主域名
    "DOMAIN-SUFFIX,huggingface.cloud,静态住宅-链式代理",  // Hugging Face 云域名
    "DOMAIN-SUFFIX,hf.co,静态住宅-链式代理",              // Hugging Face 短链域名
    "DOMAIN-SUFFIX,hf.space,静态住宅-链式代理",           // Hugging Face Spaces
    "DOMAIN-SUFFIX,cohere.ai,静态住宅-链式代理",          // Cohere 服务域名
    "DOMAIN-SUFFIX,cohere.com,静态住宅-链式代理",         // Cohere 官网域名
    "DOMAIN-SUFFIX,midjourney.com,静态住宅-链式代理",     // Midjourney 域名
    "DOMAIN-SUFFIX,stability.ai,静态住宅-链式代理",       // Stability AI 域名
    "DOMAIN-SUFFIX,replicate.com,静态住宅-链式代理",      // Replicate 服务域名
    "DOMAIN-SUFFIX,together.ai,静态住宅-链式代理",        // Together AI 域名
    "DOMAIN-SUFFIX,fireworks.ai,静态住宅-链式代理",       // Fireworks AI 域名
    "DOMAIN-SUFFIX,groq.com,静态住宅-链式代理",           // Groq 域名
    "DOMAIN-SUFFIX,mistral.ai,静态住宅-链式代理",         // Mistral AI 域名
    "DOMAIN-SUFFIX,meta.ai,静态住宅-链式代理",            // Meta AI 域名
    "DOMAIN-SUFFIX,llama.com,静态住宅-链式代理",          // Llama 相关域名
    "DOMAIN-SUFFIX,poe.com,静态住宅-链式代理",            // Poe 平台域名
    "DOMAIN-SUFFIX,character.ai,静态住宅-链式代理",       // Character.AI 域名
    "DOMAIN-SUFFIX,inflection.ai,静态住宅-链式代理",      // Inflection AI 域名
    "DOMAIN-SUFFIX,pi.ai,静态住宅-链式代理",              // Pi AI 域名
    "GEOSITE,category-ai-!cn,静态住宅-链式代理",          // 非中国 AI 站点集合

    // ══════════════════════════════════════════════════════════════════════
    //                          AI 编程工具
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,cursor.com,静态住宅-链式代理",         // Cursor 官网/服务域名
    "DOMAIN-SUFFIX,cursor.so,静态住宅-链式代理",          // Cursor 旧域名
    "DOMAIN-SUFFIX,cursor.sh,静态住宅-链式代理",          // Cursor 旧/短域名
    "DOMAIN-KEYWORD,cursor,静态住宅-链式代理",            // 关键词匹配 Cursor
    "PROCESS-NAME,Cursor.exe,静态住宅-链式代理",          // Cursor 客户端进程
    "PROCESS-NAME,cursor.exe,静态住宅-链式代理",          // Cursor 客户端进程（小写）

    // ══════════════════════════════════════════════════════════════════════
    //                          GitHub 全系服务
    // ══════════════════════════════════════════════════════════════════════
    "GEOSITE,github,静态住宅-链式代理",                  // GitHub 域名集合
    "DOMAIN-SUFFIX,github.com,静态住宅-链式代理",         // GitHub 主域名（仓库/登录/OAuth）
    "DOMAIN-SUFFIX,github.io,静态住宅-链式代理",          // GitHub Pages 域名
    "DOMAIN-SUFFIX,github.dev,静态住宅-链式代理",         // VS Code for Web 在线开发
    "DOMAIN-SUFFIX,githubusercontent.com,静态住宅-链式代理", // GitHub 用户内容（Raw/头像）
    "DOMAIN-SUFFIX,githubassets.com,静态住宅-链式代理",   // GitHub 静态资源域名
    "DOMAIN-SUFFIX,githubcopilot.com,静态住宅-链式代理",  // GitHub Copilot AI 编码助手
    "DOMAIN-SUFFIX,githubnext.com,静态住宅-链式代理",     // GitHub Next 实验项目站
    "PROCESS-NAME,git.exe,静态住宅-链式代理",            // Git 命令行进程
    "PROCESS-NAME,git,静态住宅-链式代理",                // Git 进程（无扩展）

    // --- CI/CD & DevOps ---
    "DOMAIN-SUFFIX,gitlab.com,静态住宅-链式代理",         // GitLab SaaS
    "DOMAIN-SUFFIX,gitlab.io,静态住宅-链式代理",          // GitLab Pages
    "DOMAIN-SUFFIX,gitlab-static.net,静态住宅-链式代理",  // GitLab static assets
    "DOMAIN-SUFFIX,bitbucket.org,静态住宅-链式代理",      // Bitbucket
    "DOMAIN-SUFFIX,bitbucket.io,静态住宅-链式代理",       // Bitbucket Pages
    "DOMAIN-SUFFIX,circleci.com,静态住宅-链式代理",       // CircleCI
    "DOMAIN-SUFFIX,travis-ci.com,静态住宅-链式代理",      // Travis CI
    "DOMAIN-SUFFIX,dev.azure.com,静态住宅-链式代理",      // Azure DevOps

    // ══════════════════════════════════════════════════════════════════════
    //                          VS Code 相关
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,code.visualstudio.com,静态住宅-链式代理", // VS Code 官网
    "DOMAIN-SUFFIX,vscode.dev,静态住宅-链式代理",         // VS Code Web
    "DOMAIN-SUFFIX,marketplace.visualstudio.com,静态住宅-链式代理", // 扩展市场
    "DOMAIN-SUFFIX,vsassets.io,静态住宅-链式代理",        // VS Code 静态资源

    // --- Dev tools / Cloud IDE & hosting ---
    "DOMAIN-SUFFIX,replit.com,静态住宅-链式代理",         // Replit main
    "DOMAIN-SUFFIX,repl.co,静态住宅-链式代理",            // Replit apps
    "DOMAIN-SUFFIX,repl.it,静态住宅-链式代理",            // Replit legacy
    "DOMAIN-SUFFIX,glitch.com,静态住宅-链式代理",         // Glitch main
    "DOMAIN-SUFFIX,glitch.me,静态住宅-链式代理",          // Glitch apps
    "DOMAIN-SUFFIX,netlify.com,静态住宅-链式代理",        // Netlify main
    "DOMAIN-SUFFIX,netlify.app,静态住宅-链式代理",        // Netlify apps
    "DOMAIN-SUFFIX,render.com,静态住宅-链式代理",         // Render main
    "DOMAIN-SUFFIX,onrender.com,静态住宅-链式代理",       // Render apps


    // ══════════════════════════════════════════════════════════════════════
    //                          微软海外服务（非系统级）
    // ══════════════════════════════════════════════════════════════════════
    // 注意：系统级服务（更新、激活、证书）已在 rulesSystemDirect 中直连
    // 这里是需要海外身份的微软服务

    // ─── 微软账户 & 登录 ───
    "DOMAIN-SUFFIX,live.com,静态住宅-链式代理",            // Microsoft Live 服务
    "DOMAIN-SUFFIX,login.microsoftonline.com,静态住宅-链式代理", // Azure AD 登录
    "DOMAIN-SUFFIX,account.microsoft.com,静态住宅-链式代理", // 微软账户
    "DOMAIN-SUFFIX,passport.net,静态住宅-链式代理",        // Passport 认证

    // ─── OneDrive 国际版 ───
    "DOMAIN-SUFFIX,onedrive.com,静态住宅-链式代理",        // OneDrive 主域名
    "DOMAIN-SUFFIX,onedrive.live.com,静态住宅-链式代理",   // OneDrive Live
    "DOMAIN-SUFFIX,sharepoint.com,静态住宅-链式代理",      // SharePoint 服务
    "DOMAIN-SUFFIX,sharepointonline.com,静态住宅-链式代理", // SharePoint Online
    "DOMAIN-SUFFIX,1drv.com,静态住宅-链式代理",            // OneDrive 短链
    "DOMAIN-SUFFIX,1drv.ms,静态住宅-链式代理",             // OneDrive 短链

    // ─── Microsoft 365 国际版 ───
    "DOMAIN-SUFFIX,office.com,静态住宅-链式代理",          // Office 主域名
    "DOMAIN-SUFFIX,office365.com,静态住宅-链式代理",       // Office 365 域名
    "DOMAIN-SUFFIX,office.net,静态住宅-链式代理",          // Office 网络服务
    "DOMAIN-SUFFIX,officeppe.net,静态住宅-链式代理",       // Office PPE
    "DOMAIN-SUFFIX,msftauth.net,静态住宅-链式代理",        // 微软认证
    "DOMAIN-SUFFIX,msauth.net,静态住宅-链式代理",          // 微软认证
    "DOMAIN-SUFFIX,msauthimages.net,静态住宅-链式代理",    // 认证图片
    "DOMAIN-SUFFIX,outlook.com,静态住宅-链式代理",         // Outlook 邮箱
    "DOMAIN-SUFFIX,outlook.live.com,静态住宅-链式代理",    // Outlook Live
    "DOMAIN-SUFFIX,outlook.office.com,静态住宅-链式代理",  // Outlook Office
    "DOMAIN-SUFFIX,outlook.office365.com,静态住宅-链式代理", // Outlook 365

    // ─── Copilot & AI 服务 ───
    "DOMAIN-SUFFIX,copilot.microsoft.com,静态住宅-链式代理", // Microsoft Copilot
    "DOMAIN-SUFFIX,bing.com,静态住宅-链式代理",            // Bing 国际版（含 Copilot）
    "DOMAIN-SUFFIX,bingapis.com,静态住宅-链式代理",        // Bing API
    "DOMAIN-SUFFIX,msn.com,静态住宅-链式代理",             // MSN 服务

    // ─── Xbox & 游戏服务 ───
    "DOMAIN-SUFFIX,xbox.com,静态住宅-链式代理",            // Xbox 主域名
    "DOMAIN-SUFFIX,xboxlive.com,静态住宅-链式代理",        // Xbox Live 服务
    "DOMAIN-SUFFIX,xboxservices.com,静态住宅-链式代理",    // Xbox 服务
    "DOMAIN-SUFFIX,gamepass.com,静态住宅-链式代理",        // Game Pass 服务

    // ─── 微软商店 & 奖励 ───
    "DOMAIN-SUFFIX,microsoftstore.com,静态住宅-链式代理",  // 微软商店
    "DOMAIN-SUFFIX,rewards.microsoft.com,静态住宅-链式代理", // Microsoft Rewards

    // ─── 微软其他海外服务 ───
    "DOMAIN-SUFFIX,microsoft.com,静态住宅-链式代理",       // 微软主域名（兜底）
    "DOMAIN-SUFFIX,microsoftonline.com,静态住宅-链式代理", // 微软在线服务
    "DOMAIN-SUFFIX,azure.com,静态住宅-链式代理",           // Azure 服务
    "DOMAIN-SUFFIX,azure.net,静态住宅-链式代理",           // Azure 网络
    "DOMAIN-SUFFIX,azureedge.net,静态住宅-链式代理",       // Azure CDN
    "DOMAIN-SUFFIX,msedge.net,静态住宅-链式代理",          // Edge CDN
    "DOMAIN-SUFFIX,skype.com,静态住宅-链式代理",           // Skype 服务
    "DOMAIN-SUFFIX,linkedin.com,静态住宅-链式代理",        // LinkedIn


    // ══════════════════════════════════════════════════════════════════════
    //                          IP 检测网站（用于验证链式代理是否生效）
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,ip.sb,静态住宅-链式代理",              // IP 检测服务
    "DOMAIN-SUFFIX,ipinfo.io,静态住宅-链式代理",          // IP 信息查询
    "DOMAIN-SUFFIX,ip-api.com,静态住宅-链式代理",         // IP 地理信息查询
    "DOMAIN-SUFFIX,whoer.net,静态住宅-链式代理",          // 反检测/指纹查询
    "DOMAIN-SUFFIX,ping0.cc,静态住宅-链式代理",           // IP/网络检测站
    "DOMAIN-SUFFIX,ipqualityscore.com,静态住宅-链式代理", // IP 质量评分
    "DOMAIN-SUFFIX,scamalytics.com,静态住宅-链式代理",    // 风控/欺诈评分
    "DOMAIN-SUFFIX,browserleaks.com,静态住宅-链式代理",   // 浏览器指纹检测

    // ══════════════════════════════════════════════════════════════════════
    //                          流媒体（高风控）
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,netflix.com,静态住宅-链式代理",        // Netflix 主域名
    "DOMAIN-SUFFIX,nflxvideo.net,静态住宅-链式代理",      // Netflix 视频域名
    "DOMAIN-SUFFIX,nflximg.net,静态住宅-链式代理",        // Netflix 图片资源
    "DOMAIN-SUFFIX,nflxso.net,静态住宅-链式代理",         // Netflix 服务组件
    "DOMAIN-SUFFIX,nflxext.com,静态住宅-链式代理",        // Netflix 扩展资源
    "DOMAIN-SUFFIX,disneyplus.com,静态住宅-链式代理",     // Disney+ 主域名
    "DOMAIN-SUFFIX,dssott.com,静态住宅-链式代理",         // Disney+ 流媒体域名
    "DOMAIN-SUFFIX,disneystreaming.com,静态住宅-链式代理", // Disney Streaming
    "DOMAIN-SUFFIX,hulu.com,静态住宅-链式代理",           // Hulu 主域名
    "DOMAIN-SUFFIX,huluim.com,静态住宅-链式代理",         // Hulu 图片/媒体域名
    "DOMAIN-SUFFIX,primevideo.com,静态住宅-链式代理",     // Prime Video 主域名
    "DOMAIN-SUFFIX,amazonvideo.com,静态住宅-链式代理",    // Amazon Video 域名
    "DOMAIN-SUFFIX,aiv-cdn.net,静态住宅-链式代理",        // Prime Video CDN
    "DOMAIN-SUFFIX,tv.apple.com,静态住宅-链式代理",       // Apple TV+ 域名
    "DOMAIN-SUFFIX,apple.com,静态住宅-链式代理",          // Apple 相关服务
    "DOMAIN-SUFFIX,max.com,静态住宅-链式代理",            // Max(HBO) 主域名
    "DOMAIN-SUFFIX,hbomax.com,静态住宅-链式代理",         // HBO Max 主域名
    "DOMAIN-SUFFIX,hbomaxcdn.com,静态住宅-链式代理",      // HBO Max CDN
    "DOMAIN-SUFFIX,paramountplus.com,静态住宅-链式代理",  // Paramount+ 主域名
    "DOMAIN-SUFFIX,cbs.com,静态住宅-链式代理",            // CBS/Paramount 相关
    "DOMAIN-SUFFIX,peacocktv.com,静态住宅-链式代理",      // Peacock 主域名

    // ══════════════════════════════════════════════════════════════════════
    //                          音乐/社交/风控偏严
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,spotify.com,静态住宅-链式代理",        // Spotify 主域名
    "DOMAIN-SUFFIX,scdn.co,静态住宅-链式代理",            // Spotify CDN
    "DOMAIN-SUFFIX,tiktok.com,静态住宅-链式代理",         // TikTok 主域名
    "DOMAIN-SUFFIX,tiktokcdn.com,静态住宅-链式代理",      // TikTok CDN
    "DOMAIN-SUFFIX,tiktokv.com,静态住宅-链式代理",        // TikTok 视频域名
    "DOMAIN-SUFFIX,discord.com,静态住宅-链式代理",        // Discord 主域名
    "DOMAIN-SUFFIX,discordapp.com,静态住宅-链式代理",     // Discord 旧域名
    "DOMAIN-SUFFIX,discord.gg,静态住宅-链式代理",         // Discord 邀请域名
    "DOMAIN-SUFFIX,discordapp.net,静态住宅-链式代理",     // Discord CDN

    // ══════════════════════════════════════════════════════════════════════
    //                          Cloudflare 风控与验证
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,challenges.cloudflare.com,静态住宅-链式代理", // Cloudflare 挑战页/Turnstile
    "DOMAIN-SUFFIX,captcha.website,静态住宅-链式代理",    // Cloudflare Privacy Pass 验证辅助域

    // ══════════════════════════════════════════════════════════════════════
    //                          Telegram（高风控即时通讯）
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,telegram.org,静态住宅-链式代理",       // Telegram 官网
    "DOMAIN-SUFFIX,telegra.ph,静态住宅-链式代理",         // Telegraph 博客平台
    "DOMAIN-SUFFIX,t.me,静态住宅-链式代理",               // Telegram 邀请链接
    "DOMAIN-SUFFIX,telegram.me,静态住宅-链式代理",        // Telegram 旧域名
    "DOMAIN-SUFFIX,telesco.pe,静态住宅-链式代理",         // Telegram 短链
    // ─── Telegram IP 段 ───
    "IP-CIDR,91.108.4.0/22,静态住宅-链式代理,no-resolve",     // Telegram DC
    "IP-CIDR,91.108.8.0/21,静态住宅-链式代理,no-resolve",     // Telegram DC
    "IP-CIDR,91.108.16.0/22,静态住宅-链式代理,no-resolve",    // Telegram DC
    "IP-CIDR,91.108.56.0/22,静态住宅-链式代理,no-resolve",    // Telegram DC
    "IP-CIDR,149.154.160.0/20,静态住宅-链式代理,no-resolve",  // Telegram DC
    "IP-CIDR6,2001:67c:4e8::/48,静态住宅-链式代理,no-resolve",   // Telegram IPv6
    "IP-CIDR6,2001:b28:f23d::/48,静态住宅-链式代理,no-resolve",  // Telegram IPv6
    "IP-CIDR6,2001:b28:f23f::/48,静态住宅-链式代理,no-resolve",  // Telegram IPv6

    // ══════════════════════════════════════════════════════════════════════
    //                          社交媒体（高风控平台）
    // ══════════════════════════════════════════════════════════════════════
    // ─── Facebook / Meta 系 ───
    "DOMAIN-SUFFIX,facebook.com,静态住宅-链式代理",       // Facebook 主域名
    "DOMAIN-SUFFIX,fbcdn.net,静态住宅-链式代理",          // Facebook CDN
    "DOMAIN-SUFFIX,fb.me,静态住宅-链式代理",              // Facebook 短链
    "DOMAIN-SUFFIX,fb.com,静态住宅-链式代理",             // Facebook 短域名
    "DOMAIN-SUFFIX,fbsbx.com,静态住宅-链式代理",          // Facebook 沙盒
    "DOMAIN-SUFFIX,messenger.com,静态住宅-链式代理",      // Messenger
    "DOMAIN-KEYWORD,facebook,静态住宅-链式代理",          // 关键词匹配 Facebook
    // ─── Instagram ───
    "DOMAIN-SUFFIX,instagram.com,静态住宅-链式代理",      // Instagram 主域名
    "DOMAIN-SUFFIX,cdninstagram.com,静态住宅-链式代理",   // Instagram CDN
    "DOMAIN-KEYWORD,instagram,静态住宅-链式代理",         // 关键词匹配 Instagram
    // ─── WhatsApp ───
    "DOMAIN-SUFFIX,whatsapp.com,静态住宅-链式代理",       // WhatsApp 主域名
    "DOMAIN-SUFFIX,whatsapp.net,静态住宅-链式代理",       // WhatsApp 网络
    "DOMAIN-KEYWORD,whatsapp,静态住宅-链式代理",          // 关键词匹配 WhatsApp
    // ─── Signal ───
    "DOMAIN-SUFFIX,signal.org,静态住宅-链式代理",         // Signal 主域名
    "DOMAIN-SUFFIX,whispersystems.org,静态住宅-链式代理", // Signal 旧域名
    // ─── Pinterest ───
    "DOMAIN-SUFFIX,pinterest.com,静态住宅-链式代理",      // Pinterest 主域名
    "DOMAIN-SUFFIX,pinimg.com,静态住宅-链式代理",         // Pinterest 图片 CDN
    // ─── Reddit ───
    "DOMAIN-SUFFIX,reddit.com,静态住宅-链式代理",         // Reddit 主域名
    "DOMAIN-SUFFIX,redd.it,静态住宅-链式代理",            // Reddit 短链
    "DOMAIN-SUFFIX,redditmedia.com,静态住宅-链式代理",    // Reddit 媒体
    "DOMAIN-SUFFIX,redditstatic.com,静态住宅-链式代理",   // Reddit 静态资源
    // ─── Twitch ───
    "DOMAIN-SUFFIX,twitch.tv,静态住宅-链式代理",          // Twitch 主域名
    "DOMAIN-SUFFIX,jtvnw.net,静态住宅-链式代理",          // Twitch CDN
    "DOMAIN-SUFFIX,twitchcdn.net,静态住宅-链式代理",      // Twitch CDN
    // ─── Tumblr ───
    "DOMAIN-SUFFIX,tumblr.com,静态住宅-链式代理",         // Tumblr 主域名
    "DOMAIN-SUFFIX,tmblr.co,静态住宅-链式代理",           // Tumblr 短链

    // ══════════════════════════════════════════════════════════════════════
    //                          其他 AI 服务（补充）
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,suno.ai,静态住宅-链式代理",            // Suno AI 音乐
    "DOMAIN-SUFFIX,suno.com,静态住宅-链式代理",           // Suno AI 音乐
    "DOMAIN-SUFFIX,runway.ml,静态住宅-链式代理",          // Runway 视频 AI
    "DOMAIN-SUFFIX,runwayml.com,静态住宅-链式代理",       // Runway 视频 AI
    "DOMAIN-SUFFIX,elevenlabs.io,静态住宅-链式代理",      // ElevenLabs 语音合成
    "DOMAIN-SUFFIX,leonardo.ai,静态住宅-链式代理",        // Leonardo AI 图像
    "DOMAIN-SUFFIX,ideogram.ai,静态住宅-链式代理",        // Ideogram AI 图像
    "DOMAIN-SUFFIX,civitai.com,静态住宅-链式代理",        // Civitai 模型平台
    "DOMAIN-SUFFIX,recraft.ai,静态住宅-链式代理",         // Recraft AI 图像
    "DOMAIN-SUFFIX,deepmind.com,静态住宅-链式代理",       // DeepMind
    "DOMAIN-SUFFIX,deepmind.google,静态住宅-链式代理",    // DeepMind Google
    "DOMAIN-SUFFIX,notion.so,静态住宅-链式代理",          // Notion 主域名
    "DOMAIN-SUFFIX,notion.site,静态住宅-链式代理",        // Notion 站点

    // ══════════════════════════════════════════════════════════════════════
    //                          IP 检测服务（补充）
    // ══════════════════════════════════════════════════════════════════════
    "DOMAIN-SUFFIX,ipleak.net,静态住宅-链式代理",         // IP 泄露检测
    "DOMAIN-SUFFIX,browserscan.net,静态住宅-链式代理",    // 浏览器指纹扫描
    "DOMAIN-SUFFIX,dnsleaktest.com,静态住宅-链式代理",    // DNS 泄露检测
    "DOMAIN-SUFFIX,dnsleak.com,静态住宅-链式代理",        // DNS 泄露检测

    // ──────────────────────────────────────────────────────────────────────
    // 【用户自定义规则区域 - 对 IP 要求严格的服务】
    // 在此处添加需要走静态住宅的域名
    // 格式: "DOMAIN-SUFFIX,example.com,静态住宅-链式代理"
    // ──────────────────────────────────────────────────────────────────────

  ];


  // ══════════════════════════════════════════════════════════════════════════
  //
  //                           第四部分：执行配置修改
  //
  // ══════════════════════════════════════════════════════════════════════════

  // 确保数组存在
  if (!config.proxies) config.proxies = [];
  if (!config["proxy-groups"]) config["proxy-groups"] = [];
  if (!config.rules) config.rules = [];

  // ─── 4.1 插入自定义节点 ───
  // unshift = 插入到数组最前面
  for (let i = customProxies.length - 1; i >= 0; i--) {
    config.proxies.unshift(customProxies[i]);
  }

  // ─── 4.2 插入自定义策略组 ───
  // 注意插入顺序：先插入的会排在后面
  // 所以我们倒序插入，让 "美日自动-链式代理一级跳" 排在最前面
  for (let i = customProxyGroups.length - 1; i >= 0; i--) {
    config["proxy-groups"].unshift(customProxyGroups[i]);
  }

  // ─── 4.3 插入自定义规则 ───
  // 合并所有规则，按优先级顺序
  const allCustomRules = [
    ...rulesSystemDirect,   // 最高优先级：系统必须直连
    ...rulesChinaDirect,    // 第二优先级：国内直连
    ...rulesStrictIP,       // 第三优先级：对 IP 要求严格的服务 → 链式代理
  ];

  // 将自定义规则插入到原有规则的最前面
  config.rules.unshift(...allCustomRules);


  // ══════════════════════════════════════════════════════════════════════════
  //
  //                           第五部分：DNS 配置优化
  //
  // ══════════════════════════════════════════════════════════════════════════
  //
  // 保留订阅原有DNS配置，只补充必要的proxy-server-nameserver
  // 确保代理服务器域名能够正确解析
  //

  if (!config.dns) {
    config.dns = {};
  }

  // ──────────────────────────────────────────────────────────────────────
  // DNS 全面优化（尽量不覆盖订阅已有配置，仅补全缺失项）
  // 目标：稳定、快速、兼容链式代理与分流规则
  // ──────────────────────────────────────────────────────────────────────

  // 1) 基础开关与监听
  if (config.dns.enable === undefined) {
    config.dns.enable = true;                     // 开启 DNS
  }
  if (!config.dns.listen) {
    config.dns.listen = "0.0.0.0:1053";          // 本地监听端口（避免与系统 53 冲突）
  }
  // ─── IPv6 强制关闭 ───
  // 理由：
  // 1. 防止 IPv6 流量绕过代理泄漏真实 IP
  // 2. 多数机场节点和静态住宅 IP 不支持 IPv6
  // 3. 与 Merge.yaml 中的 ipv6: false 保持一致
  // 4. 避免 DNS 返回 IPv6 地址导致连接失败
  config.dns.ipv6 = false;                        // 禁用 IPv6 DNS 解析

  // 2) 解析模式（混合：国内直连优先，国外走代理解析）
  if (!config.dns["enhanced-mode"]) {
    config.dns["enhanced-mode"] = "redir-host"; // 兼容性最好，避免 Fake-IP 风控问题
  }

  // 3) 主要 DNS（国内，低延迟）
  if (!config.dns.nameserver) {
    config.dns.nameserver = [
      "https://223.5.5.5/dns-query",             // 阿里 DoH
      "https://doh.pub/dns-query",               // 腾讯 DoH
      "tls://223.5.5.5",                         // 阿里 DoT
      "tls://dot.pub"                            // 腾讯 DoT
    ];
  }

  // 4) 代理专用 DNS（解析需走代理的域名，避免污染）
  if (!config.dns["proxy-server-nameserver"]) {
    config.dns["proxy-server-nameserver"] = [
      "https://1.1.1.1/dns-query",               // Cloudflare DoH
      "https://dns.google/dns-query",            // Google DoH
      "tls://1.1.1.1"                            // Cloudflare DoT
    ];
  }

  // 5) 备用 DNS（用于国外/被污染域名回退）
  if (!config.dns.fallback) {
    config.dns.fallback = [
      "https://1.1.1.1/dns-query",               // Cloudflare
      "https://dns.google/dns-query",            // Google
      "https://9.9.9.9/dns-query",               // Quad9
      "tls://1.1.1.1",
      "tls://8.8.8.8"
    ];
  }

  // 6) 回退过滤：仅在检测到污染/海外 IP 时才用 fallback
  if (!config.dns["fallback-filter"]) {
    config.dns["fallback-filter"] = {
      geoip: true,
      "geoip-code": "CN",
      ipcidr: [
        "240.0.0.0/4"                            // 保留地址段
      ],
      domain: [
        "+.google",
        "+.gstatic.com",
        "+.youtube.com",
        "+.github.com",
        "+.openai.com",
        "+.chatgpt.com",
        "+.anthropic.com",
        "+.claude.ai"
      ]
    };
  }

  // 7) 解析策略：按域名指定解析服务器（提高一致性）
  if (!config.dns["nameserver-policy"]) {
    config.dns["nameserver-policy"] = {
      "geosite:cn": [
        "https://223.5.5.5/dns-query",
        "https://doh.pub/dns-query"
      ],
      "geosite:private": [
        "https://223.5.5.5/dns-query",
        "https://doh.pub/dns-query"
      ],
      "geosite:geolocation-!cn": [
        "https://1.1.1.1/dns-query",
        "https://dns.google/dns-query"
      ]
    };
  }

  // 8) Fake-IP 过滤（即便是 redir-host，也保留排除清单）
  if (!config.dns["fake-ip-filter"]) {
    config.dns["fake-ip-filter"] = [
      "*.lan",
      "localhost",
      "*.local",
      "*.localdomain",
      "+.msftconnecttest.com",
      "+.msftncsi.com"
    ];
  }


  // ══════════════════════════════════════════════════════════════════════════
  //                              返回修改后的配置
  // ══════════════════════════════════════════════════════════════════════════

  return config;
}
