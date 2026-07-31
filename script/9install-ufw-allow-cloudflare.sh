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
echo -e "${ORANGE}🔥 Cloudflare UFW 端口限制一键安装脚本${RESET}"
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

# ============================
# GitHub 基础路径
# ============================
BASE_URL="https://raw.githubusercontent.com/you10069/Tools/main/service"

# ---------------------------------------------------------
# 输入要保护的端口（可多个，默认 50002 和 8440）
# ---------------------------------------------------------
echo -e "${BLUE}请输入只允许 Cloudflare 访问的端口（多个端口用空格或逗号分隔，默认 50002 8440）...${RESET}"
while true; do
    read -p "端口: " input_ports
    input_ports=${input_ports:-"50002 8440"}
    # 将逗号替换为空格，便于读取
    ports_str=$(echo "$input_ports" | tr ',' ' ')
    read -a CF_PORTS <<< "$ports_str"
    # 逐个验证
    valid=true
    for p in "${CF_PORTS[@]}"; do
        if ! validate_port "$p"; then
            echo -e "${RED}❌ 端口 $p 无效，请输入 1-65535 的纯数字${RESET}"
            valid=false
            break
        fi
    done
    if $valid; then break; fi
done
echo -e "${YELLOW}✔ 保护端口：${CF_PORTS[*]}${RESET}"

# ---------------------------------------------------------
# 选择协议类型（默认 TCP 和 UDP）
# ---------------------------------------------------------
echo -e "${BLUE}请选择允许 Cloudflare 访问的协议：${RESET}"
echo "  1) TCP"
echo "  2) UDP"
echo "  3) TCP 和 UDP (默认)"
read -p "请输入选项 [1-3] (默认 3): " proto_choice
proto_choice=${proto_choice:-3}
case $proto_choice in
    1) CF_PROTO="tcp" ;;
    2) CF_PROTO="udp" ;;
    3) CF_PROTO="both" ;;
    *) echo -e "${RED}无效输入，使用默认 both${RESET}"; CF_PROTO="both" ;;
esac
echo -e "${YELLOW}✔ 协议类型：${CF_PROTO}${RESET}"

# ---------------------------------------------------------
# 检查 UFW 是否已启用
# ---------------------------------------------------------
echo -e "${BLUE}检查 UFW 状态...${RESET}"
if ! sudo ufw status | grep -q "Status: active"; then
    echo -e "${RED}❌ UFW 未启用，请先手动启用并设置好默认策略（如 sudo ufw enable && sudo ufw default deny incoming），然后重新运行本脚本。${RESET}"
    exit 1
else
    echo -e "${YELLOW}✔ UFW 已启用${RESET}"
fi

# ---------------------------------------------------------
# 生成 ufw-allow-cloudflare.sh
# ---------------------------------------------------------
echo -e "${BLUE}生成 ufw-allow-cloudflare.sh ...${RESET}"

mkdir -p /etc/sing-box/iptables

# 将端口数组转为空格分隔的字符串，写入生成脚本
CF_PORTS_STR="${CF_PORTS[*]}"

cat > /etc/sing-box/iptables/ufw-allow-cloudflare.sh <<EOF
#!/usr/bin/env bash
set -e

# 端口列表（空格分隔）
PORTS="${CF_PORTS_STR}"
PROTO="${CF_PROTO}"
RULE_COMMENT="cloudflare-allow"
WORK_DIR="/etc/sing-box/iptables"

CF_IPV4_URL="https://www.cloudflare.com/ips-v4"
CF_IPV6_URL="https://www.cloudflare.com/ips-v6"

# 确保工作目录存在
mkdir -p "\$WORK_DIR"

# ----- 清理旧规则（可靠提取编号） -----
echo "清理旧规则..."
sudo ufw status numbered | grep "${RULE_COMMENT}" | sed -n 's/^\[[[:space:]]*\([0-9]*\)\].*/\1/p' | sort -rn | while read -r num; do
    sudo ufw delete "$num" >/dev/null 2>&1 || true
