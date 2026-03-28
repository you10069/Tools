#!/usr/bin/env bash
set -e

# ============================
# 定义颜色
# ============================
ORANGE="\033[1;33m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🚀 Sing-Panel 一键安装脚本（自动检测最新版本）${RESET}"
echo -e "${ORANGE}==============================================${RESET}"

# ---------------------------------------------------------
# 1. 创建目录
# ---------------------------------------------------------
echo -e "${BLUE}[1/7] 创建目录 /etc/sing-panel ...${RESET}"
mkdir -p /etc/sing-panel

# ---------------------------------------------------------
# 2. 自动检测最新 web-vX 分支
# ---------------------------------------------------------
echo -e "${BLUE}[2/7] 获取最新 web-vX 分支 ...${RESET}"

LATEST_WEB_BRANCH=$(
  curl -s https://api.github.com/repos/you10069/Sing-Panel/branches \
  | grep -o '"name": "web-v[0-9]\+"' \
  | cut -d '"' -f 4 \
  | sort -V \
  | tail -n 1
)

if [[ -z "$LATEST_WEB_BRANCH" ]]; then
  echo -e "${RED}❌ 未找到 web-vX 分支，安装中止。${RESET}"
  exit 1
fi

echo -e "${GREEN}➡️ 最新前端分支: ${LATEST_WEB_BRANCH}${RESET}"

# ---------------------------------------------------------
# 3. 下载前端文件
# ---------------------------------------------------------
echo -e "${BLUE}[3/7] 下载前端 sing-panel.html ...${RESET}"

wget -O /etc/sing-panel/sing-panel.html \
  "https://raw.githubusercontent.com/you10069/Sing-Panel/${LATEST_WEB_BRANCH}/sing-panel.html"

chmod 644 /etc/sing-panel/sing-panel.html
echo -e "${GREEN}✔ 前端文件已更新${RESET}"

# ---------------------------------------------------------
# 4. 自动检测最新后端 release（含 prerelease）
# ---------------------------------------------------------
echo -e "${BLUE}[4/7] 获取最新后端 sing-panel-amd64 ...${RESET}"

LATEST_URL=$(
  curl -s https://api.github.com/repos/you10069/Sing-Panel/releases \
  | grep '"browser_download_url"' \
  | grep 'sing-panel-amd64"' \
  | head -n 1 \
  | cut -d '"' -f 4
)

if [[ -z "$LATEST_URL" ]]; then
  echo -e "${RED}❌ 未找到后端下载地址，安装中止。${RESET}"
  exit 1
fi

echo -e "${GREEN}➡️ 最新后端下载地址: ${LATEST_URL}${RESET}"

# ---------------------------------------------------------
# 5. 下载后端程序
# ---------------------------------------------------------
echo -e "${BLUE}[5/7] 下载后端程序 ...${RESET}"

wget -O /etc/sing-panel/sing-panel "$LATEST_URL"
chmod 755 /etc/sing-panel/sing-panel

echo -e "${GREEN}✔ 后端程序已更新${RESET}"

# ---------------------------------------------------------
# 6. 下载 systemd 服务文件
# ---------------------------------------------------------
echo -e "${BLUE}[6/7] 下载 systemd 服务文件 ...${RESET}"

wget -O /etc/systemd/system/sing-panel.service \
  https://raw.githubusercontent.com/you10069/Tools/main/service/sing-panel.service

chmod 644 /etc/systemd/system/sing-panel.service

echo -e "${GREEN}✔ systemd 服务文件已更新${RESET}"

# ---------------------------------------------------------
# 7. 重载 systemd
# ---------------------------------------------------------
echo -e "${BLUE}[7/7] 重新加载 systemd ...${RESET}"

systemctl daemon-reload

echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🎉 安装完成！你可以启动服务：${RESET}"
echo -e "${ORANGE}  systemctl start sing-panel${RESET}"
echo -e "${ORANGE}  systemctl enable sing-panel${RESET}"
echo -e "${ORANGE}  journalctl -u sing-panel -f --output cat${RESET}"
echo -e "${ORANGE}==============================================${RESET}"
