-- ============================================================
--  WezTerm 配置
--  配色: Catppuccin Mocha | 字体: JetBrainsMono Nerd Font
--  场景: WSL2 开发 / Claude Code / Night-Night
-- ============================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─── 字体 ───────────────────────────────────────────────
-- 字体回退链：渲染某字符时，主字体没有就按顺序往下找。
-- 第一只 = 等宽主字体（自带 Nerd Font 图标）；最后一只 = 中文兜底。
-- 中文兜底想换，改下面那只 family 名即可（存盘即生效）：
--   "Microsoft YaHei" —— 微软雅黑，所有 Windows 都自带，换任何机器都在（默认，最稳）。
--   想要别的中文字形，就填一只“系统里已装好”的 family 名（先在「设置 → 字体」确认装了再填）：
--     "DengXian"（等线）、"SimHei"（黑体）—— 来自 Windows「简体中文补充字体」可选功能 / 中文语言包；
--                                          干净的英文版 Windows 默认没有，要去「设置 → 应用 → 可选功能」装。
--     "Noto Sans SC"（思源黑体）—— 不一定自带：微软近年更新给 Win10 / Win11 都推过 Noto CJK，但主要是当
--                                  回退字体塞进去的，各机器是否以此名出现在字体列表里并不一致；以「设置 → 字体」
--                                  里实际有没有为准，没有就自行从 Google Fonts 下载安装。
-- 切记 family 名要和系统里登记的完全一致：写错（例如写成另一只 family "Noto Sans CJK SC"）会静默匹配失败，
-- 退回 WezTerm 自带兜底、启动还多一条 missing-font 警告——本配置早先就踩过这个坑。
config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font", weight = "Medium" },
	"Microsoft YaHei", -- 中文回退，想换见上方注释
})
config.font_size = 12.0
config.line_height = 1.15

-- 缺字告警（哨兵，保持默认开着 = true）：某个字符所有字体都渲染不出来时，WezTerm 会弹一个"配置错误"
-- 提示窗、指向字体配置文档。它正是当初帮我们发现"中文回退字体名写错"的那个信号，所以特意留着、不关。
-- 真嫌烦想静默：取消下一行注释设 false——但从此缺字也不再提示，等于撤掉哨兵，一般别动。
-- config.warn_about_missing_glyphs = false

-- 关闭编程连字：默认字体会把 != >= -> == 等组合渲染成单个"合体"字形，终端里容易和等宽对齐 / 选中复制对不上，
-- 这里用 calt / clig / liga = 0 全关掉，保持一个字符占一个格。想开就把对应项改成 =1（见 README 微调·编程连字）。
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- ─── 配色 (Catppuccin Mocha) ────────────────────────────
-- WezTerm 内置数百套配色，名字见官方配色表。注意 tmux 状态栏、starship 提示符也都配成了 Catppuccin Mocha，
-- 只改这一处会让三者不一致（见 README 微调·配色）。
config.color_scheme = "Catppuccin Mocha"

-- 半透明 + Acrylic 毛玻璃（两行配套：Acrylic 要 opacity < 1.0 才出效果；
-- opacity 设 1.0 即完全不透明，毛玻璃自动关闭）
config.window_background_opacity = 0.5
config.win32_system_backdrop = "Acrylic"

-- ─── 窗口 ───────────────────────────────────────────────
config.initial_cols = 140    -- 开窗初始宽度（列 = 能放多少个字符）
config.initial_rows = 40     -- 开窗初始高度（行）
config.window_padding = { left = 8, right = 8, top = 4, bottom = 4 }  -- 文字到窗口四边的内边距（像素）
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"  -- 去掉系统标题栏、把最小化/关闭等按钮集成进窗口，仍可拖边改大小
config.window_close_confirmation = "NeverPrompt"  -- 关窗口不弹"确认关闭"（里面的活交给 tmux 保活，不怕误关）
-- 改字号时不重算窗口尺寸（默认 true 会跟着缩放，按 Ctrl+Shift+↑/↓ 时窗口乱跳）
config.adjust_window_size_when_changing_font_size = false

-- 光标样式（纯审美，本配置不改、用默认的稳定方块）。想换：取消下面那行注释、把值改成想要的——
--   SteadyBlock     稳定方块（默认）
--   BlinkingBlock   闪烁方块
--   SteadyUnderline / BlinkingUnderline   下划线（稳定 / 闪烁）
--   SteadyBar / BlinkingBar               竖条（稳定 / 闪烁）
-- （Steady = 不闪，Blinking = 闪烁。）
-- config.default_cursor_style = "SteadyBlock"