done

# 统一的规则添加函数：遍历所有端口，根据需要添加 TCP/UDP 规则
add_rules() {
    local ip="\$1"
    for PORT in \$PORTS; do
        if [ "\$PROTO" = "both" ]; then
            # 不指定 proto 即同时允许 TCP 和 UDP
            sudo ufw allow from "\$ip" to any port "\$PORT" comment "\$RULE_COMMENT"
        else
            sudo ufw allow from "\$ip" to any port "\$PORT" proto "\$PROTO" comment "\$RULE_COMMENT"
        fi
    done
}

# ----- IPv4 -----
echo "下载并保存 Cloudflare IPv4 列表到 \${WORK_DIR}/cloudflare-ips-v4 ..."
curl -sL "\$CF_IPV4_URL" -o "\${WORK_DIR}/cloudflare-ips-v4"

echo "添加 IPv4 规则..."
while read -r ip; do
    add_rules "\$ip"
done < "\${WORK_DIR}/cloudflare-ips-v4"

# ----- IPv6 -----
echo "下载并保存 Cloudflare IPv6 列表到 \${WORK_DIR}/cloudflare-ips-v6 ..."
if curl -sL --connect-timeout 5 "\$CF_IPV6_URL" -o "\${WORK_DIR}/cloudflare-ips-v6" 2>/dev/null; then
    echo "添加 IPv6 规则..."
    while read -r ip; do
        add_rules "\$ip"
    done < "\${WORK_DIR}/cloudflare-ips-v6"
else
    echo "跳过 IPv6 规则（下载失败或网络不可达）"
fi
EOF

chmod 755 /etc/sing-box/iptables/ufw-allow-cloudflare.sh
echo -e "${YELLOW}✔ 脚本已生成：/etc/sing-box/iptables/ufw-allow-cloudflare.sh${RESET}"

# ---------------------------------------------------------
# 下载 systemd 服务文件和定时器
# ---------------------------------------------------------
echo -e "${BLUE}下载 systemd 服务与定时器文件...${RESET}"

wget -O /etc/systemd/system/ufw-allow-cloudflare.service "${BASE_URL}/ufw-allow-cloudflare.service"
chmod 644 /etc/systemd/system/ufw-allow-cloudflare.service

wget -O /etc/systemd/system/ufw-allow-cloudflare.timer "${BASE_URL}/ufw-allow-cloudflare.timer"
chmod 644 /etc/systemd/system/ufw-allow-cloudflare.timer

systemctl daemon-reload

echo -e "${YELLOW}✔ systemd 服务文件下载完成并重载${RESET}"

# ---------------------------------------------------------
# 输出提示
# ---------------------------------------------------------
echo
echo -e "${ORANGE}==============================================${RESET}"
echo -e "${ORANGE}🎉 安装完成！你可以执行以下命令：${RESET}"
echo -e "${ORANGE}  首次应用规则（并将 Cloudflare IP 保存到文件）：${RESET}"
echo -e "${ORANGE}    sudo /etc/sing-box/iptables/ufw-allow-cloudflare.sh${RESET}"
echo -e "${ORANGE}  启动并启用自动更新：${RESET}"
echo -e "${ORANGE}    systemctl start ufw-allow-cloudflare.service${RESET}"
echo -e "${ORANGE}    systemctl enable ufw-allow-cloudflare.service${RESET}"
echo -e "${ORANGE}    systemctl enable --now ufw-allow-cloudflare.timer${RESET}"
echo -e "${ORANGE}  查看服务状态：${RESET}"
echo -e "${ORANGE}    systemctl status ufw-allow-cloudflare.service${RESET}"
echo -e "${ORANGE}    systemctl status ufw-allow-cloudflare.timer${RESET}"
echo -e "${ORANGE}  查看日志：${RESET}"
echo -e "${ORANGE}    journalctl -u ufw-allow-cloudflare.service -f --output cat${RESET}"
echo -e "${ORANGE}==============================================${RESET}"
