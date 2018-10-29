#!/bin/bash

now_date() {
	echo `date "+%Y-%m-%d %H:%M:%S"`
}

process_mem() {
	mem_info=`cat /proc/$1/status | grep -E 'VmSize|VmRSS|VmData|VmStk|VmExe|VmLib'`
	vm_size=`echo "${mem_info}" | grep -E 'VmSize' | cut -d:  -f2 | sed s/[[:space:]]//g | awk '{sub(/..$/,"")}1'`
	vm_rss=`echo "${mem_info}" | grep -E 'VmRSS' | cut -d:  -f2 | sed s/[[:space:]]//g | awk '{sub(/..$/,"")}1'`
	vm_data=`echo "${mem_info}" | grep -E 'VmData' | cut -d:  -f2 | sed s/[[:space:]]//g | awk '{sub(/..$/,"")}1'`
	vm_stk=`echo "${mem_info}" | grep -E 'VmStk' | cut -d:  -f2 | sed s/[[:space:]]//g | awk '{sub(/..$/,"")}1'`
	vm_exe=`echo "${mem_info}" | grep -E 'VmExe' | cut -d:  -f2 | sed s/[[:space:]]//g | awk '{sub(/..$/,"")}1'`
	vm_lib=`echo "${mem_info}" | grep -E 'VmLib' | cut -d:  -f2 | sed s/[[:space:]]//g | awk '{sub(/..$/,"")}1'`
	echo $vm_size,$vm_rss,$vm_data,$vm_stk,$vm_exe,$vm_lib
}

process_cpu() {
	# return: totalCPUTime processTime
	# totalCPUTime = user + nice + system + idle + iowait + irq + softirq + stealstolen + guest
	# processTime = utime + stime + cutime + cstime
	cpulog=`cat /proc/stat | grep 'cpu ' | awk '{print $2,$3,$4,$5,$6,$7,$8}'`
	totalCPUTime=`echo $cpulog | awk '{print $1 + $2 + $3 + $4 + $5 + $6 + $7}'`
	process_cpulog=`cat /proc/$1/stat | awk '{print $14,$15,$16,$17}'`
	processTime=`echo $process_cpulog | awk '{print $1 + $2 + $3 + $4}'`
	echo $totalCPUTime $processTime

}

process_cpu_rate() {
	# processCPUUse = processTime / totalCPUTime
	processTime=`expr $4 - $2`
	totalCPUTime=`expr $3 - $1`
	rate=`expr "scale=2;$processTime * 100 / $totalCPUTime" | bc -l`
	echo $rate
}

refresh_window() {
	clear
    echo ${@:1:2}
	echo "CPU(%):${@:3:1}"
    echo $(process_mem title)
    echo ${@:4}
}

lsofnum(){
	if [ $1 -eq -1 ]
	then
		echo $t
		return
	fi
	count=`netstat -nat|grep -i "$1"|wc -l`
        declare -i t=${count}-1
#	count=`lsof -i:$1 | wc -l`
#	t=`expr $count - 2`
#	declare -i t=${count}-2
	echo $t
}
main_proc_monitor() {
	if [ -z "$1" ];then
		echo "please enter process pid"
		return
	fi
	if [ -z "$2" ];then
		echo "please enter port number"
		return
	fi

	local port=-1
	if [ $# -ge 2 ]; then
		port=$2
	fi

	local time=1
	if [ $# -ge 3 ]; then
		time=$3
	fi
	echo "间隔${time}秒收集一次"

	OUTPUT_FILENAME=$1"monitor.csv"
	if [ ! -f "$OUTPUT_FILENAME" ];then
		touch $OUTPUT_FILENAME
	fi
	# 加BOM文件头
	echo -e -n "\xef\xbb\xbf" > $OUTPUT_FILENAME

	title="datetime,cpu,VmSize,VmRss,VmData,VmStk,VmExe,VmLib,connectNum"
	echo $title >> $OUTPUT_FILENAME

	status1=$(process_cpu $1)

	while true
	do
		total1=`echo $status1 | awk '{print $1}'`
		proc1=`echo $status1 | awk '{print $2}'`


		sleep $time

		status2=$(process_cpu $1)
		total2=`echo $status2 | awk '{print $1}'`
		proc2=`echo $status2 | awk '{print $2}'`

		now_date=$(now_date)
		proc_cpu_rate=$(process_cpu_rate $total1 $proc1 $total2 $proc2)
		mem=$(process_mem $1)
		count=$(lsofnum $port)
		echo $now_date,$proc_cpu_rate,$mem,$count >> $OUTPUT_FILENAME
		echo $proc_cpu_rate,$mem,$count
		status1=${status2}
	done
}

main_proc_monitor $*
