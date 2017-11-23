#!/bin/sh
# 开启外网访问权限，同步远程服务器git仓库到本地服务器
# 同步完毕后关闭外网访问权限

# vars
UPDATELOG='update.log'										# 更新日志记录
ERRORFLAG=0
GWAY_DNS="x.x.x.x"											# 设置外网网关及DNS
DEVICEPATH='/etc/sysconfig/network-scripts'					# 网卡配置文件路径
DEVICENAME='ens192'											# 网卡名字
# UPREPOS="freeswitch.git opensips-cp.git opensips.git"		# for循环的另一种用法
UPREPOS=(freeswitch.git opensips-cp.git opensips.git)		# 需要同步的仓库列表

# log
echo "$(date '+%Y-%m-%d %H:%M')" >> ${UPDATELOG} 

# modify cfg for connect wlan net
sudo sed -i "s/GATEWAY=/GATEWAY=${GWAY_DNS}/" ${DEVICEPATH}/ifcfg-${DEVICENAME}
sudo sed -i "s/DNS1=/DNS1=${GWAY_DNS}/" ${DEVICEPATH}/ifcfg-${DEVICENAME}
sudo systemctl restart network 
test 0 -ne $? && echo -e "\tBefore sync: restart network failed! exit." >> ${UPDATELOG} && exit 1 

# sync needed repoitories
# for REPO in ${UPREPOS}									# for循环的另一种用法
for REPO in ${UPREPOS[*]}
do
	git --git-dir=${HOME}/repositories/${REPO} remote update
	if [ $? -ne 0 ]
	then
		ERRORFLAG=1
		echo -e "\t${REPO} update failed!" \
			>> ${UPDATELOG}
	fi
done

# log
if [ 0 -eq ${ERRORFLAG} ]
then
	echo -e "\tAll update is done." >> ${UPDATELOG}
fi

# modify cfg for machine cut wlan net only for lan use
sudo sed -i "s/${GWAY_DNS}//g" ${DEVICEPATH}/ifcfg-${DEVICENAME}
sudo systemctl restart network 
test 0 -ne $? && echo -e "\tAfter sync: restart network failed!" >> ${UPDATELOG}

# 特别说明：脚本放到指定位置后添加定时任务
# 例如：30 1 * * * git /home/git/bin/Repositories_Update.sh
# 相应执行定时任务的用户要有sudo权限
# 重启定时任务 systemctl restart crond
