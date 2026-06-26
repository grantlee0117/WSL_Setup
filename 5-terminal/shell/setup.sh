#!/usr/bin/env bash
# ============================================================
#  shell 层：starship 提示符 + zoxide/fzf/别名/历史接线 + zsh + oh-my-zsh
#  日常交互用 zsh；脚本仍走 bash（解释器由各自 shebang 决定，与登录 shell 无关）。
#  zoxide/fzf/eza/bat 本体由 4-dev §1.7 安装，本脚本只负责把它们接进 shell。
#  本层独立可跑；不碰终端模拟器 / tmux。
#  用法（在 5-terminal/shell/ 目录下）:
#      chmod +x setup.sh && ./setup.sh
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"          # 5-terminal/shell

echo ""
echo -e "${CYAN}━━━ shell：starship + zsh + oh-my-zsh ━━━${NC}"
echo ""

# ─── 1. starship 提示符（装到 ~/.local/bin，免 sudo）──────
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
# 确保 ~/.local/bin 在 PATH（starship 装在这里）；这一行追加在 shell.bash 的 source
# 行之前，bash 起来时才找得到 starship。zsh 侧由部署的 ~/.zshrc 模板自带 PATH 行。
if ! grep -qF 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    warn "已将 ~/.local/bin 加入 PATH（~/.bashrc，重启终端生效）"
fi

# ─── 2. bash 接线层（starship / zoxide / fzf / 别名 / 历史）─
mkdir -p "$HOME/.config/wsl-setup"
cp "${SCRIPT_DIR}/shell.bash" "$HOME/.config/wsl-setup/shell.bash"
ok "shell 片段 → ~/.config/wsl-setup/shell.bash"
if [[ -f "$HOME/.config/starship.toml" && ! -f "$HOME/.config/starship.toml.bak" ]]; then
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak"   # 只在首次备份
    warn "原 starship 配置已备份到 ~/.config/starship.toml.bak"
fi
cp "${SCRIPT_DIR}/starship.toml" "$HOME/.config/starship.toml"
ok "starship 配置 → ~/.config/starship.toml"
# 在 ~/.bashrc 末尾 source（shell.bash 是 bash 语法，固定写进 .bashrc）
if ! grep -qF 'wsl-setup/shell.bash' "$HOME/.bashrc" 2>/dev/null; then
    printf '\n# WSL_Setup 终端 shell 层（starship / zoxide / fzf / 别名 / 历史）\nsource ~/.config/wsl-setup/shell.bash\n' >> "$HOME/.bashrc"
    ok "已写入 ~/.bashrc 的 source 行"
else
    ok "source 行已在 ~/.bashrc（跳过）"
fi

# ─── 3. zsh + oh-my-zsh（日常交互用 zsh；脚本仍走 bash）────
info "配置 zsh + oh-my-zsh..."
# 3a. zsh 本体
if command -v zsh &>/dev/null; then
    ok "zsh 已安装: $(zsh --version)"
else
    info "安装 zsh..."
    sudo apt update -qq && sudo apt install -y zsh
    ok "zsh 安装完成: $(zsh --version)"
fi
# 3b. oh-my-zsh（无人值守：不自动 chsh / 不自动启动 zsh / 不动 .zshrc——这三件我们自己来）
# 以「装完后 ~/.oh-my-zsh 是否存在」判断成败，而非装脚本退出码：curl 拉取失败时
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
# 3c. 两个外部插件：autosuggestions（灰字补全）+ syntax-highlighting（命令高亮）
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
# 3d. 部署 shell.zsh 与 .zshrc
cp "${SCRIPT_DIR}/shell.zsh" "$HOME/.config/wsl-setup/shell.zsh"
ok "zsh 接线层 → ~/.config/wsl-setup/shell.zsh"
if [[ -f "$HOME/.zshrc" && ! -f "$HOME/.zshrc.bak" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"   # 只在首次备份，避免二次运行用模板覆盖用户原件
    warn "原 .zshrc 已备份到 ~/.zshrc.bak"
fi
cp "${SCRIPT_DIR}/zshrc" "$HOME/.zshrc"
ok ".zshrc → ~/.zshrc"
# 3e. 默认登录 shell 换成 zsh（sudo 改，免输 user 密码；重开终端生效）
ZSH_BIN="$(command -v zsh || true)"   # || true: 否则 set -e 会在空值判断前就退出
if [[ -z "$ZSH_BIN" ]]; then
    warn "找不到 zsh，跳过切换默认 shell"
elif [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$ZSH_BIN" ]]; then
    ok "默认 shell 已是 zsh"
elif sudo chsh -s "$ZSH_BIN" "$USER" 2>/dev/null; then
    ok "默认 shell → zsh（重开终端生效）"
else
    warn "chsh 失败，可手动执行: chsh -s $ZSH_BIN"
fi

echo ""
echo -e "${GREEN}━━━ shell 层配置完成 ━━━${NC}"
echo ""
echo "  • 重开终端 → 默认进 zsh（灰字补全 / 命令高亮 / starship）"
echo "  • 想先在当前 bash 会话试 bash 层: source ~/.bashrc"
echo "  • 脚本仍走 bash：本仓脚本都带 bash shebang，与登录 shell 无关"
echo ""
