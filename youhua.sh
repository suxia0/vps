#!/usr/bin/env bash  # 指定解释器为 bash

echo=echo  # 初始化 echo 变量为 echo 命令
for cmd in echo /bin/echo; do  # 循环检查 echo 和 /bin/echo 命令
    $cmd >/dev/null 2>&1 || continue  # 检查命令是否存在，不存在则继续循环

    if ! $cmd -e "" | grep -qE '^-e'; then  # 检查 echo 命令是否支持 -e 选项
        echo=$cmd  # 如果支持，则使用该命令
        break  # 跳出循环
    fi
done

CSI=$($echo -e "\033[")  # 定义颜色序列起始
CEND="${CSI}0m"  # 结束颜色
CDGREEN="${CSI}32m"  # 绿色
CRED="${CSI}1;31m"  # 红色加粗
CGREEN="${CSI}1;32m"  # 绿色加粗
CYELLOW="${CSI}1;33m"  # 黄色加粗
CBLUE="${CSI}1;34m"  # 蓝色加粗
CMAGENTA="${CSI}1;35m"  # 洋红色加粗
CCYAN="${CSI}1;36m"  # 青色加粗

OUT_ALERT() {  # 定义输出警告信息的函数
    echo -e "${CYELLOW}$1${CEND}"  # 输出黄色警告信息
}

OUT_ERROR() {  # 定义输出错误信息的函数
    echo -e "${CRED}$1${CEND}"  # 输出红色错误信息
}

OUT_INFO() {  # 定义输出一般信息的函数
    echo -e "${CCYAN}$1${CEND}"  # 输出青色信息
}

if [[ -f /etc/redhat-release ]]; then  # 检查是否存在 /etc/redhat-release 文件
    release="centos"  # 如果存在，设置 release 变量为 centos
elif cat /etc/issue | grep -q -E -i "debian|raspbian"; then  # 检查 /etc/issue 文件内容是否包含 debian 或 raspbian
    release="debian"  # 如果匹配，设置 release 变量为 debian
elif cat /etc/issue | grep -q -E -i "ubuntu"; then  # 检查 /etc/issue 文件内容是否包含 ubuntu
    release="ubuntu"  # 如果匹配，设置 release 变量为 ubuntu
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then  # 检查 /etc/issue 文件内容是否包含 centos 或 red hat
    release="centos"  # 如果匹配，设置 release 变量为 centos
elif cat /proc/version | grep -q -E -i "raspbian|debian"; then  # 检查 /proc/version 文件内容是否包含 raspbian 或 debian
    release="debian"  # 如果匹配，设置 release 变量为 debian
elif cat /proc/version | grep -q -E -i "ubuntu"; then  # 检查 /proc/version 文件内容是否包含 ubuntu
    release="ubuntu"  # 如果匹配，设置 release 变量为 ubuntu
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then  # 检查 /proc/version 文件内容是否包含 centos 或 red hat
    release="centos"  # 如果匹配，设置 release 变量为 centos
else
    OUT_ERROR "[错误] 不支持的操作系统！"  # 如果以上检测都不匹配，输出错误信息
    exit 1  # 退出脚本
fi

OUT_ALERT "[信息] 正在更新系统中！"  # 输出系统更新信息
if [[ ${release} == "centos" ]]; then  # 如果操作系统是 centos
    yum makecache  # 更新 yum 缓存
    yum install epel-release -y  # 安装 epel-release 软件包
    yum update -y  # 更新所有软件包
else
    apt update  # 更新 apt 包列表
    apt dist-upgrade -y  # 执行系统全面升级
    apt autoremove --purge -y  # 自动移除不再需要的包
fi

OUT_ALERT "[信息] 正在安装 haveged 增强性能中！"  # 输出安装 haveged 信息
if [[ ${release} == "centos" ]]; then  # 如果操作系统是 centos
    yum install haveged -y  # 安装 haveged 软件包
else
    apt install haveged -y  # 安装 haveged 软件包
fi

OUT_ALERT "[信息] 正在配置 haveged 增强性能中！"  # 输出配置 haveged 信息
systemctl disable --now haveged  # 禁用并停止 haveged 服务
systemctl enable --now haveged  # 启用并启动 haveged 服务

