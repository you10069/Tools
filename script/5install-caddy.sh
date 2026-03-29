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
echo -e "${ORANGE}🚀 Caddy 一键安装脚本（自动检测最新版本）${RESET}"
echo -e "${ORANGE}==============================================${RESET}"

# ---------------------------------------------------------
# [1/10] CPU 指令集检测
# ---------------------------------------------------------
echo -e "${BLUE}[1/10] 检测 CPU 指令集支持情况 ...${RESET}"
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
# [2/10] 选择架构（v2 / v3）
# ---------------------------------------------------------
echo -e "${BLUE}[2/10] 请选择架构 ...${RESET}"
echo -e "${YELLOW}  1) amd64v2（兼容性更好）${RESET}"
echo -e "${YELLOW}  2) amd64v3（性能更高）${RESET}"
echo -en "${BLUE}请输入数字选择： ${RESET}"
read -r arch_choice

case "$arch_choice" in
    1) ARCH="v2" ;;
    2) ARCH="v3" ;;
    *) echo -e "${RED}❌ 无效选择${RESET}"; exit 1 ;;
esac

# ---------------------------------------------------------
# [3/10] 选择 Base（caddy / caddy-wow / caddy-zed）
# ---------------------------------------------------------
echo -e "${BLUE}[3/10] 请选择 Caddy 基础类型 ...${RESET}"
echo -e "${YELLOW}  1) caddy${RESET}"
echo -e "${YELLOW}  2) caddy-wow${RESET}"
echo -e "${YELLOW}  3) caddy-zed${RESET}"
echo -en "${BLUE}请输入数字选择： ${RESET}"
read -r base_choice

case "$base_choice" in
    1) BASE="caddy" ;;
    2) BASE="caddy-wow" ;;
    3) BASE="caddy-zed" ;;
    *) echo -e "${RED}❌ 无效选择${RESET}"; exit 1 ;;
esac

# ---------------------------------------------------------
# [4/10] 选择功能类型（nc / ncl / nct / nclt）
# ---------------------------------------------------------
echo -e "${BLUE}[4/10] 请选择功能类型 ...${RESET}"
echo -e "${YELLOW}  1) nc${RESET}"
echo -e "${YELLOW}  2) ncl${RESET}"
echo -e "${YELLOW}  3) nct${RESET}"
echo -e "${YELLOW}  4) nclt${RESET}"
echo -en "${BLUE}请输入数字选择： ${RESET}"
read -r pwd_choice

case "$pwd_choice" in
    1) PASSWORD="nc" ;;
    2) PASSWORD="ncl" ;;
    3) PASSWORD="nct" ;;
    4) PASSWORD="nclt" ;;
    *) echo -e "${RED}❌ 无效选择${RESET}"; exit 1 ;;
esac

# ---------------------------------------------------------
# 拼接最终构建名（精准匹配 24 种构建）
# ---------------------------------------------------------
TARGET_BIN="${BASE}-${PASSWORD}-${ARCH}"
echo -e "${YELLOW}✔ 已选择构建：${TARGET_BIN}${RESET}"

# ---------------------------------------------------------
# [5/10] 创建目录
# ---------------------------------------------------------
echo -e "${BLUE}[5/10] 创建 Caddy 目录结构 ...${RESET}"

mkdir -p /etc/caddy/users
mkdir -p /etc/caddy/speedtestfiles

echo -e "${YELLOW}✔ 目录创建完成${RESET}"

# ---------------------------------------------------------
# [6/10] 创建 caddy 用户与组
# ---------------------------------------------------------
echo -e "${BLUE}[6/10] 创建 caddy 用户与组 ...${RESET}"

if ! getent group caddy >/dev/null; then
    groupadd --system caddy
    echo -e "${YELLOW}✔ 创建系统组 caddy${RESET}"
else
    echo -e "${RED}⚠ 组 caddy 已存在，跳过${RESET}"
fi

if ! id caddy >/dev/null 2>&1; then
    useradd --system \
      --gid caddy \
      --create-home \
      --home-dir /etc/caddy/all \
      --shell /usr/sbin/nologin \
      --comment "Caddy web server" \
      caddy
    echo -e "${YELLOW}✔ 创建系统用户 caddy${RESET}"
else
    echo -e "${RED}⚠ 用户 caddy 已存在，跳过${RESET}"
fi

chown -R caddy:caddy /etc/caddy/all
echo -e "${YELLOW}✔ 目录权限已设置${RESET}"

# ---------------------------------------------------------
# [7/10] 下载 Caddy 二进制
# ---------------------------------------------------------
echo -e "${BLUE}[7/10] 获取最新 CaddyAll 构建 ...${RESET}"

LATEST_URL=$(curl -s https://api.github.com/repos/you10069/Build/releases \
    | grep '"browser_download_url"' \
    | grep "CaddyAll-" \
    | grep "$TARGET_BIN" \
    | head -n 1 \
    | cut -d '"' -f 4)

if [[ -z "$LATEST_URL" ]]; then
    echo -e "${RED}❌ 未找到构建：$TARGET_BIN${RESET}"
    exit 1
fi

echo -e "${YELLOW}➡️ 最新下载地址: ${LATEST_URL}${RESET}"

echo -e "${BLUE}正在下载 Caddy ...${RESET}"
wget -O /usr/bin/caddy "$LATEST_URL"
chmod 755 /usr/bin/caddy

echo -e "${YELLOW}✔ Caddy 下载完成${RESET}"

# ---------------------------------------------------------
# [8/10] 创建 Caddyfile
# ---------------------------------------------------------
echo -e "${BLUE}[8/10] 创建 Caddyfile ...${RESET}"

touch /etc/caddy/Caddyfile
chmod 644 /etc/caddy/Caddyfile

echo -e "${YELLOW}✔ Caddyfile 已创建${RESET}"

# ---------------------------------------------------------
# [9/10] 下载 systemd 服务文件并重载
# ---------------------------------------------------------
echo -e "${BLUE}[9/10] 下载 systemd 服务文件 ...${RESET}"

wget -O /etc/systemd/system/caddy.service \
  https://raw.githubusercontent.com/you10069/Tools/main/service/caddy.service

chmod 644 /etc/systemd/system/caddy.service

echo -e "${YELLOW}✔ systemd 服务文件已更新${RESET}"

echo -e "${BLUE}[10/10] 重载 systemd ...${RESET}"
systemctl daemon-reload

echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🎉 安装完成！你可以启动服务：${RESET}"
echo -e "${ORANGE}  systemctl start caddy${RESET}"
echo -e "${ORANGE}  systemctl enable caddy${RESET}"
echo -e "${ORANGE}  systemctl status caddy${RESET}"
echo -e "${ORANGE}  journalctl -u caddy -f --output cat${RESET}"
echo -e "${ORANGE}==============================================${RESET}"
