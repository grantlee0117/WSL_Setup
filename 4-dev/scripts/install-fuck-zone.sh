#!/bin/bash
# 一键安装 fuck-zone 命令到 WSL
# 用法: bash install-fuck-zone.sh
set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="fuck-zone"
SRC="$(dirname "$0")/fuck-zone"

if [ ! -f "$SRC" ]; then
    echo "错误：找不到源脚本 $SRC" >&2
    exit 1
fi

mkdir -p "$INSTALL_DIR"
cp "$SRC" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# 确保 ~/.local/bin 在 PATH 中。
# 以 .bashrc 是否已写入为准（而非当前 shell 的 $PATH），避免在同一终端
# 重复运行时反复向 .bashrc 追加同一行。
if ! grep -qF 'HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    {
        echo ""
        echo "# fuck-zone 命令"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
    } >> "$HOME/.bashrc"
    echo "已将 $INSTALL_DIR 加入 PATH（重开终端或 source ~/.bashrc 生效）"
fi

echo "安装完成！现在可以在任意目录运行: fuck-zone"
