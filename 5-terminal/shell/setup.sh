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

# deploy_template SRC DEST：把模板 SRC 部署到用户文件 DEST，绝不静默冲掉用户改动。
#   · DEST 不存在        → 直接部署。
#   · DEST 与模板相同    → 重跑而已，无害地再 cp 一次，不备份。
#   · DEST 与模板不同    → 是用户原件或首次部署后又手改过的版本，先备份再覆盖：
#                          备份名首选 DEST.bak；若它已被占用且内容又不同（之前备过别的版本），
#                          退到带时间戳的 DEST.bak.<时间>，避免把上一次的备份覆盖掉。
# 这样既不会把我们自己刚部署的文件错存成 .bak，也不会让二次手改丢失。
deploy_template() {
    local src="$1" dest="$2"
    if [[ -f "$dest" ]] && ! cmp -s "$src" "$dest"; then
        local bak="${dest}.bak"
        if [[ -e "$bak" ]] && ! cmp -s "$dest" "$bak"; then
            bak="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
        fi
        cp "$dest" "$bak"
        warn "$(basename "$dest") 与模板不同，已备份到 $(basename "$bak") 后再覆盖"
    fi
    cp "$src" "$dest"
}

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
    ok "已把 ~/.local/bin 加入 ~/.bashrc 的 PATH（重开终端生效）"
fi

# ─── 2. bash 接线层（starship / zoxide / fzf / 别名 / 历史）─
mkdir -p "$HOME/.config/wsl-setup"
# shell.common.sh / shell.bash / shell.zsh 放在我们托管的 ~/.config/wsl-setup/，
# 用户不该手改（要定制改 shell.bash/shell.zsh 模板再重跑），故直接 cp，不走备份逻辑。
cp "${SCRIPT_DIR}/shell.common.sh" "$HOME/.config/wsl-setup/shell.common.sh"
ok "shell 共用片段（别名 + fzf 配色）→ ~/.config/wsl-setup/shell.common.sh"
cp "${SCRIPT_DIR}/shell.bash" "$HOME/.config/wsl-setup/shell.bash"
ok "bash 接线层 → ~/.config/wsl-setup/shell.bash"
# starship.toml 在 ~/.config/ 下、用户可能手改，走 deploy_template：仅在与模板有别时先备份再覆盖
deploy_template "${SCRIPT_DIR}/starship.toml" "$HOME/.config/starship.toml"
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
SKIP_ZSH=""                                # 置 1 = zsh 没装上，后续 oh-my-zsh / 插件 / 切默认 shell 整体跳过
# 3a. zsh 本体
if command -v zsh &>/dev/null; then
    ok "zsh 已安装: $(zsh --version)"
else
    info "安装 zsh..."
    # 失败不致命：apt 离线 / 被锁 / 取消 sudo 时，跳过 zsh 部分而非被 set -e 整脚本掀翻，
    # 与下面 starship / omz / 插件「失败即 warn、继续」的容错风格保持一致。
    if sudo apt update -qq && sudo apt install -y zsh; then
        ok "zsh 安装完成: $(zsh --version)"
    else
        warn "zsh 安装失败（apt 离线/被锁？），跳过 zsh 部分；bash 层已生效，装好 zsh 后重跑本脚本即可"
        SKIP_ZSH=1
    fi
fi
# 3b. oh-my-zsh（无人值守：不自动 chsh / 不自动启动 zsh / 不动 .zshrc——这三件我们自己来）
# 以「装完后 ~/.oh-my-zsh 是否存在」判断成败，而非装脚本退出码：curl 拉取失败时
# $(...) 为空、sh -c "" 仍退出 0，会假报成功，所以查实际产物更可靠。
if [[ -n "$SKIP_ZSH" ]]; then
    warn "zsh 未装上 → 跳过 oh-my-zsh 与插件（zsh 接线配置仍会部署，装好 zsh 后即生效）"
elif [[ -d "$HOME/.oh-my-zsh" ]]; then
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
# 3d. 部署 shell.zsh 与 .zshrc（即便 zsh 暂时没装上也部署，装好后即生效）
cp "${SCRIPT_DIR}/shell.zsh" "$HOME/.config/wsl-setup/shell.zsh"
ok "zsh 接线层 → ~/.config/wsl-setup/shell.zsh"
# .zshrc 在 ~ 下、用户可能手改，走 deploy_template：仅在与模板有别时先备份（含二次手改）再覆盖
deploy_template "${SCRIPT_DIR}/zshrc" "$HOME/.zshrc"
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
if [[ -n "$SKIP_ZSH" ]]; then
    echo "  • zsh 这次没装上：bash 层已生效，重开终端或 source ~/.bashrc 即有 starship/zoxide/fzf/别名"
    echo "  • 想要 zsh（灰字补全 / 命令高亮）：装好 zsh 后重跑本脚本——zsh 接线配置已就位"
else
    echo "  • 重开终端 → 默认进 zsh（灰字补全 / 命令高亮 / starship）"
    echo "  • 想先在当前 bash 会话试 bash 层: source ~/.bashrc"
fi
echo "  • 脚本仍走 bash：本仓脚本都带 bash shebang，与登录 shell 无关"
echo ""
