#!/usr/bin/env bash

# 颜色（用于标题和完成提示）
BLUE="\033[1;34m"
ORANGE="\033[38;5;208m"
RESET="\033[0m"

LINE="-------------------------------"

# 总标题（橙色 + == 包裹）
printf "${ORANGE}== 📊 系统状态总览 ==${RESET}\n"
printf "%s\n\n" "$LINE"


printf "${BLUE}📌 系统信息${RESET}\n"
printf "%s\n" "$LINE"
printf "主机名: %s\n" "$(hostname)"
printf "系统: %s\n" "$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
printf "内核: %s\n" "$(uname -r)"
printf "运行时间: %s\n" "$(uptime -p)"
printf "虚拟化: %s\n" "$(systemd-detect-virt)"
printf "\n\n"


printf "${BLUE}🖥️  CPU 信息${RESET}\n"
printf "%s\n" "$LINE"
printf "CPU 型号: %s\n" "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2)"
printf "CPU 核心数: %s\n" "$(nproc)"
printf "\n\n"


printf "${BLUE}🧩 CPU 支持指令集（GOAMD64）${RESET}\n"
printf "%s\n" "$LINE"

flags=$(grep -m1 flags /proc/cpuinfo)

supports() { echo "$flags" | grep -qw "$1"; }

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

print_flag() {
    if supports "$1"; then
        printf "%b\n" "  ${green}$1 ✔${reset}"
    else
        printf "%b\n" "  ${red}$1 ✘${reset}"
    fi
}

printf "%b\n" "${yellow}v2:${reset}"
for f in aes ssse3 sse4_1 sse4_2 popcnt cx16 lahf_lm; do
    print_flag "$f"
done

printf "%b\n" "${yellow}v3:${reset}"
for f in avx avx2 bmi1 bmi2 fma movbe xsave lzcnt osxsave; do
    print_flag "$f"
done

printf "%b\n" "${yellow}v4:${reset}"
for f in avx512f avx512bw avx512cd avx512dq avx512vl; do
    print_flag "$f"
done

# 自动判断 GOAMD64 级别
level=1
supports sse4_2 && level=2
supports avx2 && level=3
supports avx512f && level=4

printf "\n"
printf "%b\n" "${yellow}Your CPU supports: GOAMD64=v${level}${reset}"

printf "\n\n"


printf "${BLUE}📀 磁盘空间${RESET}\n"
printf "%s\n" "$LINE"
df -hT -x tmpfs -x devtmpfs
printf "\n\n"


printf "${BLUE}🧠 内存 & Swap${RESET}\n"
printf "%s\n" "$LINE"
free -h

printf "\n"

swapon --show
printf "\n\n"


printf "${BLUE}🌐 网络信息（ip addr show）${RESET}\n"
printf "%s\n" "$LINE"
ip addr show
printf "\n\n"


printf "${BLUE}🛣️  路由信息（ip route）${RESET}\n"
printf "%s\n" "$LINE"
ip route
printf "\n\n"


printf "${BLUE}🔎 DNS 信息${RESET}\n"
printf "%s\n" "$LINE"

# 原始 resolv.conf DNS
printf "resolv.conf 中的 DNS：\n"
grep -E "^nameserver" /etc/resolv.conf | sed 's/^/  /'

# resolv.conf 是否为符号链接
printf "\nresolv.conf 文件类型：\n"
if [ -L /etc/resolv.conf ]; then
    printf "  符号链接 -> %s\n" "$(readlink -f /etc/resolv.conf)"
else
    printf "  普通文件\n"
fi

# systemd-resolved 是否启用
printf "\nsystemd-resolved 状态：\n"
if systemctl is-active --quiet systemd-resolved; then
    printf "  已启用\n"
else
    printf "  未启用（resolvectl 功能将跳过）\n"
fi

# 实际使用的 DNS（resolvectl）
if command -v resolvectl >/dev/null 2>&1 && systemctl is-active --quiet systemd-resolved; then
    printf "\n实际使用的 DNS（resolvectl）：\n"
    resolvectl dns | sed 's/^/  /'

    printf "\nDNS over TLS / DNSSEC 状态：\n"
    resolvectl status | grep -E "DNSSEC|DNS over TLS" | sed 's/^/  /'
else
    printf "\n实际使用的 DNS（resolvectl）：\n"
    printf "  （systemd-resolved 未启用或 resolvectl 不可用）\n"
fi

printf "\n\n"


printf "${BLUE}📡 端口监听信息（TCP/UDP）${RESET}\n"
printf "%s\n" "$LINE"

ss -tunlp

printf "\n\n"


printf "${BLUE}⏰ 定时任务（crontab）${RESET}\n"
printf "%s\n" "$LINE"

crontab -l

printf "\n\n"


printf "${BLUE}⚙️ /etc/sysctl.conf 有效配置${RESET}\n"
printf "%s\n" "$LINE"

sed -e '/^\s*#/d' -e '/^\s*$/d' /etc/sysctl.conf

printf "\n\n"


printf "${BLUE}⚙️ /etc/sysctl.conf 我的配置${RESET}\n"
printf "%s\n" "$LINE"

sed -n '/^# 优化开始$/,$p' /etc/sysctl.conf

printf "\n\n"


printf "${BLUE}🔥 NAT 表规则（iptables）${RESET}\n"
printf "%s\n" "$LINE"

iptables -t nat -nvL

printf "\n\n"


printf "${BLUE}🛡️  UFW 防火墙状态${RESET}\n"
printf "%s\n" "$LINE"
ufw status verbose
printf "\n\n"


# 结束标题（橙色 + == 包裹）
printf "${ORANGE}== 🔚 系统状态总览结束 ==${RESET}\n"
