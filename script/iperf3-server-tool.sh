#!/usr/bin/env bash  

# 提醒使用者
echo "--------------------------------------------------"
echo "TCP调优脚本-V2026.03.28（临时调参版，无持久化修改）"
echo "--------------------------------------------------"
echo "请阅读以下注意事项："
echo "1. 所有调参均为临时生效，重启后自动恢复"
echo "2. 不会修改 /etc/sysctl.conf"
echo "3. 小带宽或低延迟场景下，调优效果不显著"
echo "4. 请尽量在晚高峰进行调优"
echo "--------------------------------------------------"

# --------------------------------------------------
# 依赖检查（仅检查，不安装）
# --------------------------------------------------

if ! command -v iperf3 &> /dev/null; then
    echo "警告：iperf3 未安装，部分功能将不可用"
    echo "请手动安装：apt install iperf3 或 yum install iperf3"
else
    echo "iperf3 已安装"
fi

# 查询并输出当前的TCP缓冲区参数大小
echo "--------------------------------------------------"
echo "当前 TCP 缓冲区参数如下："
sysctl net.ipv4.tcp_wmem
sysctl net.ipv4.tcp_rmem
echo "--------------------------------------------------"

# --------------------------------------------------
# 重置 TCP 缓冲区为 Linux 默认值（临时）
# --------------------------------------------------
reset_tcp() {
    sysctl -w net.ipv4.tcp_wmem="4096 16384 4194304"
    sysctl -w net.ipv4.tcp_rmem="4096 131072 6291456"
    echo "已将 TCP 缓冲区恢复为默认值（临时生效）"
}

# --------------------------------------------------
# 主菜单
# --------------------------------------------------
echo "选择方案："
echo "1. 自由调整"
echo "2. 调整复原"
echo "0. 退出脚本"

read -p "请输入方案编号: " choice_main

