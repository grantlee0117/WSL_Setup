# ============================================================
#  WSL_Setup 终端 shell 层（zsh）
#  与 shell.bash 同责：把 4-dev §1.7 装的工具接进 zsh——
#    starship 提示符 / zoxide / fzf 键位 / 现代别名 / 大历史
#  外加 zsh 专属：autosuggestions（灰字补全）+ syntax-highlighting（命令高亮）。
#  由 5-terminal/setup.sh 部署，并在 ~/.zshrc 末尾 source 本文件。
#  仅作用于交互式 shell；每段都先探测命令/文件存在再启用，缺哪个跳哪个，不报错。
#
#  与 oh-my-zsh 的分工：omz 只管它的内置插件（git/sudo/...，见 ~/.zshrc 的 plugins）；
#  工具接线（zoxide/fzf/starship/别名）全留在这里，和 bash 侧一一对称——所以
#  zoxide/fzf 不放进 omz 的 plugins，避免重复初始化。
# ============================================================

# ─── 历史：放大缓冲（多 pane 实时共享靠 zsh 的 SHARE_HISTORY，omz 已开，这里兜底）─
: "${HISTFILE:=$HOME/.zsh_history}"   # omz 会设此值；万一 omz 没装上，这里兜底，否则历史不落盘
HISTSIZE=100000
SAVEHIST=200000                 # 落盘上限与 shell.bash 的 HISTFILESIZE=200000 对齐
setopt SHARE_HISTORY            # 一个 pane 敲的命令，另一个按 ↑ 立刻能翻到
setopt HIST_IGNORE_ALL_DUPS     # 去重
setopt HIST_IGNORE_SPACE        # 忽略前导空格的命令

# ─── 现代命令别名（4-dev §1.7 装的替代品，仅交互式生效）──
if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first --git'
    alias la='eza -a --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons --group-directories-first'
fi
# Ubuntu 把命令改名为 batcat/fdfind，给回惯用名（若 4-dev 已建软链则二者并存无害）
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'

# ─── zoxide：智能 cd（`z 关键字` 跳到最常去的目录）────────
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# ─── fzf：Ctrl+R 模糊搜历史 / Ctrl+T 选文件 / Alt+C 跳目录 ─
# Ubuntu 的 fzf deb 不会自动启用键位，必须显式加载。
if command -v fzf >/dev/null 2>&1; then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)                                              # fzf ≥0.48（键位+补全一并给）
    else
        [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && \
            source /usr/share/doc/fzf/examples/key-bindings.zsh          # Ubuntu 24.04 (fzf 0.44)
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
            source /usr/share/doc/fzf/examples/completion.zsh
    fi
    # Catppuccin Mocha 配色，和 WezTerm/tmux 一致
    # 不放 selected-bg：那是 fzf 0.45+ 才认的键，Ubuntu 24.04 的 0.44 一遇到它就整条报错退出，
    # 会连累 Ctrl+R / Ctrl+T / Alt+C 全打不开。等 fzf 升到 0.45+ 再加不迟。
    export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--height 40% --layout=reverse --border"
fi

# ─── starship 提示符（覆盖 omz 主题，故 ~/.zshrc 里 ZSH_THEME 留空）──
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ─── zsh 专属增强（放到最后；语法高亮要求是最后一个 source 的插件）─────
# autosuggestions：按历史给灰字补全，按 → / End 接受整条、Alt+F 接受一个词。
# syntax-highlighting：合法命令绿、错命令红——必须最后 source，否则后挂的部件不被着色。
# 两者由 setup.sh git clone 到 omz 的 custom/plugins 下；缺了就跳过，不报错。
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
    source "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
    source "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
