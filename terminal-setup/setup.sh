#!/usr/bin/env bash
# ============================================================
#  WezTerm + tmux + Nerd Font 一键配置
#  用法: chmod +x setup.sh && ./setup.sh
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  终端工具链配置${NC}"
echo -e "${CYAN}  Catppuccin Mocha + JetBrainsMono + tmux${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ─── 1. tmux ──────────────────────────────────────────────
info "检查 tmux..."
if command -v tmux &>/dev/null; then
    ok "tmux 已安装: $(tmux -V)"
else
    info "安装 tmux..."
    sudo apt update -qq && sudo apt install -y tmux
    ok "tmux 安装完成: $(tmux -V)"
fi

# ─── 2. Nerd Font ─────────────────────────────────────────
FONT_NAME="JetBrainsMono"
FONT_DIR="${WIN_HOME}/AppData/Local/Microsoft/Windows/Fonts"

info "检查 JetBrainsMono Nerd Font..."
if ls "${FONT_DIR}"/${FONT_NAME}Nerd* &>/dev/null 2>&1; then
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

# ─── 3. tmux 配置 ─────────────────────────────────────────
info "部署 tmux 配置..."
if [[ -f "$HOME/.tmux.conf" ]]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
    warn "原配置已备份到 ~/.tmux.conf.bak"
fi
cp "${SCRIPT_DIR}/tmux.conf" "$HOME/.tmux.conf"
ok "tmux 配置 → ~/.tmux.conf"

# TPM
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    info "安装 TPM..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null
    ok "TPM 安装完成"
else
    ok "TPM 已存在"
fi

# 自动安装 tmux 插件（tmux-sensible / tmux-resurrect / tmux-continuum）
# 注意：进 tmux 后按 Ctrl+A I 的交互式安装有时只装上一个插件，这里直接用
# TPM 的命令行安装脚本，确保 tmux.conf 里声明的插件全部装上。
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
    info "安装 tmux 插件..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || \
        warn "插件自动安装失败，请进 tmux 后手动执行 ~/.tmux/plugins/tpm/bin/install_plugins"
    ok "tmux 插件安装完成"
fi

# ─── 4. WezTerm 配置 ──────────────────────────────────────
info "部署 WezTerm 配置..."
cp "${SCRIPT_DIR}/wezterm.lua" "${WIN_HOME}/.wezterm.lua"
ok "WezTerm 配置 → ${WIN_HOME}/.wezterm.lua"

# ─── 5. ta 快捷命令 ───────────────────────────────────────
info "部署 ta 快捷命令..."
mkdir -p "$HOME/.local/bin"
cp "${SCRIPT_DIR}/ta" "$HOME/.local/bin/ta"
chmod +x "$HOME/.local/bin/ta"

if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    SHELL_RC="$HOME/.bashrc"
    [[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${SHELL_RC}"
    warn "已将 ~/.local/bin 加入 PATH (重启终端生效)"
fi
ok "ta 命令就绪"

# ─── 完成 ─────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  配置完成!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "接下来:"
echo ""
echo "  1. 安装字体 (如果刚才下载了):"
echo "     打开 ${FONT_DIR}"
echo "     全选 .ttf → 右键 → 为所有用户安装"
echo ""
echo "  2. 关闭 WezTerm，重新打开 → 自动进入 WSL"
echo ""
echo "  3. 首次进入 tmux 后按 Ctrl+A I 安装插件"
echo ""
echo "  4. 试试:"
echo "     ta dev          → 创建 dev 会话"
echo "     Ctrl+A \"        → 上下分屏"
echo "     Ctrl+A %        → 左右分屏"
echo "     Ctrl+A h/j/k/l  → 切换 pane"
echo "     Ctrl+A d         → 后台挂起"
echo "     ta               → 重新连接"
echo ""
