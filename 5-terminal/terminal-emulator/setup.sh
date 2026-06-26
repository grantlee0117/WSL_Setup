#!/usr/bin/env bash
# ============================================================
#  终端模拟器层：WezTerm 配置 + Nerd Font
#  本层独立可跑；只部署配置与下载字体，不碰 tmux / shell。
#  用法（在 5-terminal/terminal-emulator/ 目录下）:
#      chmod +x setup.sh && ./setup.sh
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"          # 5-terminal/terminal-emulator
WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"

echo ""
echo -e "${CYAN}━━━ 终端模拟器：WezTerm + Nerd Font ━━━${NC}"
echo ""

# ─── 1. Nerd Font ─────────────────────────────────────────
# 字体由本层负责：shell 的 starship、tmux 的状态栏图标都依赖它。
FONT_NAME="JetBrainsMono"
FONT_DIR="${WIN_HOME}/AppData/Local/Microsoft/Windows/Fonts"

info "检查 JetBrainsMono Nerd Font..."
if ls "${FONT_DIR}"/${FONT_NAME}Nerd* &>/dev/null; then
    ok "字体已安装"
else
    info "下载 JetBrainsMono Nerd Font..."
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    TEMP_DIR=$(mktemp -d)
    if curl -fsSL -o "${TEMP_DIR}/font.zip" "${FONT_URL}"; then
        unzip -qo "${TEMP_DIR}/font.zip" -d "${TEMP_DIR}/fonts"
        mkdir -p "${FONT_DIR}"
        cp "${TEMP_DIR}"/fonts/*.ttf "${FONT_DIR}/" 2>/dev/null || true
        ok "字体已下载到: ${FONT_DIR}"
        warn "请在 Windows 中: 全选 .ttf 文件 → 右键 → 为所有用户安装"
    else
        warn "下载失败，请手动下载: ${FONT_URL}"
    fi
    rm -rf "${TEMP_DIR}"
fi

# ─── 2. WezTerm 配置 ──────────────────────────────────────
info "部署 WezTerm 配置..."
if [[ -f "${WIN_HOME}/.wezterm.lua" && ! -f "${WIN_HOME}/.wezterm.lua.bak" ]]; then
    cp "${WIN_HOME}/.wezterm.lua" "${WIN_HOME}/.wezterm.lua.bak"   # 只在首次备份，避免二次运行用模板覆盖用户原件
    warn "原 WezTerm 配置已备份到 ${WIN_HOME}/.wezterm.lua.bak"
fi
# wezterm.lua 模板里 default_domain 写死 Ubuntu-24.04；部署时按本机实际发行版名替换，
# 否则发行版名一对不上，WezTerm 开窗就 domain not found、进不了 WSL。
WSL_DISTRO="${WSL_DISTRO_NAME:-Ubuntu-24.04}"
sed "s|^config.default_domain = .*|config.default_domain = \"WSL:${WSL_DISTRO}\"|" \
    "${SCRIPT_DIR}/wezterm.lua" > "${WIN_HOME}/.wezterm.lua"
ok "WezTerm 配置 → ${WIN_HOME}/.wezterm.lua（default_domain = WSL:${WSL_DISTRO}）"

echo ""
echo -e "${GREEN}━━━ 终端模拟器层配置完成 ━━━${NC}"
echo ""
echo "接下来:"
echo "  1. 安装字体（如果刚下载了）: 打开 ${FONT_DIR}"
echo "     全选 .ttf → 右键 → 为所有用户安装（只下载不算装上）"
echo "  2. 关闭 WezTerm 重新打开 → 自动进 WSL，加载新主题/字体"
echo ""
