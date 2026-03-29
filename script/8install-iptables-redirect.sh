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
echo -e "${ORANGE}🔥 iptables-redirect 一键安装脚本（交互式）${RESET}"
echo -e "${ORANGE}==============================================${RESET}"

# ============================
# 校验函数
# ============================
validate_port() {
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

validate_range() {
    local range="$1"

    if [[ ! "$range" =~ ^[0-9]+:[0-9]+$ ]]; then
        return 1
    fi

    local start="${range%%:*}"
    local end="${range##*:}"

    if ! [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]]; then return 1; fi
    if [ "$start" -lt 1 ] || [ "$start" -gt 65535 ]; then return 1; fi
    if [ "$end" -lt 1 ] || [ "$end" -gt 65535 ]; then return 1; fi
    if [ "$start" -ge "$end" ]; then return 1; fi

    return 0
}

# ---------------------------------------------------------
# [1/10] 显示网卡信息
# ---------------------------------------------------------
echo -e "${BLUE}[1/10] 当前网卡信息如下：${RESET}"
ip a
echo

# ---------------------------------------------------------
# [2/10] 输入网卡名称
# ---------------------------------------------------------
echo -e "${BLUE}[2/10] 请输入网卡名称（默认 eth0）...${RESET}"
read -p "网卡名称: " IFACE
IFACE=${IFACE:-eth0}
echo -e "${YELLOW}✔ 使用网卡：${IFACE}${RESET}"

# ---------------------------------------------------------
# [3/10] 输入 hy2 端口
# ---------------------------------------------------------
echo -e "${BLUE}[3/10] 请输入 hy2 端口（默认 8443）...${RESET}"
while true; do
    read -p "hy2 端口: " HY2
    HY2=${HY2:-8443}
    if validate_port "$HY2"; then break; fi
    echo -e "${RED}❌ 端口无效，请输入 1-65535 的纯数字${RESET}"
done
echo -e "${YELLOW}✔ hy2 端口：${HY2}${RESET}"

# ---------------------------------------------------------
# [4/10] 输入 hy2 端口区间
# ---------------------------------------------------------
echo -e "${BLUE}[4/10] 请输入 hy2 端口区间（默认 10000:20000）...${RESET}"
while true; do
    read -p "hy2 端口区间: " HY2_RANGE
    HY2_RANGE=${HY2_RANGE:-10000:20000}
    if validate_range "$HY2_RANGE"; then break; fi
    echo -e "${RED}❌ 区间无效，请输入正确格式，例如：10000:20000${RESET}"
done
echo -e "${YELLOW}✔ hy2 端口区间：${HY2_RANGE}${RESET}"

# ---------------------------------------------------------
# [5/10] 输入 hy2-bbr 端口
# ---------------------------------------------------------
echo -e "${BLUE}[5/10] 请输入 hy2-bbr 端口（默认 8444）...${RESET}"
while true; do
    read -p "hy2-bbr 端口: " HY2BBR
    HY2BBR=${HY2BBR:-8444}
    if validate_port "$HY2BBR"; then break; fi
    echo -e "${RED}❌ 端口无效，请输入 1-65535 的纯数字${RESET}"
done
echo -e "${YELLOW}✔ hy2-bbr 端口：${HY2BBR}${RESET}"

# ---------------------------------------------------------
# [6/10] 输入 hy2-bbr 端口区间
# ---------------------------------------------------------
echo -e "${BLUE}[6/10] 请输入 hy2-bbr 端口区间（默认 21000:29000）...${RESET}"
while true; do
    read -p "hy2-bbr 端口区间: " HY2BBR_RANGE
    HY2BBR_RANGE=${HY2BBR_RANGE:-21000:29000}
    if validate_range "$HY2BBR_RANGE"; then break; fi
    echo -e "${RED}❌ 区间无效，请输入正确格式，例如：21000:29000${RESET}"
