#!/usr/bin/env bash  # 指定解释器为 bash

# 检测并设置合适的 echo 命令
detect_echo() {
    for cmd in echo /bin/echo; do
        if $cmd >/dev/null 2>&1 && ! $cmd -e "" | grep -qE '^-e'; then
            echo=$cmd
            return
        fi
    done
    echo=echo
}

# 定义颜色序列
define_colors() {
    CSI=$($echo -e "\033[")
    CEND="${CSI}0m"
    CDGREEN="${CSI}32m"
    CRED="${CSI}1;31m"
    CGREEN="${CSI}1;32m"
    CYELLOW="${CSI}1;33m"
    CBLUE="${CSI}1;34m"
    CMAGENTA="${CSI}1;35m"
    CCYAN="${CSI}1;36m"
}

# 输出警告信息
OUT_ALERT() {
    echo -e "${CYELLOW}$1${CEND}"
}

# 输出错误信息
OUT_ERROR() {
    echo -e "${CRED}$1${CEND}"
}

# 输出一般信息
OUT_INFO() {
    echo -e "${CCYAN}$1${CEND}"
}

# 检测操作系统
detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif grep -qiE "debian|raspbian" /etc/issue || grep -qiE "raspbian|debian" /proc/version; then
        release="debian"
    elif grep -qiE "ubuntu" /etc/issue || grep -qiE "ubuntu" /proc/version; then
        release="ubuntu"
    elif grep -qiE "centos|red hat|redhat" /etc/issue || grep -qiE "centos|red hat|redhat" /proc/version; then
        release="centos"
    else
        OUT_ERROR "[错误] 不支持的操作系统！"
        exit 1
    fi
}

# 安装 and 配置 haveged
install_haveged() {
    OUT_ALERT "[信息] 正在安装 haveged 增强性能中！"
    if [[ ${release} == "centos" ]]; then
        yum install haveged -y
    else
        apt install haveged -y
    fi

    OUT_ALERT "[信息] 正在配置 haveged 增强性能中！"
    systemctl disable --now haveged
    systemctl enable --now haveged
}

# 优化系统参数
optimize_system() {
    OUT_ALERT "[信息] 正在优化系统参数中！"
    modprobe ip_conntrack
    chattr -i /etc/sysctl.conf
    cat > /etc/sysctl.conf << EOF
vm.swappiness = 0
fs.file-max = 1024000
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 1024000
net.core.default_qdisc = fq_pie
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_announce = 2
net.ipv4.conf.default.arp_announce = 2
net.ipv4.ip_forward = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.neigh.default.gc_stale_time = 120
net.ipv4.tcp_ecn = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_keepalive_time = 10
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 8192
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
EOF

    cat > /etc/security/limits.conf << EOF
* soft nofile 512000
* hard nofile 512000
* soft nproc 512000
* hard nproc 512000
root soft nofile 512000
root hard nofile 512000
root soft nproc 512000
root hard nproc 512000
EOF

    cat > /etc/systemd/journald.conf <<EOF
[Journal]
SystemMaxUse=50M
SystemMaxFileSize=12M
ForwardToSyslog=no
EOF

    sysctl -p
}

# 主程序
main() {
    detect_echo
    define_colors
    detect_os
    install_haveged
    optimize_system
    OUT_INFO "[信息] 优化完毕！"
}

main
