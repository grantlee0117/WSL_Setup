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

# ─── 共用片段：现代别名 + fzf 配色（bash/zsh 同源，见 shell.common.sh）──
[ -f "$HOME/.config/wsl-setup/shell.common.sh" ] && \
    source "$HOME/.config/wsl-setup/shell.common.sh"

# ─── zoxide：智能 cd（`z 关键字` 跳到最常去的目录）────────
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# ─── fzf：Ctrl+R 模糊搜历史 / Ctrl+T 选文件 / Alt+C 跳目录 ─
# Ubuntu 的 fzf deb 不会自动启用键位，必须显式加载（配色见 shell.common.sh）。
if command -v fzf >/dev/null 2>&1; then
    if fzf --bash >/dev/null 2>&1; then
        eval "$(fzf --bash)"                                              # fzf ≥0.48
    else
        [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && \
            source /usr/share/doc/fzf/examples/key-bindings.bash          # Ubuntu 24.04 (fzf 0.44)
        [ -f /usr/share/bash-completion/completions/fzf ] && \
            source /usr/share/bash-completion/completions/fzf
    fi
fi

# ─── starship 提示符（必须最后 eval，覆盖默认 PS1）────────
command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"

# ─── 历史多 pane / 多终端 实时共享 ───────────────────────
# 每次出提示符前：先把本 pane 的新命令写进历史文件(-a)，再读回其它 pane 刚写入的(-n)，
# 这样多个 pane / 终端的历史实时互通。
# 用 prepend 挂到 PROMPT_COMMAND（而非直接赋值），是为了和 starship 的 starship_precmd
# 以及任何已有的 PROMPT_COMMAND 共存：starship 1.x 会保留原有的 PROMPT_COMMAND（转存到
# STARSHIP_PROMPT_COMMAND，在 starship_precmd 内照常执行），所以放在 starship init 之后
# 也不会被它挤掉。case 守卫：重复 source 本文件时不叠加 history -a。
case "${PROMPT_COMMAND:-}" in
    *"history -a"*) : ;;
    *) PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac
