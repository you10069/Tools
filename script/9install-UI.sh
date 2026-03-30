#!/usr/bin/env bash

# ============================
#   Color
# ============================
BLUE="\033[34m"
ORANGE="\033[38;5;208m"
YELLOW="\033[33m"
RED="\033[31m"
GREEN="\033[32m"
RESET="\033[0m"

UI_DIR="/etc/sing-box/ui"

# ============================
#   Big Title (Start)
# ============================
echo -e "${ORANGE}"
echo "==============================================="
echo "==              Clash面板 快速安装           =="
echo "==============================================="
echo -e "${RESET}"

# ============================
#   Step Header
# ============================
step() {
    echo -e "${BLUE}\n[$1/$2] $3${RESET}"
}

TOTAL=4

# ============================
#   Step 1: 选择面板
# ============================
step 1 $TOTAL "请选择要安装的面板"

echo -e "${YELLOW}1.${RESET} Zash 面板（默认）"
echo -e "${YELLOW}2.${RESET} MetaCubeXD 面板（XD）"

echo -e "${BLUE}请选择你要安装的面板编号${RESET}"
read -p "$(echo -e ${YELLOW}请输入编号（1 或 2）：${RESET}) " choice
choice=${choice:-1}

if [[ "$choice" == "1" ]]; then
    PANEL_NAME="Zash"
    PANEL_URL="https://github.com/Zephyruso/zashboard/releases/latest/download/dist.zip"
elif [[ "$choice" == "2" ]]; then
    PANEL_NAME="MetaCubeXD"
    PANEL_URL="https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip"
else
    echo -e "${RED}无效选项，退出。${RESET}"
    exit 1
fi

echo -e "${GREEN}已选择：${PANEL_NAME}${RESET}"

# ============================
#   Step 2: 准备目录
# ============================
step 2 $TOTAL "准备目录"

echo -e "${BLUE}创建目录：${UI_DIR}${RESET}"
mkdir -p "$UI_DIR"

echo -e "${BLUE}清空旧文件...${RESET}"
rm -rf "${UI_DIR:?}"/*

# ============================
#   Step 3: 下载面板
# ============================
step 3 $TOTAL "下载 ${PANEL_NAME} 面板"

TMP_ZIP="/tmp/ui.zip"

echo -e "${BLUE}下载中...${RESET}"
wget -qO "$TMP_ZIP" "$PANEL_URL"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}下载失败，请检查网络或 URL。${RESET}"
    exit 1
fi

echo -e "${GREEN}下载成功${RESET}"

# ============================
#   Step 4: 安装面板
# ============================
step 4 $TOTAL "安装面板"

unzip -q "$TMP_ZIP" -d /tmp/ui_extract

if [[ "$choice" == "1" ]]; then
    mv /tmp/ui_extract/* "$UI_DIR/"
else
    mv /tmp/ui_extract/metacubexd-gh-pages/* "$UI_DIR/"
fi

rm -rf /tmp/ui_extract "$TMP_ZIP"

echo -e "${GREEN}面板已成功安装到：${RESET} ${BLUE}${UI_DIR}${RESET}"
echo -e "${GREEN}你现在可以在 Caddy 中设置 root 指向该目录。${RESET}"

# ============================
#   Big Title (End)
# ============================
echo -e "${ORANGE}"
echo "==============================================="
echo "==              Clash面板 安装完成！         =="
echo "==============================================="
echo -e "${RESET}"
