#!/usr/bin/bash

#===== 6. SHORT PROCESS INFO (sorted by memory usage, command arguments stripped)
#$(ps -ewo pid,user,priority,vsize,pcpu,rss,cmd --sort=-rss | \
#    awk '{print $1 "\t" $2 "\t\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7}')

ssh_log=$(journalctl -o short --since yesterday -u sshd)

cat << EOF
System report for $(hostname) on $(date "+%d %B %Y at %r")

===== CONTENTS:
1. UPTIME AND LOAD
2. BATTERY
3. MEMORY USAGE
4. DISK USAGE
5. SENSORS
6. SSH CONNECTIONS ACCEPTED
7. SSH CONNECTIONS REJECTED

===== 1. UPTIME AND LOAD
$(uptime)

===== 2. BATTERY
$(acpi)

===== 3. MEMORY USAGE
$(free | sed -n 2p | awk '{print "used:\t" ($3+$5)/$2*100 "% \navailable: " $7/$2*100 "%"}')

$(free --mega)

===== 4. DISK USAGE (mountpoints stripped)
$(df -h --output=source,size,used,avail,pcent)

===== 5. SENSORS
$(sensors)

===== 6. SSH CONNECTIONS ACCEPTED (since yesterday)
$(grep Accepted <<< "$ssh_log")

===== 7. SSH CONNECTIONS REJECTED (since yesterday)
$(grep -E "preauth|Invalid|Did not receive" <<< "$ssh_log")

EOF
