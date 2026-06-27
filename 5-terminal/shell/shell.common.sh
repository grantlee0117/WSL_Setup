# ============================================================
#  WSL_Setup 终端 shell 层 —— bash / zsh 共用片段
#  只放「与 shell 语法无关、两边一字不差」的部分：现代命令别名 + fzf 配色。
#  由 shell.bash 和 shell.zsh 各自在顶部 source（部署到 ~/.config/wsl-setup/）。
#  改一处两边同步，避免 bash/zsh 两份漂移。
#  注意：zoxide / fzf 键位 / starship 的初始化语法 bash≠zsh，仍各自留在
#  shell.bash / shell.zsh，不放这里。
# ============================================================

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

# ─── fzf 配色：Catppuccin Mocha，和 WezTerm/tmux 一致 ─────
# FZF_DEFAULT_OPTS 是环境变量、fzf 运行时才读，放哪都行，所以归到共用片段；
# 键位加载因 bash/zsh 语法不同，仍各自在 shell.bash / shell.zsh 里处理。
# 不放 selected-bg：那是 fzf 0.45+ 才认的键，Ubuntu 24.04 的 0.44 一遇到它就整条报错退出，
# 会连累 Ctrl+R / Ctrl+T / Alt+C 全打不开。等 fzf 升到 0.45+ 再加不迟。
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--height 40% --layout=reverse --border"
