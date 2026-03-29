#!/usr/bin/env bash
set -e

# ============================
# 定义颜色
# ============================
ORANGE="\033[1;33m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;35m"
RESET="\033[0m"

echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🚀 Sing-Box 一键安装脚本（自动检测最新构建）${RESET}"
echo -e "${ORANGE}==============================================${RESET}"

# ---------------------------------------------------------
# [1/8] CPU 指令集检测
# ---------------------------------------------------------
echo -e "${BLUE}[1/8] 检测 CPU 指令集支持情况 ...${RESET}"
echo

flags=$(grep -m1 flags /proc/cpuinfo)
supports() { echo "$flags" | grep -qw "$1"; }

print_flag() {
    if supports "$1"; then
        printf "%b\n" "  ${GREEN}$1 ✔${RESET}"
    else
        printf "%b\n" "  ${RED}$1 ✘${RESET}"
    fi
}

echo -e "${YELLOW}CPU 指令集支持情况：${RESET}"

echo -e "${YELLOW}v2:${RESET}"
for f in aes ssse3 sse4_1 sse4_2 popcnt cx16 lahf_lm; do print_flag "$f"; done

echo -e "${YELLOW}v3:${RESET}"
for f in avx avx2 bmi1 bmi2 fma movbe xsave lzcnt osxsave; do print_flag "$f"; done

echo -e "${YELLOW}v4:${RESET}"
for f in avx512f avx512bw avx512cd avx512dq avx512vl; do print_flag "$f"; done

level=1
supports sse4_2 && level=2
supports avx2 && level=3
supports avx512f && level=4

echo
echo -e "${ORANGE}Your CPU supports: GOAMD64=v${level}${RESET}"
echo

# ---------------------------------------------------------
# [2/8] 选择 CPU 架构（v1 / v2 / v3）
# ---------------------------------------------------------
echo -e "${BLUE}[2/8] 请选择 Sing-Box CPU 架构 ...${RESET}"
echo -e "${YELLOW}  1) v1（最低要求）${RESET}"
echo -e "${YELLOW}  2) v2（推荐）${RESET}"
echo -e "${YELLOW}  3) v3（高性能）${RESET}"
echo -en "${BLUE}请输入数字选择： ${RESET}"
read -r CPU_CHOICE

case "$CPU_CHOICE" in
    1) CPU="v1" ;;
    2) CPU="v2" ;;
    3) CPU="v3" ;;
    *) echo -e "${RED}❌ 无效选择${RESET}"; exit 1 ;;
esac

TARGET_BIN="sing-box-${CPU}-all"
echo -e "${YELLOW}✔ 目标构建：${TARGET_BIN}${RESET}"

# ---------------------------------------------------------
# [3/8] 输入 sb 版本号（自动补 v）
# ---------------------------------------------------------
echo -e "${BLUE}[3/8] 请输入 sb 版本号 ...${RESET}"
echo -en "${BLUE}请输入 sb 版本号（默认 v1.12.25）：${RESET}"
read -r SB_VER

SB_VER=${SB_VER:-v1.12.25}

if [[ "$SB_VER" != v* ]]; then
    SB_VER="v${SB_VER}"
fi

echo -e "${YELLOW}✔ 使用版本号：${SB_VER}${RESET}"

# ---------------------------------------------------------
# [4/8] 自动查找最新构建
# ---------------------------------------------------------
echo -e "${BLUE}[4/8] 正在查找最新 Sing-Box 构建 ...${RESET}"

LATEST_URL=$(curl -s https://api.github.com/repos/you10069/Build/releases \
    | grep '"browser_download_url"' \
    | grep "sb-${SB_VER}" \
    | grep "${TARGET_BIN}" \
    | head -n 1 \
    | cut -d '"' -f 4)

if [[ -z "$LATEST_URL" ]]; then
    echo -e "${RED}❌ 未找到构建：sb-${SB_VER} / ${TARGET_BIN}${RESET}"
    exit 1
fi

echo -e "${YELLOW}➡️ 最新下载地址: ${LATEST_URL}${RESET}"

# ---------------------------------------------------------
# [5/8] 下载 Sing-Box
# ---------------------------------------------------------
echo -e "${BLUE}[5/8] 正在下载 Sing-Box ...${RESET}"

wget -O /usr/bin/sing-box "$LATEST_URL"
chmod 755 /usr/bin/sing-box

echo -e "${YELLOW}✔ Sing-Box 下载完成${RESET}"

# ---------------------------------------------------------
# [6/8] 创建目录结构
# ---------------------------------------------------------
echo -e "${BLUE}[6/8] 创建目录结构与配置文件 ...${RESET}"

mkdir -p /etc/sing-box
mkdir -p /etc/sing-box/crt

touch /etc/sing-box/config_template.json
touch /etc/sing-box/config.json

chmod 644 /etc/sing-box/config.json
chmod 644 /etc/sing-box/config_template.json

echo -e "${YELLOW}✔ 目录与配置文件已创建${RESET}"

# ---------------------------------------------------------
# [7/8] 下载 systemd 服务文件
# ---------------------------------------------------------
echo -e "${BLUE}[7/8] 下载 systemd 服务文件 ...${RESET}"

wget -O /etc/systemd/system/sing-box.service \
  https://raw.githubusercontent.com/you10069/Tools/main/service/sing-box.service

chmod 644 /etc/systemd/system/sing-box.service

echo -e "${YELLOW}✔ systemd 服务文件已更新${RESET}"

# ---------------------------------------------------------
# [8/8] 重载 systemd
# ---------------------------------------------------------
echo -e "${BLUE}[8/8] 重载 systemd ...${RESET}"
systemctl daemon-reload

echo -e "${YELLOW}✔ systemd 已重载${RESET}"

echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🎉 安装完成！你可以启动服务：${RESET}"
echo -e "${ORANGE}  systemctl start sing-box${RESET}"
echo -e "${ORANGE}  systemctl enable sing-box${RESET}"
echo -e "${ORANGE}  systemctl status sing-box${RESET}"
echo -e "${ORANGE}  journalctl -u sing-box -f --output cat${RESET}"
echo -e "${ORANGE}==============================================${RESET}"
