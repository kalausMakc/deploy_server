#!/bin/bash
######################## Деплой чистого сервера #########################
############################### 06.05.2019 ##############################
#########################################################################

echo "==================================================================="
echo "===================== START DEPLOY SERVER ========================="
echo "==================================================================="
sleep 5s

echo "==================================================================="
echo "============================ BACKUP ==============================="
echo "==================================================================="
if ! [ -d /home/backup/etc/ ]; then
mkdir -p /home/backup/etc
echo "Create /home/backup/etc"
fi

if [ -f /etc/pure-ftpd/pure-ftpd.conf ]; then
cp /etc/pure-ftpd/pure-ftpd.conf /root/backup/etc/pure-ftpd.conf.`date +%Y-%m-%d_%H-%M`
echo "pure-ftpd.conf copy complete"
fi

if [ -f /etc/sysctl.conf ]; 
then cp /etc/sysctl.conf /home/backup/etc/sysctl.conf.`date +%Y-%m-%d_%H-%M`
echo "sysctl.conf copy complete"
fi

if [ -f /etc/hosts ]; then
cp /etc/hosts /home/backup/etc/hosts.`date +%Y-%m-%d_%H-%M`
echo "hosts copy complete"
fi

if [ -f /etc/httpd/conf/httpd.conf ]; then
cp -r /etc/httpd /home/backup/etc.`date +%Y-%m-%d_%H-%M`
echo "httpd.conf copy complete"
fi
# !!!! надо будет продолжить
echo "==================================================================="
echo "======================= BACKUP COMPLETE ==========================="
echo "==================================================================="

sleep 1

echo "==================================================================="
echo "===================== TIME SYNCHRONIZATION ========================"
echo "==================================================================="
# синхронизация времени
yum remove -y ntp
timedatectl set-timezone Europe/Moscow
yum -y install chrony
systemctl restart chronyd 
systemctl enable chronyd
echo "==================================================================="
echo "================ TIME SYNCHRONIZATION COMPLETE ===================="
echo "==================================================================="

sleep 1

echo "==================================================================="
echo "========================= REPO INSTALL ============================"
echo "==================================================================="
# установка репозиторий
yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
yum localinstall -y --nogpgcheck https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm
yum localinstall -y --nogpgcheck http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/e/epel-release-7-11.noarch.rpm
yum localinstall -y --nogpgcheck http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

if ! [ -f /etc/yum.repos.d/ius-archive.repo ]; then
cat > /etc/yum.repos.d/ius-archive.repo << EOL
[ius-arhive]
name=IUS arhive
baseurl=http://dl.iuscommunity.org/pub/ius/archive/CentOS/7/x86_64/
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/IUS-COMMUNITY-GPG-KEY
EOL
echo "Edit ius-archive.repo complete"
fi

if ! [ -f /etc/yum.repos.d/MariaDB.repo ]; then
cat > /etc/yum.repos.d/MariaDB.repo << EOL
# MariaDB 10.3 CentOS repository list - created 2019-04-25 09:41 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.3/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOL
echo "Edit MariaDB.repo complete"
fi

if ! [ -f /etc/yum.repos.d/nginx.repo ]; then
cat > /etc/yum.repos.d/nginx.repo <<EOL
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
EOL
echo "Edit nginx.repo complete"
fi

# обновление пакетов
yum update -y
echo "==================================================================="
echo "==================== REPO INSTALL COMPLETE ========================"
echo "==================================================================="

sleep 1

