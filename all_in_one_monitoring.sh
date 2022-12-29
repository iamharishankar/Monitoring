#!/bin/bash
dba_team=abc@abc.com
filelocation="/tmp"                                                                     
MESSAGE="$filelocation/mail.txt"                                                        
ZMESSAGE="$filelocation/zmail.txt"                                                              
Zlistfile="$filelocation/Zlistfile.log"                         
memoryfile="$filelocation/memory_$(date "+%Y%m%d%H%M%S").csv"   
memoryfileday="$filelocation/memory_$(date "+%Y%m%d").csv"      
cpufile="$filelocation/cpu_$(date "+%Y%m%d%H%M%S").csv"         
cpufileday="$filelocation/cpu_$(date "+%Y%m%d").csv"            
zombiefile="$filelocation/zombie_$(date "+%Y%m%d%H%M%S").csv"   
zombiefileday="$filelocation/zombie_$(date "+%Y%m%d").csv" 

################### Server Health Monitoring steps ##################################
# Step0: Check the present date and time.
echo "Current Date and Time is: `date +"%Y-%m-%d %T"`"
time=$(date +"%Y-%m-%d %T")

echo "Server Status:  $USER@$HOSTNAME"

# Step1: Check the System Load
# Check Load Average
#loadaverage=`uptime | cut -d'l' -f2 | awk '{print $3 " " $4 " " $5}'\ | sed 's/,//'`
loadaverage=`uptime | cut -d'l' -f2 | awk '{print $3 " " $4 " " $5}'`
echo "Current Load Average is: $loadaverage"

# Step2: Check the CPU utilization
#store cpu utilization with %
CPU_USAGE=$(top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f%%\n", prefix, 100 - v }')
#store cpu utilization without % for if condition
CPU_USAGE2=$(top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f\n", prefix, 100 - v }')
DATE=$(date "+%Y-%m-%d %H:%M:")
CPU_USAGE1="$DATE CPU: $CPU_USAGE"
# removing decimal value for comparision.
c_value=$(echo "($CPU_USAGE2 + 0.5)/1" | bc)
echo "CPU Current Utilization is : $CPU_USAGE "

# Step3 : Check the RAM utilization
ramusage=$(free | awk '/Mem/{printf("RAM Usage: %.2f\n"), $3/$2*100}'| awk '{print $3}')
r_value=$(echo "($ramusage + 0.5)/1" | bc)

echo "Memory Current Usage is: $ramusage%"

# Step4: Check the Swap utilization
swapusage=$(free | awk '/Swap/{printf("Swap Usage: %.2f\n"), $3/$2*100}'| awk '{print $3}')
s_value=$(echo "($swapusage + 0.5)/1" | bc)
echo "Swap Current Usage is: $swapusage%"

# Step5: Check the zombie process running
#zombie_process=$(ps aux | grep 'Z')
zombie_process=$(top -b1 -n1 | grep Z)
z_value=$(top -b1 -n1 | grep Z|wc -l)
echo "Zombie Process count is: $z_value"
	if [ $z_value != 0 ]
	then
		echo "Zombie Process list: "
		echo "$zombie_process"
	else
	echo ""
	fi
echo "Comparing the CPU, Memory, and Swap Utilization with the respective threshold values."

# Step6: Compare the CPU, Memory, and Swap Utilization with the respective threshold values.
if [ "$c_value" -ge 85 ] 
then
  SUBJECT="ATTENTION: CPU load is high on $(hostname) at $(date)"
  echo "Dear Team," >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Server:  $USER@$HOSTNAME" >> $MESSAGE
  echo "CPU current usage is: $CPU_USAGE" >> $MESSAGE
  echo "Memory Current Usage is: $ramusage%" >> $MESSAGE
  echo "Swap Current Usage is: $swapusage%" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "Top 10 Processes which consuming high CPU using the ps command" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%cpu | head -10)" >> $MESSAGE
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%cpu | head -20)" >> $cpufile
  echo Current Date and Time is: `date +"%Y-%m-%d %T"` >> $cpufileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%cpu | head -20)" >> $cpufileday
  echo "" >> $MESSAGE
  echo "Kindly check the attached file for top 20 processes consuming high CPU" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Thank you " >> $MESSAGE
  echo "DBA Team " >> $MESSAGE
  
  mail -r no_reply@abc.com -s "$SUBJECT" -a "$cpufile" "$dba_team" < $MESSAGE

  rm /tmp/mail.txt
  rm -rf $cpufile
  echo "Server CPU utilization has exceeded the threshold"
