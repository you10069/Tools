#!/usr/bin/env bash

# ====== 颜色定义（全部蓝色） ======
BLUE="\033[34m"
RESET="\033[0m"

# ====== 通用函数：末尾空6行后追加 ======
append_with_padding() {
    local FILE="$1"
    local CONTENT="$2"

    # 确保文件存在
    if [ ! -f "$FILE" ]; then
        echo -e "${BLUE}文件不存在: $FILE${RESET}"
        exit 1
    fi

    # 计算末尾已有多少空行
    local END_EMPTY_LINES
    END_EMPTY_LINES=$(tac "$FILE" | awk '
        /^[[:space:]]*$/ { n++ }
        /^[[:space:]]*[^[:space:]]/ { print n; exit }
        END { if (NR==0) print 0 }
    ')

    # 需要补齐的空行数
    local NEED=$((6 - END_EMPTY_LINES))
    if [ $NEED -lt 0 ]; then NEED=0; fi

    # 追加空行
    for ((i=0; i<NEED; i++)); do
        echo "" >> "$FILE"
    done

    # 追加内容
    echo "$CONTENT" >> "$FILE"
}

# ===========================
# sysctl.conf 优化模块
# ===========================
CONF="/etc/sysctl.conf"

read -r -d '' ADD_CONTENT << 'EOF'
# 优化开始
# ===========================
# 1. BBR + FQ（核心加速）
# ===========================
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq


# ===========================
# 2. 内存行为优化（系统稳定性）
# ===========================
vm.swappiness = 5
vm.vfs_cache_pressure = 50


# ===========================
# 3. TCP 缓冲区（适合 1Gbps + 高延迟）
# ===========================
net.core.wmem_max = 16777216
net.core.rmem_max = 16777216
net.ipv4.tcp_wmem = 4096 16384 8388608
net.ipv4.tcp_rmem = 4096 131072 8388608


# ===========================
# 4. TCP Fast Open（加速握手）
# ===========================
net.ipv4.tcp_fastopen = 3


# ===========================
# 5. MTU 探测（避免跨境丢包）
# ===========================
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_window_scaling = 1


# ===========================
# 6. 队列优化（高并发）
# ===========================
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 4096
net.ipv4.tcp_max_syn_backlog = 8192


# ===========================
# 7. TIME-WAIT 优化（大量连接时）
# ===========================
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
# 优化结束
EOF

echo -e "${BLUE}正在处理 $CONF ...${RESET}"
append_with_padding "$CONF" "$ADD_CONTENT"

echo -e "${BLUE}已成功在 $CONF 末尾空6行后追加优化内容。${RESET}"

echo -e "${BLUE}正在应用 sysctl 配置...${RESET}"
sysctl -p



# ===========================
# journald.conf 交互 + 追加模块
# ===========================
JOURNAL_CONF="/etc/systemd/journald.conf"

echo -e "${BLUE}正在配置 /etc/systemd/journald.conf 日志限制...${RESET}"

DEFAULT_RUNTIME="50M"
DEFAULT_SYSTEM="100M"

# 输入 RuntimeMaxUse
echo -e "${BLUE}请输入journald.conf的RuntimeMaxUse（默认：50M）${RESET}"
read -r INPUT_RUNTIME
[[ -z "$INPUT_RUNTIME" ]] && INPUT_RUNTIME="$DEFAULT_RUNTIME"

if [[ "$INPUT_RUNTIME" =~ ^[0-9]+$ ]]; then
    INPUT_RUNTIME="${INPUT_RUNTIME}M"
elif [[ "$INPUT_RUNTIME" =~ ^[0-9]+[Mm]$ ]]; then
    INPUT_RUNTIME="${INPUT_RUNTIME^^}"
else
    echo -e "${BLUE}输入无效，必须为纯数字或数字+M${RESET}"
    exit 1
fi

# 输入 SystemMaxUse
echo -e "${BLUE}请输入journald.conf的SystemMaxUse（默认：100M）${RESET}"
read -r INPUT_SYSTEM
[[ -z "$INPUT_SYSTEM" ]] && INPUT_SYSTEM="$DEFAULT_SYSTEM"

if [[ "$INPUT_SYSTEM" =~ ^[0-9]+$ ]]; then
    INPUT_SYSTEM="${INPUT_SYSTEM}M"
elif [[ "$INPUT_SYSTEM" =~ ^[0-9]+[Mm]$ ]]; then
    INPUT_SYSTEM="${INPUT_SYSTEM^^}"
else
    echo -e "${BLUE}输入无效，必须为纯数字或数字+M${RESET}"
    exit 1
fi

# 追加内容（仅一个空格）
JOURNAL_CONTENT="RuntimeMaxUse = $INPUT_RUNTIME
SystemMaxUse = $INPUT_SYSTEM"

echo -e "${BLUE}正在写入 /etc/systemd/journald.conf ...${RESET}"
append_with_padding "$JOURNAL_CONF" "$JOURNAL_CONTENT"

echo -e "${BLUE}journald.conf 已更新：${RESET}"
echo -e "${BLUE}  RuntimeMaxUse = $INPUT_RUNTIME${RESET}"
echo -e "${BLUE}  SystemMaxUse = $INPUT_SYSTEM${RESET}"

systemctl restart systemd-journald
echo -e "${BLUE}journald 配置完成。${RESET}"



# ===========================
# 时区设置模块
# ===========================
echo -e "${BLUE}正在检查系统是否支持 Asia/Hong_Kong 时区...${RESET}"

if timedatectl list-timezones | grep -Ei 'Hong_Kong|Shanghai' >/dev/null 2>&1; then
    echo -e "${BLUE}检测到系统支持 Asia/Hong_Kong，正在设置...${RESET}"
    timedatectl set-timezone Asia/Hong_Kong
else
    echo -e "${BLUE}系统未找到 Hong_Kong 或 Shanghai 时区，跳过时区设置。${RESET}"
fi

echo -e "${BLUE}优化完成。${RESET}"
