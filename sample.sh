#!/bin/bash

# Function to check if a package is installed
check_package() {
    PACKAGE_NAME=$1
    if dpkg -l | grep -q "^ii  $PACKAGE_NAME"; then
        echo "$PACKAGE_NAME is already installed."
        return 0
    else
        echo "$PACKAGE_NAME is not installed."
        return 1
    fi
}

# Function to install required software
install_software() {
    echo "Installing $1..."

    apt-get update
    apt-get install -y "$1"

    systemctl enable "$1"
    systemctl start "$1"

    echo "$1 installed and started."
}



# Check and install apache2 if necessary
if check_package "apache2"; then
    echo "apache2 is already installed, skipping installation."
else
    install_software "apache2"
fi

# Check and install squid if necessary
if check_package "squid"; then
    echo "squid is already installed, skipping installation."
else
    install_software "squid"
fi