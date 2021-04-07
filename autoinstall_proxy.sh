#!/bin/bash

#首先是设置密码，会提示先输入密码
#Enter current password for root (enter for none):<–初次运行直接回车
#设置密码
#Set root password? [Y/n] <– 是否设置root用户密码，输入y并回车或直接回车
#New password: <– 设置root用户的密码
#Re-enter new password: <– 再输入一次你设置的密码
#其他配置
#Remove anonymous users? [Y/n] <– 是否删除匿名用户，回车
#Disallow root login remotely? [Y/n] <–是否禁止root远程登录,回车,
#Remove test database and access to it? [Y/n] <– 是否删除test数据库，回车
#Reload privilege tables now? [Y/n] <– 是否重新加载权限表，回车
#初始化MariaDB完成，接下来测试登录
#mysql -uroot -ppassword
#完成。

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld && systemctl disable firewalld

yum install -y mariadb-server mariadb
mysql_secure_installation

cat >> EOF < /usr/share/doc/zabbix-proxy-mysql*/zabbix.sql
CREATE DATABASE zabbix character SET utf8 collate utf8_bin;
USE zabbix;
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%' IDENTIFIED BY 'longtian@ywzx123';
FLUSH PRIVILEGES;
EOF

yum -y install yum-utils
yum-config-manager --enable rhel-7-server-optional-rpms
yum install -y zabbix-proxy-mysql
cat /usr/share/doc/zabbix-proxy-mysql*/zabbix.sql | mysql -uroot -p longtian@ywzx123
zcat /usr/share/doc/zabbix-proxy-mysql*/schema.sql.gz | mysql -uzabbix -p longtian@ywzx123
systemctl enable zabbix-proxy && systemctl start zabbix-proxy

