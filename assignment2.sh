#!/bin/bash

newIP='192.168.16.21'
oldIP=$(cat /etc/hosts | awk '/server1/ {print $1}' | sed -n '2p')
netplanIP=$(grep -Po '(?<=addresses: \[).*(?=\])' /etc/netplan/10-lxc.yaml | head -n 1)
fnetplanIP="192.168.16.21/24"
#Change the IP Address of Server1 from /etc/hosts
changeIP() {
    if [ -z $oldIP ]; then
        echo "The IP Address : $oldIP not found in /etc/hosts"
    elif [[ $newIP == $oldIP ]]; then
        echo "The /etc/hosts is already modified to the appropriate IP Address."
        return 0
    else
        sed -i "s/$oldIP/$newIP/" /etc/hosts
        echo "The IP Address in /etc/hosts has been changed."
        sudo netplan apply
        return 0
    fi
}
#Change the IP Address of yaml file in /etc/netplan
change_netplan() {
    if [[ $netplanIP != $fnetplanIP ]]; then
        sed -i 's/${netplanIP}/${fnetplanIP}/g' /etc/netplan/10-lxc.yaml
        sudo netplan apply
        echo "The IP Address in the yaml file is updated."
    else
        echo "The IP Address in the yaml file is already updated."
    fi
}


install_apache() {
    
    if ! systemctl status apache2 &> /dev/null; then
        echo "Installing apache2"
        sudo apt-get update -qy &> /dev/null
        sudo apt-get install apache2 -y &> /dev/null
        systemctl enable apache2 &> /dev/null 
        systemctl start apache2 &> /dev/null
    else
        echo "Apache2 is already installed."
    fi
}

install_squid() {
    if ! systemctl status squid &> /dev/null; then
        sudo echo "Installing squid."
        sudo apt-get install squid -y &> /dev/null
        systemctl enable squid &> /dev/null
        systemctl start squid &> /dev/null
    else
        echo "Squid is already installed."
    fi
}

firewall_config() {
    if ! command -v ufw &> /dev/null; then
        echo "Installing UFW..."
        apt-get install ufw -y &> /dev/null
        ufw --force enable
        echo "ufw enabled."
        if [ $? -ne 0 ]; then
            echo "Error installing UFW"
            return 1
        fi
    else
        echo "UFW already installed in the system."
    fi

    echo "Setting up UFW policies"
    ufw default deny incoming &> /dev/null
    ufw default allow outgoing &> /dev/null
    if [ $? -ne 0 ]; then
        echo "Error in setting up UFW policies"
        return 1
    else
        echo "Successfully set-up UFW policies"
    fi
    
    echo "Configuring traffic"
    ufw allow in on eth1 to any port 22 &> /dev/null
    ufw allow in on any to any port 80 &> /dev/null
    ufw allow in on any to any port 3128 &> /dev/null
        if [ $? -ne 0 ]; then
            echo "Failed to configure UFW rules."
            return 1
        fi
    
    sudo ufw reload &> /dev/null
    if [ $? -ne 0 ]; then
        
        return 1
    else 
        echo "UFW Reloaded"
    fi
    echo "UFW successfully configured."
                
        


}

user_accounts() {
    echo "Adding user accounts"
    userAccounts=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in ${userAccounts[@]} 
    do
        if id "$user" &> /dev/null; then
            echo "$user already exists."
            continue
        fi
        if ! sudo mkdir -p "/home/$user/.ssh" 2>/dev/null; then
            echo "Error creating directory /home/$user/.ssh for user $user"
        else
            sudo useradd -m -d /home/$user -s /bin/bash $user
            sudo mkdir -p /home/$user/.ssh
            echo "Creating directory for user $user"
        fi
        if ! sudo chown -R "$user:$user" "/home/$user/.ssh" 2>/dev/null; then
            echo "Error setting ownership for /home/$user/.ssh for user $user"
        else
            sudo chown -R $user:$user /home/$user/.ssh
        fi
        
        sudo -u $user ssh-keygen -t rsa -q -N "" -f /home/$user/.ssh/id_rsa
        sudo -u $user ssh-keygen -t ed25519 -q -N "" -f /home/$user/.ssh/id_ed25519

  # Append public keys to authorized_keys
        sudo -u $user cat /home/$user/.ssh/id_rsa.pub /home/$user/.ssh/id_ed25519.pub >> /home/$user/.ssh/authorized_keys

  # Set permissions for authorized_keys
        sudo chmod 600 /home/$user/.ssh/authorized_keys

  # Add user to sudo group if it's dennis
        if [ "$user" = "dennis" ]; then
            sudo usermod -aG sudo $user
        fi

  # Add additional SSH key for dennis
        if [ "$user" = "dennis" ]; then
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/$user/.ssh/authorized_keys
        fi
    done
}


changeIP
change_netplan
install_apache
install_squid
firewall_config
user_accounts
