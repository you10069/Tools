#!/usr/bin/env bash

# ====== 颜色定义（全部蓝色） ======
BLUE="\033[34m"
RESET="\033[0m"

CONF="/etc/sysctl.conf"

# 要追加的内容
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
net.ipv4.tcp_wmem= 4096 16384 8388608
net.ipv4.tcp_rmem= 4096 87380 8388608


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

# 确保文件存在
if [ ! -f "$CONF" ]; then
    echo -e "${BLUE}文件不存在: $CONF${RESET}"
    exit 1
fi

# 计算末尾已有多少空行
END_EMPTY_LINES=$(tac "$CONF" | awk '
    /^[[:space:]]*$/ { n++ }
    /^[[:space:]]*[^[:space:]]/ { print n; exit }
    END { if (NR==0) print 0 }
')

# 需要补齐的空行数
NEED=$((6 - END_EMPTY_LINES))
if [ $NEED -lt 0 ]; then NEED=0; fi

# 追加空行
for ((i=0; i<NEED; i++)); do
    echo "" >> "$CONF"
done

# 追加内容
echo "$ADD_CONTENT" >> "$CONF"

echo -e "${BLUE}已成功在 $CONF 末尾空6行后追加优化内容。${RESET}"

# 立即生效
echo -e "${BLUE}正在应用 sysctl 配置...${RESET}"
sysctl -p

echo -e "${BLUE}优化完成。${RESET}"
