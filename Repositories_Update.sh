#!/bin/sh
# 开启外网访问权限，同步远程服务器git仓库到本地服务器
# 同步完毕后关闭外网访问权限

# vars
UPDATELOG='update.log'
ERRORFLAG=0
# UPREPOS="freeswitch.git opensips-cp.git opensips.git"		#for 循环的另一种用
UPREPOS=(freeswitch.git opensips-cp.git opensips.git)
GWAY_DNS="x.x.x.x"					# 设置外网网关及DNS

# log
echo "$(date '+%Y-%m-%d %H:%M')" >> ${UPDATELOG} 

# modify cfg for connect wlan net
sudo sed -i "s/GATEWAY=/GATEWAY=${GWAY_DNS}/" /etc/sysconfig/network-scripts/ifcfg-ens192
sudo sed -i "s/DNS1=/DNS1=${GWAY_DNS}/" /etc/sysconfig/network-scripts/ifcfg-ens192
{ sudo systemctl restart network } || \
	{ echo -e "\tConnect net out failed!" >> ${UPDATELOG};\
	exit 1 }

# sync needed repoitories
# for REPO in ${UPREPOS}		# for 循环的另一种用法
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
sudo sed -i "s/${GWAY_DNS}//g" /etc/sysconfig/network-scripts/ifcfg-ens192
{ sudo systemctl restart network } || echo -e "\tCut wlan net failed!" >> ${UPDATELOG}

# 特别说明：脚本放到指定位置后添加定时任务
# 例如：30 1 * * * git /home/git/bin/Repositories_Update.sh
# 重启定时任务 systemctl restart crond
