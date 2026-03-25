#!/bin/bash
# 一键安装 fuck-zone 命令到 WSL
# 用法: bash install-fuck-zone.sh

INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="fuck-zone"

mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/fuck-zone" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# 确保 ~/.local/bin 在 PATH 中
if ! echo "$PATH" | grep -q "$INSTALL_DIR"; then
    echo "" >> "$HOME/.bashrc"
    echo "# fuck-zone 命令" >> "$HOME/.bashrc"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "已将 $INSTALL_DIR 加入 PATH（重开终端或 source ~/.bashrc 生效）"
fi

echo "安装完成！现在可以在任意目录运行: fuck-zone"