OUT_ALERT "[信息] 正在优化系统参数中！"  # 输出系统优化信息
modprobe ip_conntrack  # 加载 ip_conntrack 内核模块
chattr -i /etc/sysctl.conf  # 解除 /etc/sysctl.conf 文件的不可变属性
cat > /etc/sysctl.conf << EOF  # 写入优化参数到 /etc/sysctl.conf 文件
vm.swappiness = 0  # 设置虚拟内存交换倾向为 0
fs.file-max = 1024000  # 设置最大文件描述符数为 1024000
net.core.rmem_max = 134217728  # 设置最大接收缓存为 134217728
net.core.wmem_max = 134217728  # 设置最大发送缓存为 134217728
net.core.netdev_max_backlog = 250000  # 设置网络设备的最大接受队列为 250000
net.core.somaxconn = 1024000  # 设置最大连接数为 1024000
net.core.default_qdisc = fq_pie  # 设置默认队列规则为 fq_pie
net.ipv4.conf.all.rp_filter = 0  # 禁用所有接口的反向路径过滤
net.ipv4.conf.default.rp_filter = 0  # 禁用默认接口的反向路径过滤
net.ipv4.conf.lo.arp_announce = 2  # 设置环回接口的 ARP 通告模式
net.ipv4.conf.all.arp_announce = 2  # 设置所有接口的 ARP 通告模式
net.ipv4.conf.default.arp_announce = 2  # 设置默认接口的 ARP 通告模式
net.ipv4.ip_forward = 1  # 启用 IPv4 转发
net.ipv4.ip_local_port_range = 1024 65535  # 设置本地端口范围
net.ipv4.neigh.default.gc_stale_time = 120  # 设置邻居表项过期时间
net.ipv4.tcp_ecn = 0  # 禁用 TCP ECN
net.ipv4.tcp_syncookies = 1  # 启用 TCP SYN cookies
net.ipv4.tcp_tw_reuse = 1  # 启用 TIME-WAIT sockets 复用
net.ipv4.tcp_low_latency = 1  # 启用 TCP 低延迟模式
net.ipv4.tcp_fin_timeout = 10  # 设置 TCP FIN 超时时间
net.ipv4.tcp_window_scaling = 1  # 启用 TCP 窗口扩展
net.ipv4.tcp_keepalive_time = 10  # 设置 TCP 保持连接时间
net.ipv4.tcp_timestamps = 0  # 禁用 TCP 时间戳
net.ipv4.tcp_sack = 1  # 启用 TCP Selective Acknowledgements
net.ipv4.tcp_fack = 1  # 启用 TCP Forward Acknowledgements
net.ipv4.tcp_syn_retries = 3  # 设置 TCP SYN 重试次数
net.ipv4.tcp_synack_retries = 3  # 设置 TCP SYN-ACK 重试次数
net.ipv4.tcp_max_syn_backlog = 16384  # 设置 TCP SYN backlog
net.ipv4.tcp_max_tw_buckets = 8192  # 设置 TIME-WAIT 状态连接数
net.ipv4.tcp_fastopen = 3  # 启用 TCP Fast Open
net.ipv4.tcp_mtu_probing = 1  # 启用 TCP MTU Probing
net.ipv4.tcp_rmem = 4096 87380 67108864  # 设置 TCP 接收窗口大小
net.ipv4.tcp_wmem = 4096 65536 67108864  # 设置 TCP 发送窗口大小
net.ipv4.tcp_congestion_control = bbr  # 设置 TCP 拥塞控制算法为 BBR
net.ipv6.conf.all.forwarding = 1  # 启用所有接口的 IPv6 转发
net.ipv6.conf.default.forwarding = 1  # 启用默认接口的 IPv6 转发
net.nf_conntrack_max = 25000000  # 设置 Netfilter 连接跟踪表的最大值
net.netfilter.nf_conntrack_max = 25000000  # 同上
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30  # 设置连接跟踪表的 TIME-WAIT 超时时间
net.netfilter.nf_conntrack_tcp_timeout_established = 180  # 设置连接跟踪表的已建立连接超时时间
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 30  # 设置连接跟踪表的 CLOSE-WAIT 超时时间
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30  # 设置连接跟踪表的 FIN-WAIT 超时时间
EOF

cat > /etc/security/limits.conf << EOF  # 写入文件和进程数限制到 /etc/security/limits.conf 文件
* soft nofile 512000  # 设置所有用户的软文件描述符数为 512000
* hard nofile 512000  # 设置所有用户的硬文件描述符数为 512000
* soft nproc 512000  # 设置所有用户的软进程数为 512000
* hard nproc 512000  # 设置所有用户的硬进程数为 512000
root soft nofile 512000  # 设置 root 用户的软文件描述符数为 512000
root hard nofile 512000  # 设置 root 用户的硬文件描述符数为 512000
root soft nproc 512000  # 设置 root 用户的软进程数为 512000
root hard nproc 512000  # 设置 root 用户的硬进程数为 512000
EOF

cat > /etc/systemd/journald.conf <<EOF  # 写入日志文件限制到 /etc/systemd/journald.conf 文件
[Journal]
SystemMaxUse=384M  # 设置日志文件最大使用空间为 384M
SystemMaxFileSize=128M  # 设置单个日志文件最大大小为 128M
ForwardToSyslog=no  # 禁止将日志转发到 syslog
EOF

sysctl -p  # 应用 sysctl 配置

OUT_INFO "[信息] 优化完毕！"  # 输出优化完成信息
exit 0  # 正常退出脚本