else
echo "Server CPU utilization is under the threshold."
fi

if [ "$r_value" -ge 85 ] 
then
  SUBJECT="ATTENTION: Memory load is high on $(hostname) at $(date)"
  echo "Dear Team," >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Server:  $USER@$HOSTNAME" >> $MESSAGE
  echo "CPU current usage is: $CPU_USAGE" >> $MESSAGE
  echo "Memory Current Usage is: $ramusage%" >> $MESSAGE
  echo "Swap Current Usage is: $swapusage%" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "Top 10 Processes which consuming high Memory using the ps command" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -10)" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "$(ps aux | head -1; ps aux | sort -rnk 4 | head -20)" >> $MESSAGE
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -20)" >> $memoryfile
  echo Current Date and Time is: `date +"%Y-%m-%d %T"` >> $memoryfileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -20)" >> $memoryfileday
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Kindly check the attached file for top 20 processes consuming high Memory" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Thank you " >> $MESSAGE
  echo "DBA Team " >> $MESSAGE
  
  mail -r no_reply@abc.com -s "$SUBJECT" -a "$memoryfile" "$dba_team" < $MESSAGE
 
  rm /tmp/mail.txt
  rm -rf $memoryfile
  echo "Server Memory utilization has exceeded the threshold"
else
 echo "Server Memory utilization is under the threshold."
fi

if [ "$s_value" -ge 50 ] 
then
  SUBJECT="ATTENTION: Swap Memory is high on $(hostname) at $(date)"
  echo "Dear Team," >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Server:  $USER@$HOSTNAME" >> $MESSAGE
  echo "CPU current usage is: $CPU_USAGE" >> $MESSAGE
  echo "Memory Current Usage is: $ramusage%" >> $MESSAGE
  echo "Swap Current Usage is: $swapusage%" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "Present swap status using free command" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  free -h -w >> $MESSAGE
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -20)" >> $memoryfile
  echo "" >> $MESSAGE
  echo "$(ps aux | head -1; ps aux | sort -rnk 4 | head -20)" >> $memoryfile
  echo Current Date and Time is: `date +"%Y-%m-%d %T"` >> $memoryfileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -20)" >> $memoryfileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%cpu | head -20)" >> $cpufile
  echo Current Date and Time is: `date +"%Y-%m-%d %T"` >> $cpufileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%cpu | head -20)" >> $cpufileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%cpu | head -20)" >> $memoryfile
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Kindly check the attached file for top 20 processes consuming high CPU and Memory" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Thank you " >> $MESSAGE
  echo "DBA Team " >> $MESSAGE
  mail -r no_reply@abc.com -s "$SUBJECT" -a "$memoryfile" "$dba_team" < $MESSAGE

  rm /tmp/mail.txt
  rm -rf $memoryfile 
  echo "Server Swap utilization has exceeded the threshold"
else
  echo "Server Swap utilization is under the threshold."
fi
  
