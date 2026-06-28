#!/usr/bin/env bash
# ============================================================
#  复用器层：tmux 配置 + 插件 + ta 命令 + win32yank
#  tmux 本体一般由 4-dev §1.7 用 apt 装；本脚本第一步会兜底安装。
#  本层独立可跑；不碰终端模拟器 / shell。
#  用法（在 5-terminal/multiplexer/ 目录下）:
#      chmod +x setup.sh && ./setup.sh
# ============================================================
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"          # 5-terminal/multiplexer

echo ""
echo -e "${CYAN}━━━ 复用器：tmux + ta ━━━${NC}"
echo ""

# ─── 1. tmux 本体（4-dev §1.7 一般已装；这里兜底）─────────
info "检查 tmux..."
if command -v tmux &>/dev/null; then
    ok "tmux 已安装: $(tmux -V)"
else
    info "安装 tmux..."
    sudo apt update -qq && sudo apt install -y tmux
    ok "tmux 安装完成: $(tmux -V)"
fi

# ─── 2. tmux 配置 ─────────────────────────────────────────
info "部署 tmux 配置..."
if [[ -f "$HOME/.tmux.conf" && ! -f "$HOME/.tmux.conf.bak" ]]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"   # 只在首次备份，避免二次运行用模板覆盖用户原件
    warn "原配置已备份到 ~/.tmux.conf.bak"
fi
cp "${SCRIPT_DIR}/tmux.conf" "$HOME/.tmux.conf"
ok "tmux 配置 → ~/.tmux.conf"

# TPM（裸 clone 在 set -e 下失败会中断全脚本、连累后面的 ta/win32yank；这里兜底 + 清残目录）
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    info "安装 TPM..."
    if git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" 2>/dev/null; then
        ok "TPM 安装完成"
    else
        rm -rf "$HOME/.tmux/plugins/tpm"   # 清掉半截目录，免得下次误判"已存在"
        warn "TPM 克隆失败（网络？），跳过插件；可后续手动: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    fi
else
    ok "TPM 已存在"
fi

# 自动安装 tmux 插件（tmux-sensible / tmux-resurrect / tmux-continuum / tmux-cpu / tmux-battery）
# 注意：进 tmux 后按 Ctrl+A I 的交互式安装有时只装上一个插件，这里直接用
# TPM 的命令行安装脚本，确保 tmux.conf 里声明的插件全部装上。
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
    info "安装 tmux 插件..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 || \
        warn "插件自动安装失败，请执行 ~/.tmux/plugins/tpm/bin/install_plugins"
    ok "tmux 插件安装完成"
fi

# ─── 3. ta 快捷命令 ───────────────────────────────────────
info "部署 ta 快捷命令..."
mkdir -p "$HOME/.local/bin"
[[ -f "$HOME/.local/bin/ta" && ! -f "$HOME/.local/bin/ta.bak" ]] && \
    cp "$HOME/.local/bin/ta" "$HOME/.local/bin/ta.bak"   # 只在首次备份
cp "${SCRIPT_DIR}/ta" "$HOME/.local/bin/ta"
chmod +x "$HOME/.local/bin/ta"
# 确保 ~/.local/bin 在 PATH（ta 装在这里）。bash 总写，已存在的 ~/.zshrc 也写，各自 grep 去重——
# 本层独立可跑、又不部署 zshrc 模板，故不能像 shell 层那样只认 .bashrc。
for _rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ "$_rc" == "$HOME/.zshrc" && ! -f "$_rc" ]] && continue
    if ! grep -qF 'HOME/.local/bin' "$_rc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$_rc"
        warn "已将 ~/.local/bin 加入 PATH（${_rc##*/}，重启终端生效）"
    fi
done
ok "ta 命令就绪"

# ─── 4. win32yank（修复 tmux 复制中文乱码）────────────────
# tmux.conf 的复制绑定（复制模式里按 y / 鼠标拖选）直接调用 win32yank.exe，
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

echo ""
echo -e "${GREEN}━━━ 复用器层配置完成 ━━━${NC}"
echo ""
echo "验证: ta test   → 创建并连入名为 test 的会话"
echo "      Ctrl+A d 退出, ta kill test 关闭"
echo ""
