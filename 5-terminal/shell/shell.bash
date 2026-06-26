# ============================================================
#  WSL_Setup 终端 shell 层
#  把 4-dev §1.7 装的工具真正接进 bash：
#    starship 提示符 / zoxide / fzf 键位 / 现代别名 / 大历史与多 pane 共享
#  由 5-terminal/shell/setup.sh 部署，并在 ~/.bashrc 末尾 source 本文件。
#  仅作用于交互式 shell；每段都先探测命令存在再启用，缺哪个跳哪个，不报错。
# ============================================================

# ─── 历史：放大缓冲（多 pane 实时共享的 PROMPT_COMMAND 见文件末尾）─
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups          # 去重 + 忽略前导空格的命令
shopt -s histappend                        # 追加而非覆盖历史文件

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
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# ─── fzf：Ctrl+R 模糊搜历史 / Ctrl+T 选文件 / Alt+C 跳目录 ─
# Ubuntu 的 fzf deb 不会自动启用键位，必须显式加载。
if command -v fzf >/dev/null 2>&1; then
    if fzf --bash >/dev/null 2>&1; then
        eval "$(fzf --bash)"                                              # fzf ≥0.48
    else
        [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && \
            source /usr/share/doc/fzf/examples/key-bindings.bash          # Ubuntu 24.04 (fzf 0.44)
        [ -f /usr/share/bash-completion/completions/fzf ] && \
            source /usr/share/bash-completion/completions/fzf
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

# ─── starship 提示符（必须最后 eval，覆盖默认 PS1）────────
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# ─── 历史多 pane / 多终端 实时共享 ───────────────────────
# 必须放在 starship 之后：starship 会把 PROMPT_COMMAND 重写成 starship_precmd
# 且不保留旧值，所以这里再把历史同步前置进去——每次出提示符前先把本 pane 的
# 新命令写入历史文件(-a)，再读回其它 pane 刚写入的(-n)。case 去重，重复 source 不叠加。
case "${PROMPT_COMMAND:-}" in
    *"history -a"*) : ;;
    *) PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
