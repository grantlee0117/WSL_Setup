#!/usr/bin/env bash
# ============================================================
#  WezTerm + tmux + shell 层 一键配置
#  用法（在 5-terminal/ 目录下）: chmod +x scripts/setup.sh && ./scripts/setup.sh
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # 5-terminal/scripts
CONFIG_DIR="$(cd "${SCRIPT_DIR}/../config" && pwd)"          # 5-terminal/config
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
cp "${CONFIG_DIR}/multiplexer/tmux.conf" "$HOME/.tmux.conf"
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
if [[ -f "${WIN_HOME}/.wezterm.lua" ]]; then
    cp "${WIN_HOME}/.wezterm.lua" "${WIN_HOME}/.wezterm.lua.bak"
    warn "原 WezTerm 配置已备份到 ${WIN_HOME}/.wezterm.lua.bak"
fi
cp "${CONFIG_DIR}/terminal-emulator/wezterm.lua" "${WIN_HOME}/.wezterm.lua"
ok "WezTerm 配置 → ${WIN_HOME}/.wezterm.lua"

# ─── 5. ta 快捷命令 ───────────────────────────────────────
info "部署 ta 快捷命令..."
mkdir -p "$HOME/.local/bin"
[[ -f "$HOME/.local/bin/ta" ]] && cp "$HOME/.local/bin/ta" "$HOME/.local/bin/ta.bak"
cp "${SCRIPT_DIR}/ta" "$HOME/.local/bin/ta"
chmod +x "$HOME/.local/bin/ta"

SHELL_RC="$HOME/.bashrc"
[[ -f "$HOME/.zshrc" ]] && SHELL_RC="$HOME/.zshrc"
# 以 rc 文件内容判断（而非当前 $PATH），与 install-fuck-zone.sh 一致，避免重复追加
if ! grep -qF 'HOME/.local/bin' "$SHELL_RC" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${SHELL_RC}"
    warn "已将 ~/.local/bin 加入 PATH (重启终端生效)"
fi
ok "ta 命令就绪"

# ─── 6. win32yank（修复 tmux 复制中文乱码）────────────────
# tmux.conf 的复制绑定（Ctrl+A y / 鼠标选择）直接调用 win32yank.exe，
# 不装会 command not found、复制中文乱码，所以并进脚本而非留给手动。
info "检查 win32yank..."
if command -v win32yank.exe &>/dev/null; then
    ok "win32yank 已安装"
else
    info "下载 win32yank..."
    YANK_TMP=$(mktemp -d)
    if curl -fsSL -o "${YANK_TMP}/win32yank.zip" \
        https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip; then
        unzip -qo "${YANK_TMP}/win32yank.zip" -d "${YANK_TMP}"
        sudo install -m 0755 "${YANK_TMP}/win32yank.exe" /usr/local/bin/win32yank.exe
        ok "win32yank → /usr/local/bin/"
    else
        warn "win32yank 下载失败，复制功能暂不可用；可后续手动装（见 README）"
    fi
    rm -rf "${YANK_TMP}"
fi

# ─── 7. shell 层（starship 提示符 + zoxide/fzf/别名/历史）──
# 把 4-dev §1.7 装的 zoxide/fzf/eza/bat 等真正接进 bash。
info "配置 shell 层..."
# 7a. starship 提示符（装到 ~/.local/bin，免 sudo）
if command -v starship &>/dev/null; then
    ok "starship 已安装: $(starship --version | head -1)"
else
    info "安装 starship..."
    if curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null 2>&1; then
        ok "starship 安装完成"
    else
        warn "starship 安装失败，shell 层其余部分仍会生效；可后续手动装"
    fi
fi
# 7b. 部署 shell 片段与 starship 配置
mkdir -p "$HOME/.config/wsl-setup"
cp "${CONFIG_DIR}/shell/shell.bash" "$HOME/.config/wsl-setup/shell.bash"
ok "shell 片段 → ~/.config/wsl-setup/shell.bash"
if [[ -f "$HOME/.config/starship.toml" ]]; then
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"
    warn "原 starship 配置已备份到 ~/.config/starship.toml.bak"
fi
cp "${CONFIG_DIR}/shell/starship.toml" "$HOME/.config/starship.toml"
ok "starship 配置 → ~/.config/starship.toml"
# 7c. 在 ~/.bashrc 末尾 source（shell.bash 是 bash 语法，固定写进 .bashrc）
if ! grep -qF 'wsl-setup/shell.bash' "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# WSL_Setup 终端 shell 层（starship / zoxide / fzf / 别名 / 历史）\nsource ~/.config/wsl-setup/shell.bash\n' >> "$HOME/.bashrc"
    ok "已写入 ~/.bashrc 的 source 行"