echo "==================================================================="
echo "======================= CONFIGURE LIMIT ==========================="
echo "==================================================================="
# Настройка лимитов
echo "fs.inotify.max_user_watches=99999999" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets=99999999" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=65536" >> /etc/sysctl.conf
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "fs.file-max=99999999" >> /etc/sysctl.conf
echo "kernel.sem=1000 128000 128 512" >> /etc/sysctl.conf
echo "vm.dirty_ratio=5" >> /etc/sysctl.conf
echo "fs.aio-max-nr=262144" >> /etc/sysctl.conf
echo "kernel.panic=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.conf
echo "kernel.sysrq=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.send_redirects=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.ip_dynaddr=1" >> /etc/sysctl.conf
echo "kernel.sem=1000 256000 128 1024" >> /etc/sysctl.conf
echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
echo "fs.inotify.max_user_instances=1024" >> /etc/sysctl.conf
echo "kernel.msgmax=65536" >> /etc/sysctl.conf
echo "kernel.shmmax=4294967295" >> /etc/sysctl.conf
echo "kernel.shmall=268435456" >> /etc/sysctl.conf
echo "kernel.shmmni=4096" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time=15" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_intvl=10" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_probes=5" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout=30" >> /etc/sysctl.conf
echo "net.ipv4.tcp_window_scaling=0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_sack=0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps=0" >> /etc/sysctl.conf
echo "vm.swappiness=10" >> /etc/sysctl.conf
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
sed -i 's/.*net.netfilter.nf_conntrack_max.*/net.netfilter.nf_conntrack_max=99999999/g' /etc/sysctl.conf
sed -i 's/.*fs.inotify.max_user_watches.*/fs.inotify.max_user_watches=99999999/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.net.ipv4.tcp_max_tw_buckets.*/net.ipv4.net.ipv4.tcp_max_tw_buckets=99999999/g' /etc/sysctl.conf
sed -i 's/.*tcp_max_tw_buckets_ub.*/net.ipv4.tcp_max_tw_buckets_ub=65535/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_max_tw_buckets_ub.*/net.ipv4.tcp_max_tw_buckets_ub=65535/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_syncookies.*/net.ipv4.tcp_syncookies=1/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_max_syn_backlog.*/net.ipv4.tcp_max_syn_backlog=65536/g' /etc/sysctl.conf
sed -i 's/.*net.core.somaxconn.*/net.core.somaxconn=65535/g' /etc/sysctl.conf
sed -i 's/.*fs.file-max.*/fs.file-max=99999999/g' /etc/sysctl.conf
sed -i 's/.*kernel.sem.*/kernel.sem=1000 128000 128 512/g' /etc/sysctl.conf
sed -i 's/.*vm.dirty_ratio.*/vm.dirty_ratio=5/g' /etc/sysctl.conf
sed -i 's/.*fs.aio-max-nr.*/fs.aio-max-nr=262144/g' /etc/sysctl.conf
sed -i 's/.*kernel.panic.*/kernel.panic=1/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.conf.all.rp_filter.*/net.ipv4.conf.all.rp_filter=1/g' /etc/sysctl.conf
sed -i 's/.*kernel.sysrq.*/kernel.sysrq=1/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.conf.default.send_redirects.*/net.ipv4.conf.default.send_redirects=1/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.conf.all.send_redirects.*/net.ipv4.conf.all.send_redirects=0/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.ip_dynaddr.*/net.ipv4.ip_dynaddr=1/g' /etc/sysctl.conf
sed -i 's/.*kernel.sem.*/kernel.sem=1000 256000 128 1024/g' /etc/sysctl.conf
sed -i 's/.*kernel.msgmn.*/kernel.msgmn=1024/g' /etc/sysctl.conf
sed -i 's/.*fs.inotify.max_user_watches.*/fs.inotify.max_user_watches=524288/g' /etc/sysctl.conf
sed -i 's/.*fs.inotify.max_user_instances.*/fs.inotify.max_user_instances=1024/g' /etc/sysctl.conf
sed -i 's/.*kernel.msgmnb.*/kernel.msgmnb=65536/g' /etc/sysctl.conf
sed -i 's/.*kernel.msgmax.*/kernel.msgmax=65536/g' /etc/sysctl.conf
sed -i 's/.*kernel.shmmax.*/kernel.shmmax=4294967295/g' /etc/sysctl.conf
sed -i 's/.*kernel.shmall.*/kernel.shmall=268435456/g' /etc/sysctl.conf
sed -i 's/.*kernel.shmmni.*/kernel.shmmni=4096/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_keepalive_time.*/net.ipv4.tcp_keepalive_time=15/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_keepalive_intvl.*/net.ipv4.tcp_keepalive_intvl=10/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_keepalive_probes.*/net.ipv4.tcp_keepalive_probes=5/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_fin_timeout.*/net.ipv4.tcp_fin_timeout=30/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_window_scaling.*/net.ipv4.tcp_window_scaling=0/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_sack.*/net.ipv4.tcp_sack=0/g' /etc/sysctl.conf
sed -i 's/.*net.ipv4.tcp_timestamps.*/net.ipv4.tcp_timestamps=0/g' /etc/sysctl.conf 
sed -i 's/.*vm.swappiness.*/vm.swappiness=10/g' /etc/sysctl.conf 
sed -i 's/.*vm.overcommit_memory.*/vm.overcommit_memory=1/g' /etc/sysctl.conf 

