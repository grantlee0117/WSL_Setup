-- ============================================================
--  WezTerm 配置
--  配色: Catppuccin Mocha | 字体: JetBrainsMono Nerd Font
--  场景: WSL2 开发 / Claude Code / Night-Night
-- ============================================================
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─── 字体 ───────────────────────────────────────────────
config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font", weight = "Medium" },
	"Noto Sans CJK SC", -- 中文回退
})
config.font_size = 12.0
config.line_height = 1.15

-- 关闭连字
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- ─── 配色 (Catppuccin Mocha) ────────────────────────────
config.color_scheme = "Catppuccin Mocha"

-- 半透明 + Acrylic 毛玻璃
config.window_background_opacity = 0.5
config.win32_system_backdrop = "Acrylic"

-- ─── 窗口 ───────────────────────────────────────────────
config.initial_cols = 140
config.initial_rows = 40
config.window_padding = { left = 8, right = 8, top = 4, bottom = 4 }
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_close_confirmation = "NeverPrompt"

-- Tab 栏
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false

-- ─── 默认启动 WSL ────────────────────────────────────────
config.default_domain = "WSL:Ubuntu-24.04"

-- ─── 滚动 ───────────────────────────────────────────────
config.scrollback_lines = 100000
config.enable_scroll_bar = false

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
config.animation_fps = 60
config.max_fps = 120

-- ─── 杂项 ───────────────────────────────────────────────
config.audible_bell = "Disabled"
config.check_for_updates = true
config.automatically_reload_config = true
config.unicode_version = 14

return config
