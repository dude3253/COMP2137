#!/bin/bash

userName=$USER
today=$(date +%y-%m-%d/%l:%M:%S)
comp_hostname=$(hostname)
userUptime=$(uptime | awk '{print $1}')
cpuInfo=$(lscpu | awk '/Model name: / {print $3, $4, $5, $6, $7, $8, $9}')
cpuSpeed=$(cat /proc/cpuinfo | grep -i 'cpu mhz' | head -n 1 | awk '{print $4}')
cpuSpeed2=$(cat /proc/cpuinfo | grep -i 'cpu mhz' | head -n 1 | awk '{print $2}')
ramSize=$(free -h | grep -i "mem:" | awk '{print $2}')
osSource=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2)
disks1=$(lsblk -dno model | tail -n 2 | awk '{print $1, $2, $3}' | sed -n '1p')
diskSize1=$(lsblk -dno size | tail -n 3 | awk '{print $1}' | sed -n '1p')
disks2=$(lsblk -dno model | tail -n 2 | awk '{print $1, $2, $3}' | sed -n '2p')
diskSize2=$(lsblk -dno size | tail -n 2 | awk '{print $1}'| sed -n '1p')
vidCardMake=$(lshw -class display | grep -i 'vendor:' | cut -d':' -f2)
vidCard=$(lshw -class display | grep -i 'product:' | cut -d':' -f2)
ipAddress=$(ip addr show | awk '/inet /{print $2}' | sed -n '2p')
fqdn=$(nmcli | awk '/domains: / {print $2}' | sed -n '2p')
hostAddress=$(ip addr show | awk '/inet /{print $2}' | cut -d'/' -f1 | sed -n '2p')
gatewayIP=$(ip route | awk '/default /{print $3}')
interface1=$(nmcli | awk '/interface: /{print $2}' | sed -n '1p')
interface2=$(nmcli | awk '/interface: /{print $2}' | sed -n '2p')
dnsServer=$(nmcli | awk '/servers: /{print $2}'| sed -n '1p')
usersLoggedIn1=$(getent passwd | tail -n 2 | cut -d':' -f1 | sed -n '1p')
usersLoggedIn2=$(getent passwd | tail -n 2 | cut -d':' -f1 | sed -n '2p')
processCount=$(ps -A | wc -l)
memoryAllocation=$(free -h)
ufwRules=$(sudo ufw status)
diskSpace=$(df -hP | awk '/dev/ ')
listenPort=$(ss -tnlp | awk '/LISTEN /{print $1, $2, $3}')
loadAverage=$(uptime | awk '{print $9, $10, $11}')

cat <<EOF

System Report generated by $userName, $today
 
 
System Information
------------------
HOSTNAME: $comp_hostname
OS: $osSource
Uptime: $userUptime

Hardware Information 
--------------------
CPU: $cpuInfo
Speed: $cpuSpeed$cpuSpeed2
RAM: $ramSize
Disks: $disks1 - $diskSize1, $disks2 - $diskSize2
Videocard: $vidCardMake$vidCard

Network Information
-------------------
FQDN: $comp_hostname.$fqdn
Host Address: $hostAddress
Gateway IP: $gatewayIP
DNS Server: $dnsServer
Interface Name: $interface1, $interface2
IP Address: $ipAddress   

System Status
-------------
Users Logged In: $usersLoggedIn1, $usersLoggedIn2
Disk Space: $diskSpace
Process Count: $processCount
Load Averages: $loadAverage
Memory Allocation: $memoryAllocation
Listening Network Ports: $listenPort
UFW Rules: $ufwRules

EOF