done
echo -e "${YELLOW}✔ hy2-bbr 端口区间：${HY2BBR_RANGE}${RESET}"

# ---------------------------------------------------------
# [7/10] 输入 hy1 端口
# ---------------------------------------------------------
echo -e "${BLUE}[7/10] 请输入 hy1 端口（默认 8445）...${RESET}"
while true; do
    read -p "hy1 端口: " HY1
    HY1=${HY1:-8445}
    if validate_port "$HY1"; then break; fi
    echo -e "${RED}❌ 端口无效，请输入 1-65535 的纯数字${RESET}"
done
echo -e "${YELLOW}✔ hy1 端口：${HY1}${RESET}"

# ---------------------------------------------------------
# [8/10] 输入 hy1 端口区间
# ---------------------------------------------------------
echo -e "${BLUE}[8/10] 请输入 hy1 端口区间（默认 31000:39000）...${RESET}"
while true; do
    read -p "hy1 端口区间: " HY1_RANGE
    HY1_RANGE=${HY1_RANGE:-31000:39000}
    if validate_range "$HY1_RANGE"; then break; fi
    echo -e "${RED}❌ 区间无效，请输入正确格式，例如：31000:39000${RESET}"
done
echo -e "${YELLOW}✔ hy1 端口区间：${HY1_RANGE}${RESET}"

# ---------------------------------------------------------
# [9/10] 生成 iptables-redirect.sh
# ---------------------------------------------------------
echo -e "${BLUE}[9/10] 生成 iptables-redirect.sh ...${RESET}"

mkdir -p /etc/sing-box/iptables

cat > /etc/sing-box/iptables/iptables-redirect.sh <<EOF
#!/bin/bash
iptables -t nat -A PREROUTING -i ${IFACE} -p udp --dport ${HY2_RANGE} -j REDIRECT --to-ports ${HY2}
ip6tables -t nat -A PREROUTING -i ${IFACE} -p udp --dport ${HY2_RANGE} -j REDIRECT --to-ports ${HY2}

iptables -t nat -A PREROUTING -i ${IFACE} -p udp --dport ${HY2BBR_RANGE} -j REDIRECT --to-ports ${HY2BBR}
ip6tables -t nat -A PREROUTING -i ${IFACE} -p udp --dport ${HY2BBR_RANGE} -j REDIRECT --to-ports ${HY2BBR}

iptables -t nat -A PREROUTING -i ${IFACE} -p udp --dport ${HY1_RANGE} -j REDIRECT --to-ports ${HY1}
ip6tables -t nat -A PREROUTING -i ${IFACE} -p udp --dport ${HY1_RANGE} -j REDIRECT --to-ports ${HY1}
EOF

chmod 755 /etc/sing-box/iptables/iptables-redirect.sh

echo -e "${YELLOW}✔ iptables-redirect.sh 已生成${RESET}"
echo -e "${YELLOW}✔ 位于：/etc/sing-box/iptables${RESET}"

# ---------------------------------------------------------
# [10/10] 下载 systemd 服务文件
# ---------------------------------------------------------
echo -e "${BLUE}[10/10] 下载 systemd 服务文件 ...${RESET}"

wget -O /etc/systemd/system/iptables-redirect.service \
  https://raw.githubusercontent.com/you10069/Tools/main/service/iptables-redirect.service

chmod 644 /etc/systemd/system/iptables-redirect.service
systemctl daemon-reload

echo -e "${YELLOW}✔ systemd 下载完成并重载${RESET}"

echo
echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🎉 安装完成！你可以启动服务：${RESET}"
echo -e "${ORANGE}  systemctl start iptables-redirect${RESET}"
echo -e "${ORANGE}  systemctl enable iptables-redirect${RESET}"
echo -e "${ORANGE}  systemctl status iptables-redirect${RESET}"
echo -e "${ORANGE}  journalctl -u iptables-redirect -f --output cat${RESET}"
echo -e "${ORANGE}==============================================${RESET}"