else
    ok "source 行已在 ~/.bashrc（跳过）"
fi

# ─── 8. zsh + oh-my-zsh（日常交互用 zsh；脚本仍走 bash）────
# 默认登录 shell 换成 zsh，只影响交互式会话。脚本由自身 shebang 决定解释器
# （本仓脚本均带 bash shebang），与登录 shell 无关——所以 ./xxx.sh 照旧走 bash。
info "配置 zsh + oh-my-zsh..."
# 8a. zsh 本体
if command -v zsh &>/dev/null; then
    ok "zsh 已安装: $(zsh --version)"
else
    info "安装 zsh..."
    sudo apt update -qq && sudo apt install -y zsh
    ok "zsh 安装完成: $(zsh --version)"
fi
# 8b. oh-my-zsh（无人值守：不自动 chsh / 不自动启动 zsh / 不动 .zshrc——这三件我们自己来）
# 以「装完后 ~/.oh-my-zsh 是否存在」判断成败，而非装脚本的退出码：curl 拉取失败时
# $(...) 为空、sh -c "" 仍退出 0，会假报成功，所以查实际产物更可靠。
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh 已存在"
else
    info "安装 oh-my-zsh..."
    KEEP_ZSHRC=yes RUNZSH=no CHSH=no sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>&1 || true
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        ok "oh-my-zsh 安装完成"
    else
        warn "oh-my-zsh 安装失败（多半是网络），可后续手动装；zsh 配置仍会部署"
    fi
fi
# 8c. 两个外部插件：autosuggestions（灰字补全）+ syntax-highlighting（命令高亮）
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_zsh_plugin() {   # $1=仓库地址  $2=目录名
    local dest="${ZSH_CUSTOM_DIR}/plugins/$2"
    if [[ -d "$dest" ]]; then
        ok "zsh 插件已存在: $2"
    elif git clone --depth=1 "$1" "$dest" >/dev/null 2>&1; then
        ok "zsh 插件: $2"
    else
        warn "zsh 插件 $2 克隆失败（对应的灰字补全/命令高亮暂不可用）"
    fi
}
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    mkdir -p "${ZSH_CUSTOM_DIR}/plugins"
    clone_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
    clone_zsh_plugin https://github.com/zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting
fi
# 8d. 部署 shell.zsh 与 .zshrc
mkdir -p "$HOME/.config/wsl-setup"
cp "${CONFIG_DIR}/shell/shell.zsh" "$HOME/.config/wsl-setup/shell.zsh"
ok "zsh 接线层 → ~/.config/wsl-setup/shell.zsh"
if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    warn "原 .zshrc 已备份到 ~/.zshrc.bak"
fi
cp "${CONFIG_DIR}/shell/zshrc" "$HOME/.zshrc"
ok ".zshrc → ~/.zshrc"
# 8e. 默认登录 shell 换成 zsh（sudo 改，免输 user 密码；重开终端生效）
ZSH_BIN="$(command -v zsh)"
if [[ -z "$ZSH_BIN" ]]; then
    warn "找不到 zsh，跳过切换默认 shell"
elif [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$ZSH_BIN" ]]; then
    ok "默认 shell 已是 zsh"
elif sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null; then
    ok "默认 shell → zsh（重开终端生效）"
else
    warn "chsh 失败，可手动执行: chsh -s $ZSH_BIN"
fi

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
echo "  2. 关闭 WezTerm，重新打开 → 自动进入 WSL，且默认 shell 已是 zsh"
echo "     → 灰字补全（按 → 接受）、命令绿/红高亮、starship 提示符"
echo "     （脚本仍走 bash：本仓脚本都有 bash shebang，与登录 shell 无关）"
echo ""
echo "  3. 想先在当前 bash 会话试 shell 层：source ~/.bashrc"
echo "     → starship 提示符、z 跳目录、Ctrl+R 模糊搜历史、ll/eza 别名"
echo ""
echo "  4. 试试:"
echo "     ta dev          → 创建 dev 会话"
echo "     Ctrl+A \"        → 上下分屏"
echo "     Ctrl+A %        → 左右分屏"
echo "     Ctrl+A h/j/k/l  → 切换 pane"
echo "     Ctrl+A d         → 后台挂起"
echo "     ta               → 重新连接"
echo ""