# применить параметры 
sysctl -p
echo "Settings limit complete"

# лимиты системы
cat > /etc/security/limits.d/nofile.conf << EOL
root      soft    nofile           1048576
root      hard    nofile           1048576
*         soft    nofile           1048576
*         hard    nofile           1048576    
*         hard    core             0
EOL

cat > /etc/security/limits.d/90-nproc.conf << EOL
*       hard    nproc   unlimited
*       soft    nproc   unlimited
root    hard    nproc   unlimited
root    soft    nproc   unlimited
EOL

cat > /etc/security/limits.d/90-stack.conf << EOL
*       hard    stack   unlimited
*       soft    stack   unlimited
root    hard    stack   unlimited
root    soft    stack   unlimited
EOL
echo "==================================================================="
echo "======================= CONFIGURE LIMIT ==========================="
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "========================= INSTALL SUDO ============================"
echo "==================================================================="
# установка sudo
yum install -y sudo

sed -i 's/Defaults\    requiretty/#Defaults\    requiretty/g' /etc/sudoers
echo "==================================================================="
echo "==================== INSTALL SUDO COMPLETE ========================"
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "======================= CONFIGURE BASH ============================"
echo "==================================================================="
# конфигурация bash
localedef  -i ru_RU -f UTF-8 ru_RU.UTF-8
export LC_ALL="ru_RU.UTF-8"

mkdir -p /home/backup/etc/sysconfig/
if [ -f /etc/sysconfig/i18n ]; then
cp /etc/sysconfig/i18n /home/backup/etc/sysconfig/i18n.`date +%Y-%m-%d_%H-%M`
fi  

cat > /etc/sysconfig/i18n << EOL
LANG="ru_RU.UTF-8"
SUPPORTED="ru_RU.UTF-8:ru_RU:ru"
SYSFONT="latarcyrheb-sun16"
EOL

cat > /etc/profile.d/bash.sh << EOL
PS1='\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;36m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\] '     
EOL
echo "==================================================================="
echo "=================== CONFIGURE BASH COMPLETE ======================="
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "======================== INSTALL SCREEN ==========================="
echo "==================================================================="
# установка screen
yum install screen -y

mkdir -p /home/backup/etc/skel
if [ -f /etc/skel/.screenrc ]; then
cp /etc/skel/.screenrc /home/backup/etc/skel/.screenrc.`date +%Y-%m-%d_%H-%M`
fi

wget --no-check-certificate -q -O /etc/skel/.screenrc 'https://repo.netlinux.ru/screenrc'
wget --no-check-certificate -q -O /root/.screenrc 'https://repo.netlinux.ru/screenrc'
echo "==================================================================="
echo "=================== INSTALL SCREEN COMPLETE ======================="
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "======================= DISABLED SELINUX =========================="
echo "==================================================================="
# базовая конфигурация
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

systemctl stop firewalld
systemctl disable firewalld
echo "==================================================================="
echo "=================== DISABLED SELINUX COMPLETE ====================="
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "======================== CLEANING CACHE ==========================="
echo "==================================================================="
# очистка кеша dns
yum install -y nscd
systemctl start nscd
systemctl enable nscd
nscd -i hosts
echo "==================================================================="
echo "==================== CLEANING CACHE COMPLETE ======================"
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "======================== ACTIVATE FSTRIM ========================="
echo "==================================================================="
#включить fstrim
systemctl enable fstrim.timer
systemctl restart fstrim.timer
echo "==================================================================="
echo "==================== ACTIVATE FSTRIM COMPLETE ====================="
echo "==================================================================="

sleep 1s

echo "==================================================================="
echo "================== CONFIGURATION ENERGY SAVING ===================="
echo "==================================================================="
# оптимизация энергосбережения
mkdir -p /etc/tuned/no-thp
cat > /etc/tuned/no-thp/tuned.conf << EOL
[main]
include=virtual-guest

[vm]
transparent_hugepages=never
EOL

tuned-adm profile no-thp
echo "==================================================================="
echo "============== CONFIGURATION ENERGY SAVING COMPLETE ==============="
echo "==================================================================="

sleep 1

echo "==================================================================="
echo "============== CONFIGURATION SERVER COMPLETE ==============="
echo "==================================================================="
sleep 1
exit