-- ─── Tab 栏 ─────────────────────────────────────────────
-- WezTerm 的 Tab = 终端窗口层的多个独立标签页（Ctrl+Shift+T 新建、Alt+1~5 切换），
-- 和 tmux 管的「同一标签页内部的 pane 分屏 / 会话恢复」是两套东西、互不冲突。
config.hide_tab_bar_if_only_one_tab = true  -- 只有 1 个 Tab 时隐藏 Tab 栏、平时不占地方；开第 2 个 Tab 才显示
config.tab_bar_at_bottom = true             -- Tab 栏放底部；开 ≥2 个 Tab 时它会和 tmux 状态栏一起叠在底部（正常）
config.use_fancy_tab_bar = false            -- 朴素文字 Tab 栏，不用花哨渲染（更省资源、更贴终端风格）
-- 想彻底不要 WezTerm 这条 Tab 栏：config.enable_tab_bar = false（Tab 功能仍在、只是没有可视栏）

-- ─── 默认启动 WSL ────────────────────────────────────────
-- 开窗直接进这个 WSL 发行版（而不是 Windows 的 cmd / PowerShell）。
-- setup.sh 部署时会按本机实际发行版名（WSL_DISTRO_NAME）改写这行；装了多个发行版时，这里决定默认进哪个。
config.default_domain = "WSL:Ubuntu-24.04"

-- ─── 滚动 ───────────────────────────────────────────────
config.scrollback_lines = 100000   -- 每个 pane 往上能翻多少行历史（10 万行；越大越吃内存）
config.enable_scroll_bar = false   -- 不显示右侧滚动条（用滚轮 / Shift+PageUp 翻历史）

-- ─── 快捷键 ─────────────────────────────────────────────
config.keys = {
	-- Ctrl+Shift+T: 新 Tab
	{ key = "t", mods = "CTRL|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	-- Ctrl+Shift+W: 关闭 Tab
	{ key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
	-- Ctrl+Shift+F: 搜索
	{ key = "f", mods = "CTRL|SHIFT", action = wezterm.action.Search("CurrentSelectionOrEmptyString") },
	-- Ctrl+Shift+C/V: 复制粘贴
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
	-- Alt+数字: 切换 Tab
	{ key = "1", mods = "ALT", action = wezterm.action.ActivateTab(0) },
	{ key = "2", mods = "ALT", action = wezterm.action.ActivateTab(1) },
	{ key = "3", mods = "ALT", action = wezterm.action.ActivateTab(2) },
	{ key = "4", mods = "ALT", action = wezterm.action.ActivateTab(3) },
	{ key = "5", mods = "ALT", action = wezterm.action.ActivateTab(4) },
	-- Ctrl+Shift+上/下: 调整字体大小
	{ key = "UpArrow", mods = "CTRL|SHIFT", action = wezterm.action.IncreaseFontSize },
	{ key = "DownArrow", mods = "CTRL|SHIFT", action = wezterm.action.DecreaseFontSize },
}

-- ─── 鼠标 ───────────────────────────────────────────────
config.mouse_bindings = {
	-- 右键粘贴
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.PasteFrom("Clipboard"),
	},
}

-- ─── 性能 ───────────────────────────────────────────────
config.front_end = "WebGpu"
-- WebGpu 默认挑低功耗核显渲染（webgpu_power_preference 默认 "LowPower"）：终端只画文字，核显完全够用、
-- 省电省热。双显卡笔记本想强制独显，取消下一行注释（代价：独显常驻、更费电更热，终端场景一般无必要）：
-- config.webgpu_power_preference = "HighPerformance"
config.animation_fps = 60
config.max_fps = 120

-- ─── 杂项 ───────────────────────────────────────────────
config.audible_bell = "Disabled"  -- 关掉响铃：程序输出 BEL（\a）时不发系统提示音（终端里很常被触发，烦）
-- WezTerm 由 winget 安装，更新统一交给 `winget upgrade` 管，这里关掉 WezTerm 自带的联网更新检查。
-- （设 true 时它也只会联网查、弹一个"有新版"的提示，并不会自动下载安装；和 winget 那套属于重复。）
config.check_for_updates = false
config.automatically_reload_config = true  -- 改本文件一存盘就热重载、立即生效，不用重开 WezTerm
config.unicode_version = 14                -- 按 Unicode 14 规则算字符显示宽度（影响 emoji / 中文等宽对齐是否准）

return config
