#!/bin/bash
#Author: Harimustdie
# ------
#
# PURPOSE:
# -----------
# This script will monitor the Server CPU, Memory, Swap, and Zombie Process every 5/10/15 mins (depending on schedule in cron).

export email_add=xyz@xyz.com
export filelocation="/tmp"                                                                     
export MESSAGE="$filelocation/mail.txt"                                                        
export ZMESSAGE="$filelocation/zmail.txt"                                                              
export Zlistfile="$filelocation/Zlistfile.log"                         
export memoryfile="$filelocation/memory_$(date "+%Y%m%d%H%M%S").csv"   
export memoryfileday="$filelocation/memory_$(date "+%Y%m%d").csv"      
export cpufile="$filelocation/cpu_$(date "+%Y%m%d%H%M%S").csv"         
export cpufileday="$filelocation/cpu_$(date "+%Y%m%d").csv"            
export zombiefile="$filelocation/zombie_$(date "+%Y%m%d%H%M%S").csv"   
export zombiefileday="$filelocation/zombie_$(date "+%Y%m%d").csv" 

# Step0: Check the present date and time.
echo Current Date and Time is: `date +"%Y-%m-%d %T"`
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
#echo "Memory Current Usage is: $r_value"

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
  echo "SysAdmin Team " >> $MESSAGE
  
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE -a "$cpufile"
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" -a "$cpufile" "$email_add" < $MESSAGE
  #mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add"  < $MESSAGE  
  (
	echo "From: xyz@xyz.com"
	echo "To: $email_add"
	echo "Subject: $SUBJECT"
	echo "MIME-Version: 1.0"
	echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
	echo
	echo '---q1w2e3r4t5'
	echo "Content-Type: text/html"
	echo "Content-Disposition: inline"
	echo -e "MIME-Version: 1.0\nContent-Type: text/plain\n\n" && cat $MESSAGE
	echo '---q1w2e3r4t5'
	echo 'Content-Type: application; name="'$(basename $cpufile)'"'
	echo "Content-Transfer-Encoding: base64"
	echo 'Content-Disposition: attachment; filename="'$(basename $cpufile)'"'
	uuencode --base64 $cpufile $(basename $cpufile)
	echo '---q1w2e3r4t5--'
	echo
	) | /usr/sbin/sendmail -t
  
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
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -20)" >> $memoryfile
  echo Current Date and Time is: `date +"%Y-%m-%d %T"` >> $memoryfileday
  echo "$(ps -eo pid,ppid,user,%mem,%cpu,args --sort=-%mem | head -20)" >> $memoryfileday
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Kindly check the attached file for top 20 processes consuming high Memory" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "" >> $MESSAGE
  echo "Thank you " >> $MESSAGE
  echo "SysAdmin Team " >> $MESSAGE
  
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE -a "$memoryfile"
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" -a "$memoryfile" "$email_add" < $MESSAGE
   #mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE
   (
	echo "From: xyz@xyz.com"
	echo "To: $email_add"
	echo "Subject: $SUBJECT"
	echo "MIME-Version: 1.0"
	echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
	echo
	echo '---q1w2e3r4t5'
	echo "Content-Type: text/html"
	echo "Content-Disposition: inline"
	echo -e "MIME-Version: 1.0\nContent-Type: text/plain\n\n" && cat $MESSAGE
	echo '---q1w2e3r4t5'
	echo 'Content-Type: application; name="'$(basename $memoryfile)'"'
	echo "Content-Transfer-Encoding: base64"
	echo 'Content-Disposition: attachment; filename="'$(basename $memoryfile)'"'
	uuencode --base64 $memoryfile $(basename $memoryfile)
	echo '---q1w2e3r4t5--'
	echo
	) | /usr/sbin/sendmail -t
   
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
  echo "SysAdmin Team " >> $MESSAGE
  
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE -a "$memoryfile" "$cpufile"
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" -a "$memoryfile" "$cpufile" "$email_add" < $MESSAGE
  #mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE
  (
	echo "From: xyz@xyz.com"
	echo "To: $email_add"
	echo "Subject: $SUBJECT"
	echo "MIME-Version: 1.0"
	echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
	echo
	echo '---q1w2e3r4t5'
	echo "Content-Type: text/html"
	echo "Content-Disposition: inline"
	echo -e "MIME-Version: 1.0\nContent-Type: text/plain\n\n" && cat $MESSAGE
	echo '---q1w2e3r4t5'
	echo 'Content-Type: application; name="'$(basename $memoryfile)'"'
	echo "Content-Transfer-Encoding: base64"
	echo 'Content-Disposition: attachment; filename="'$(basename $memoryfile)'"'
	uuencode --base64 $memoryfile $(basename $memoryfile);
	echo '---q1w2e3r4t5--'
	#echo 'Content-Type: application; name="'$(basename $cpufile)'"'
	#echo "Content-Transfer-Encoding: base64"
	#echo 'Content-Disposition: attachment; filename="'$(basename $cpufile)'"'
	#uuencode --base64 $cpufile $(basename $cpufile);
	echo '---q1w2e3r4t5--'
	
	echo
	) | /usr/sbin/sendmail -t
  rm /tmp/mail.txt
  rm -rf $memoryfile 
  echo "Server Swap utilization has exceeded the threshold"
else
  echo "Server Swap utilization is under the threshold."
fi
  
if [ "$z_value" -ge 1 ] 
then
  SUBJECT="ATTENTION: Found Zombie procress on $(hostname) at $(date)"
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
  echo "SysAdmin Team " >> $MESSAGE
  
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE -a "$zombiefile"
  ##mailx -r nxyz@xyz.com -s "$SUBJECT" -a "$zombiefile" "$email_add" < $MESSAGE
  #mailx -r nxyz@xyz.com -s "$SUBJECT" "$email_add" < $MESSAGE
   (
	echo "From: xyz@xyz.com"
	echo "To: $email_add"
	echo "Subject: $SUBJECT"
	echo "MIME-Version: 1.0"
	echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
	echo
	echo '---q1w2e3r4t5'
	echo "Content-Type: text/html"
	echo "Content-Disposition: inline"
	echo -e "MIME-Version: 1.0\nContent-Type: text/plain\n\n" && cat $MESSAGE
	echo
	) | /usr/sbin/sendmail -t
  rm /tmp/mail.txt
  rm -rf $zombiefile 

  
  # zombie_array= $z_value
  #echo "Zombie Array: $zombie_array"
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
				  echo "SysAdmin Team " >> $ZMESSAGE
				  
				  #mailx -r nxyz@xyz.com -s "$ZSUBJECT" "$email_add" < $ZMESSAGE
				  (
					echo "From: xyz@xyz.com"
					echo "To: $email_add"
					echo "Subject: $ZSUBJECT"
					echo "MIME-Version: 1.0"
					echo 'Content-Type: multipart/mixed; boundary="-q1w2e3r4t5"'
					echo
					echo '---q1w2e3r4t5'
					echo "Content-Type: text/html"
					echo "Content-Disposition: inline"
					echo -e "MIME-Version: 1.0\nContent-Type: text/plain\n\n" && cat $ZMESSAGE
					echo
					) | /usr/sbin/sendmail -t
				  rm -rf $ZMESSAGE				
				  
				
				
				
			fi

	echo "+++++++++++++++++++++++++++++"
  done < "$Zlistfile"
  
else
	echo "Server Zombie Process is under the threshold."
fi

echo "+++ End of Script. +++"