case "$choice_main" in
  1)
    while true; do
        echo "方案一：自由调整"
        echo "请选择操作："
        echo "1. 后台启动 iperf3"
        echo "2. TCP 缓冲区 max 值设为 BDP（临时）"
        echo "3. TCP 缓冲区 max 值设为指定值（临时）"
        echo "4. 增减 TCP 缓冲区参数（临时，可连续调整）"
        echo "5. 重置 TCP 缓冲区参数（临时）"
        echo "0. 结束 iperf3 进程并退出"
        echo "--------------------------------------------------"

        read -p "请输入选择: " sub_choice

        case "$sub_choice" in
            1)
                local_ip=$(wget -qO- --inet4-only http://icanhazip.com 2>/dev/null)
                [ -z "$local_ip" ] && local_ip=$(wget -qO- http://icanhazip.com)

                echo "您的出口IP是: $local_ip"
                echo "--------------------------------------------------"

                while true; do
                    read -p "请输入用于 iperf3 的端口号（默认 80）： " iperf_port
                    iperf_port=${iperf_port// /}
                    iperf_port=${iperf_port:-80}

                    if [[ "$iperf_port" =~ ^[0-9]+$ ]] && [ "$iperf_port" -ge 1 ] && [ "$iperf_port" -le 65535 ]; then
                        break
                    else
                        echo "无效端口号，请重新输入"
                    fi
                done

                echo "启动 iperf3 服务端，端口：$iperf_port..."
                nohup iperf3 -s -p $iperf_port > /dev/null 2>&1 &
                iperf3_pid=$!
                echo "iperf3 服务端启动，PID：$iperf3_pid"
                echo "客户端测试命令：iperf3 -c $local_ip -R -t 30 -p $iperf_port"
                ;;
            2)
                while true; do
                    read -p "请输入本机带宽 (Mbps): " local_bandwidth
                    [[ "$local_bandwidth" =~ ^[0-9]+(\.[0-9]+)?$ ]] && break
                    echo "无效输入，请输入数字"
                done

                while true; do
                    read -p "请输入对端带宽 (Mbps): " server_bandwidth
                    [[ "$server_bandwidth" =~ ^[0-9]+(\.[0-9]+)?$ ]] && break
                    echo "无效输入，请输入数字"
                done

                while true; do
                    read -p "请输入往返时延 RTT (ms): " rtt
                    [[ "$rtt" =~ ^[0-9]+(\.[0-9]+)?$ ]] && break
                    echo "无效输入，请输入数字"
                done

                min_bandwidth=$(echo "$local_bandwidth $server_bandwidth" | awk '{print ($1 < $2 ? $1 : $2)}')
                bdp=$(echo "$min_bandwidth * $rtt * 1000 / 8" | bc)

                echo "BDP 理论值：$bdp bytes"
                sysctl -w net.ipv4.tcp_wmem="4096 16384 $bdp"
                sysctl -w net.ipv4.tcp_rmem="4096 87380 $bdp"
                echo "已应用（临时生效）"
                ;;
            3)
                while true; do
                    read -p "请输入指定值 (MiB，可小数): " tcp_value
                    [[ "$tcp_value" =~ ^[0-9]+(\.[0-9]+)?$ ]] && break
                    echo "无效输入，请输入数字"
                done

                value=$(echo "$tcp_value * 1024 * 1024" | bc | awk '{printf "%d", $0}')
                echo "设置 TCP 缓冲区 max 值为：$value bytes"
                sysctl -w net.ipv4.tcp_wmem="4096 16384 $value"
                sysctl -w net.ipv4.tcp_rmem="4096 87380 $value"
                echo "已应用（临时生效）"
                ;;
            4)
                while true; do
                    current_wmem=$(sysctl net.ipv4.tcp_wmem | awk '{print $NF}')
                    current_rmem=$(sysctl net.ipv4.tcp_rmem | awk '{print $NF}')

                    # 转换为 MiB（保留两位小数）
                    current_wmem_mib=$(echo "scale=2; $current_wmem / 1024 / 1024" | bc)
                    current_rmem_mib=$(echo "scale=2; $current_rmem / 1024 / 1024" | bc)

                    echo "当前发送缓冲区 max：$current_wmem bytes（${current_wmem_mib} MiB）"
                    echo "当前接收缓冲区 max：$current_rmem bytes（${current_rmem_mib} MiB）"

                    read -p "发送缓冲区调整值 (MiB，可小数，可负数): " adjust_value
                    read -p "接收缓冲区调整值 (MiB，可小数，可负数): " adjust_value_2

                    # 计算新值（支持小数）
                    new_wmem=$(echo "$current_wmem + $adjust_value * 1024 * 1024" | bc | awk '{printf "%d", $0}')
                    new_rmem=$(echo "$current_rmem + $adjust_value_2 * 1024 * 1024" | bc | awk '{printf "%d", $0}')

                    # 转换为 MiB（保留两位小数）
                    new_wmem_mib=$(echo "scale=2; $new_wmem / 1024 / 1024" | bc)
                    new_rmem_mib=$(echo "scale=2; $new_rmem / 1024 / 1024" | bc)

                    if [ $new_wmem -lt 4096 ] || [ $new_rmem -lt 4096 ]; then
                        echo "错误：新值小于 4096，操作取消"
                    else
                        sysctl -w net.ipv4.tcp_wmem="4096 16384 $new_wmem"
                        sysctl -w net.ipv4.tcp_rmem="4096 87380 $new_rmem"
                        echo "已应用（临时生效）"
                        echo "新的发送缓冲区 max：$new_wmem bytes（${new_wmem_mib} MiB）"
                        echo "新的接收缓冲区 max：$new_rmem bytes（${new_rmem_mib} MiB）"
                    fi

                    echo "--------------------------------------------------"
                    read -p "是否继续调整？ [Y/n]（默认Y）: " cont
                    cont=${cont:-Y}

                    if [[ "$cont" =~ ^[Nn]$ ]]; then
                        echo "返回上一级菜单..."
                        break
                    fi
                done
                ;;
            5)
                reset_tcp
                ;;
            0)
                echo "停止 iperf3..."
                pkill iperf3
                echo "退出脚本"
                exit 0
                ;;
            *)
                echo "无效选择"
                ;;
        esac

        echo "--------------------------------------------------"
        read -p "按回车继续..."
    done
    ;;
  2)
    echo "执行调整复原..."
    reset_tcp
    echo "复原完成（临时生效）"
    ;;
  0)
    echo "退出脚本"
    exit 0
    ;;
  *)
    echo "无效选择"
    ;;
esac
