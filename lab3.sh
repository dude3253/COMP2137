#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

verbose=""
if [[ $1 == "-verbose" ]]; then
    verbose="-verbose"
fi

# Function to check the result of a command and exit if it failed
check_result() {
    if [[ $1 -ne 0 ]]; then
        echo "Error: $2 failed."
        exit 1
    fi
}

# Function to run configure-host.sh and check its result
run_configure_host() {
    local server=$1
    local args=$2
    ssh remoteadmin@$server -- /root/configure-host.sh $verbose $args
    check_result $? "Running configure-host.sh on $server"
}

# Copy the configure-host.sh script to the remote servers
scp configure-host.sh remoteadmin@server1-mgmt:/root
check_result $? "SCP to server1-mgmt"
scp configure-host.sh remoteadmin@server2-mgmt:/root
check_result $? "SCP to server2-mgmt"

# Run the configure-host.sh script on the remote servers
run_configure_host "server1-mgmt" "-name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4"
run_configure_host "server2-mgmt" "-name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3"

# Run the configure-host.sh script locally
./configure-host.sh $verbose -hostentry loghost 192.168.16.3
check_result $? "Running configure-host.sh locally for loghost"
./configure-host.sh $verbose -hostentry webhost 192.168.16.4
check_result $? "Running configure-host.sh locally for webhost"

echo "All operations completed successfully."
