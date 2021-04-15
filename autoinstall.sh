#!/bin/bash

#首先是设置密码，会提示先输入密码
#Enter current password for root (enter for none):<–初次运行直接回车
#设置密码
#Set root password? [Y/n] <– 是否设置root用户密码，输入y并回车或直接回车
#New password: <– 设置root用户的密码,密码为longtian@ywzx123
#Re-enter new password: <– 再输入一次你设置的密码
#其他配置
#Remove anonymous users? [Y/n] <– 是否删除匿名用户，按Y回车
#Disallow root login remotely? [Y/n] <–是否禁止root远程登录,按Y回车,
#Remove test database and access to it? [Y/n] <– 是否删除test数据库，按Y回车
#Reload privilege tables now? [Y/n] <– 是否重新加载权限表，按Y回车
#初始化MariaDB完成

#关闭selinux
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld && systemctl disable firewalld

yum install -y mariadb-server mariadb

#修改mariadb默认配置文件
cat << EOF > /etc/my.cnf
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
character_set_server=utf8mb4
max_connections=1000
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d
EOF

#启动mariadb
systemctl start mariadb && systemctl enable mariadb

touch /tmp/zabbix.sql
cat << EOF > /tmp/zabbix.sql 
set password for root@localhost=password('longtian@ywzx123');
FLUSH PRIVILEGES;
CREATE DATABASE zabbix character SET utf8 collate utf8_bin;
USE zabbix;
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%' IDENTIFIED BY 'longtian@ywzx123';
FLUSH PRIVILEGES;
DROP DATABASE test;
EOF

#安装zabbix仓库，并安装proxy及agent
rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum clean all
yum install -y zabbix-proxy-mysql-5.0.3 zabbix-agent-5.0.3
cat /tmp/zabbix.sql | mysql -uroot --password=
zcat /usr/share/doc/zabbix-proxy-mysql-5.0.3/schema.sql.gz | mysql -uzabbix --password=longtian@ywzx123 --database=zabbix
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak
mv /etc/zabbix/zabbix_proxy.conf /etc/zabbix/zabbix_proxy.conf.bak
systemctl enable zabbix-proxy && systemctl enable zabbix-agent
cd /etc/zabbix
wget http://192.168.10.161/zabbix_agentd.conf
wget http://192.168.10.161/zabbix_proxy.conf 