if [ "$z_value" -ge 1 ] 
then
  SUBJECT="ATTENTION: Found Zombie processes on $(hostname) at $(date)"
  echo "Dear Team," >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Server:  $USER@$HOSTNAME" >> $MESSAGE
  echo "CPU current usage is: $CPU_USAGE" >> $MESSAGE
  echo "Memory Current Usage is: $ramusage%" >> $MESSAGE
  echo "Swap Current Usage is: $swapusage%" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "Zombie Processes running using the top command" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "$(top -b1 -n1 | grep Z)" >> $MESSAGE
  echo "$(top -b1 -n1 | grep Z)" >> $zombiefile
  echo "$(top -b1 -n1 | grep Z)" >> $zombiefileday
  ps axo stat,ppid,pid,comm | grep -w defunct > $Zlistfile
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "Zombie Processes running using the ps command" >> $MESSAGE
  echo "+------------------------------------------------------------------+" >> $MESSAGE
  echo "$(ps -ef | { head -1; grep defunct; })" >> $MESSAGE
  echo "Zombie Process kill execution script is initiated now. "
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Thank you " >> $MESSAGE
  echo "DBA Team " >> $MESSAGE
  
  mail -r no_reply@abc.com -s "$SUBJECT" -a "$zombiefile" "$dba_team" < $MESSAGE
  
  rm /tmp/mail.txt
  rm -rf $zombiefile 

  echo "Server Zombie Process has exceeded the threshold"
  echo "ATTENTION: Found Zombie process on $(hostname) at $(date)"
  echo "List of Zombie Process will be killed: "
  cat $Zlistfile
  echo "Number of lines in $Zlistfile: $(wc -l < $Zlistfile )"
  echo "Executing the Zombie process kill steps. "
  while read name; do
    echo "Initiating the kill process for Zombie Process: $name"
	#string=$(echo -e " $name" | tr '\n' ' ' | sed -e 's/[^0-9]/ /g' -e 's/^ *//g' -e 's/ *$//g' | tr -s ' ' | sed 's/ /\n/g')
	 string=$(echo -e " $name" | grep -o -E '[0-9]+')
	 #echo "$string"
    PPID_V=$(echo "$string" | head -1)
    echo "PPID: $PPID_V"
    PID_V=$(echo "$string" | tail -1)
    #echo "PID: $PID_V"
    echo "Trying to kill the PPID $PPID_V by sending SIGCHLD signal."
	sudo kill -s SIGCHLD $PPID_V
	
			if [ $? -gt 0 ];
			then 
				echo "Zombie process with $PPID_V is killed by sending SIGCHLD signal."
			else 
				echo "Trying to kill the PPID $PPID_V using kill command." 
				sudo kill -9 $PPID_V
				zk_value=$(top -b1 -n1 | grep Z|wc -l)
				echo "Present Zombie Process list is : $zk_value"
				echo "The PPID $PPID_V is killed successfully."
				  ZSUBJECT=" The Zombie process is killed successfully on $(hostname) at $(date)."
				  echo "Dear Team," >> $ZMESSAGE
				  echo "" >> $ZMESSAGE
				  echo "Server:  $USER@$HOSTNAME" >> $ZMESSAGE
				  echo "The PPID $PPID_V is killed successfully." >> $ZMESSAGE
				  echo "Present Zombie Process list is : $zk_value" >> $ZMESSAGE
				  echo "" >> $ZMESSAGE
				  echo "" >> $ZMESSAGE
				  echo "Thank you " >> $ZMESSAGE
				  echo "DBA Team " >> $ZMESSAGE
				  mail -r no_reply@abc.com -s "$ZSUBJECT" "$dba_team" < $ZMESSAGE
				  
				  rm -rf $ZMESSAGE				
			
			fi

	echo "+++++++++++++++++++++++++++++"
  done < "$Zlistfile"
  
else
	echo "Server Zombie Process is under the threshold."
fi

# Step7: Monitor mounts on the server
# Step8: Monitor services on the server
UP=$(systemctl status mysqld | grep 'running' | awk '{ print $3 }')
if [[ $UP != *running* ]];
#UP=$(pgrep mysqld | wc -l);
#if [ "$UP" -ne 1 ];
then
    echo "MySQL is down.";
    sudo systemctl start mysqld
	echo "Dear Team,
	
	Time: $(date)
	Server : $(hostname)
	Alert: MySQL service is down, trying to restart it.
	
Thanks and regards
DBA Team
	
	" |
	 mail -r no_reply@abc.com -s "Alert: MySQL service is down!" "$dba_team"

else
    echo "MySQL service is running." | tee -a $log
fi

# Step9: Monitor log files
# Monitor MySQL server logs
fromdate=$(date +"%Y-%m-%d")
#echo "$fromdate"
cd /var/log/ || return
a=$(grep -w "FAILED\|Failed\|Error\|REJECTED" mysqld.log | grep "$fromdate")
echo "$a"
if [[ -n "${a// /}" ]];
then
b=$(echo $a)
echo "Dear Team,

Errors/Warnings found in MySQL Server Log, kindly check the log file.
---------------------------------------------------------------
"$b"

---------------------------------------------------------------
Thanks and regards
DBA Team
" | mail -r no_reply@abc.com -s "Errors/Warnings found in MySQL Server Log" "$dba_team"

else
echo "No Errors/Warnings found in MySQL Server Log"     
fi

# Monitor MySQL Backup logs
#fromdate=$(date -d "1 days ago" | awk '{print $1 " "$2 " " $3}')
fromdate=$(date | awk '{print $1 " "$2 " " $3}')
cd /mnt/sqldata/SQL-NetBackup/$HOSTNAME/ || return
a=$(grep -w "FAILED\|Failed\|Error\|REJECTED" sqldump.log | grep "$fromdate")
echo "$a"
if [[ -n "${a// /}" ]];
then
b=$(echo $a)
echo "Dear Team,

