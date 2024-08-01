#!/bin/bash

chmod +x configure-host.sh
oldHostname=$(hostname)
oldIP=$(ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
newHostname=""
newIP=""
verbose=false
verifyHostname=""
verifyIP=""

# Ignore TERM, HUP, and INT signals
trap '' TERM HUP INT

#Logging outputs
msg_Log() {
    logger "$1"
    if $verbose; then
        echo "$1"
    fi
}

#Logging errors
error_Log() {
    logger "$1"
    echo "$1" >&2
}

# Checking arguments
if [[ $# -eq 0 ]]; then
    error_Log "Error: No arguments provided."
    echo "Arguments: $0 [-verbose] -name [hostname] -ip [IP Address] -hostentry [hostname IP Address]"
    exit 1
fi

#Arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -verbose)
            verbose=true
            shift
            ;;
        -name)
            newHostname="$2"
            shift 2
            ;;
        -ip)
            newIP="$2"
            shift 2
            ;;
        -hostentry)
            verifyHostname="$2"
            verifyIP="$3"
            shift 3
            ;;
        *)
            error_Log "Unknown argument: $1"
            echo "Usage: $0 [-verbose] -name [hostname] -ip [IP Address] -hostentry [hostname IP Address]"
            exit 1
            ;;
    esac
done

# Change hostname
if [ -n "$newHostname" ]; then
    msg_Log "Updating hostname to $newHostname"
    hostnamectl set-hostname "$newHostname"
    sudo sed -i "s/$oldHostname/$newHostname/" /etc/hosts
    newset_Hostname=$(hostname)

    if [ "$newset_Hostname" == "$newHostname" ]; then
        msg_Log "Hostname successfully updated to: $newHostname"
    else
        error_Log "Failed to update hostname"
    fi
fi

# Change IP address
if [ -n "$newIP" ]; then
    msg_Log "Updating IP address to $newIP"
    sudo sed -i "s/$oldIP/$newIP/" /etc/hosts
    sudo sed -i "s/$oldIP/$newIP/" /etc/netplan/*.yaml
    sudo netplan apply

    msg_Log "IP address successfully updated to: $newIP"
fi

# Modify host entry
if [ -n "$verifyHostname" ] && [ -n "$verifyIP" ]; then
    msg_Log "Checking and updating host entry for $verifyHostname with IP $verifyIP"
    
    currentIP=$(grep -w "$verifyHostname" /etc/hosts | awk '{print $1}')
    currentHostname=$(grep -w "$verifyIP" /etc/hosts | awk '{print $2}')

    if [ "$verifyHostname" == "$currentHostname" ] && [ "$verifyIP" == "$currentIP" ]; then
        msg_Log "Hostname $verifyHostname with IP $verifyIP is already updated in the system."
    else
        msg_Log "Updating hostname and IP in the system to $verifyHostname and $verifyIP"
        
        # Update hostname
        hostnamectl set-hostname "$verifyHostname"
        sudo sed -i "s/$oldHostname/$verifyHostname/" /etc/hosts

        # Update IP address in /etc/hosts
        if grep -q "$oldIP" /etc/hosts; then
            sudo sed -i "s/$oldIP/$verifyIP/" /etc/hosts
        else
            echo "$verifyIP $verifyHostname" | sudo tee -a /etc/hosts
        fi
        
        # Update IP address in netplan
        sudo sed -i "s/$oldIP/$verifyIP/" /etc/netplan/*.yaml
        sudo netplan apply

        msg_Log "Updated to hostname: $verifyHostname, IP: $verifyIP"
    fi
fi

# Check if both -name and -ip are used together
if [ -n "$newHostname" ] && [ -n "$newIP" ]; then
    msg_Log "The -name and -ip paramters are used."
fi 

# Check if all parameters are used together
if [ -n "$newHostname" ] && [ -n "$newIP" ] && [ -n "$verifyHostname" ] && [ -n "$verifyIP" ]; then
    msg_Log "All parameters used together: -name, -ip, and -hostentry"
fi