Errors/Warnings found in $HOSTNAME MySQL Server Dump Log, kindly check the log file.
---------------------------------------------------------------
"$b"

---------------------------------------------------------------
Thanks and regards
DBA Team
" | mail -r no_reply@abc.com -s "Errors/Warnings $HOSTNAME MySQL Server Dump Log" "$dba_team"

else
echo "No Errors/Warnings found in MySQL Server Dump Log"     
fi

# Monitor MySQL Database Size
## Mysql DB Credentials
DB_USER='backup_user'
DB_PASSWD='B@ckUp@MYD@T@!@#1'

echo "DB Size check for database: confluence on $HOSTNAME"
confluence=$(mysql -u$DB_USER -p$DB_PASSWD -h localhost -e "SELECT  sum(round(((data_length + index_length) / 1024 / 1024 / 1024), 0))  as 'Size in GB'
FROM information_schema.TABLES
WHERE table_schema = 'confluence';" -s -N)
echo "confluence DB size is $confluence"

# Step 10: Monitor HDD Size and alert
# Gathering information on HDD utilization for MySQL data mount.
MM=$(df -h | grep -vE '^Filesystem|devtmpfs|tmpfs|/dev/mapper/rhel_rhel--template-root|/dev/mapper/rhel_rhel--template-home|/dev/sda1|/dev/mapper/confluence_vg-confluence_lv|/db_backups/confluence' | awk '{ print $2 " " $1 }')

#echo "MySQL Mount is: $MM"

MMTS=$(df -h | grep -vE '^Filesystem|devtmpfs|tmpfs|/dev/mapper/rhel_rhel--template-root|/dev/mapper/rhel_rhel--template-home|/dev/sda1|/dev/mapper/confluence_vg-confluence_lv|/db_backups/confluence'  | awk '{ print $2 " " $1 }')

MMTS1=$(echo $MMTS | sed 's/[^0-9]//g' | rev | cut -c1- | rev)
#echo "MySQL Mount Total Size is: $MMTS1"

MMUS=$(df -h | grep -vE '^Filesystem|devtmpfs|tmpfs|/dev/mapper/rhel_rhel--template-root|/dev/mapper/rhel_rhel--template-home|/dev/sda1|/dev/mapper/confluence_vg-confluence_lv|/db_backups/confluence'  | awk '{ print $3 " " $1 }')

MMUS1=$(echo $MMUS | sed 's/[^0-9]//g' | rev | cut -c1- | rev)
#echo "MySQL Mount Used Size is: $MMUS1"

MMUP=$(df -h | grep -vE '^Filesystem|devtmpfs|tmpfs|/dev/mapper/rhel_rhel--template-root|/dev/mapper/rhel_rhel--template-home|/dev/sda1|/dev/mapper/confluence_vg-confluence_lv|/db_backups/confluence'  | awk '{ print $5 }')
echo "MySQL Mount used in % is: $MMUP" 

MMUPC=$(df -h | grep -vE '^Filesystem|devtmpfs|tmpfs|/dev/mapper/rhel_rhel--template-root|/dev/mapper/rhel_rhel--template-home|/dev/sda1|/dev/mapper/confluence_vg-confluence_lv|/db_backups/confluence'  | awk '{ print $5 }' | awk '{ print $1}' | cut -d'%' -f1)
PARTITION=$(df -h | grep -vE '^Filesystem|devtmpfs|tmpfs|/dev/mapper/rhel_rhel--template-root|/dev/mapper/rhel_rhel--template-home|/dev/sda1|/dev/mapper/confluence_vg-confluence_lv|/db_backups/confluence'  | awk '{ print $1 }')
#### Notification users in case the utilization is above 85%. Kindly defined the threshold value. ################
if [ $MMUPC -ge 85 ]; then
    echo "Dear Team,
	
	Time: $(date)
	Server : $(hostname)
	HDD : $PARTITION
	Utilization %: $MMUP
	Alert: Running out of space.
	
Thanks and regards
SysAdmin Team
	
	" |
     mail -r no_reply@abc.com -s "Alert: Almost out of disk space $MMUP " "$dba_team"
else 
   echo "MySQL Mount Utilization is under 85%."
  fi


echo "+++ End of Script. +++"

