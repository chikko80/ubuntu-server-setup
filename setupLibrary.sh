#!/bin/bash

# Update the user account
# Arguments:
#   Account Username
function updateUserAccount() {
    echo "Calling updateUserAccount.."
    local username=${1}
    
    sudo passwd -d "${username}"
    sudo usermod -aG sudo "${username}"
}

# Add the new user account
# Arguments:
#   Account Username
#   Flag to determine if user account is added silently. (With / Without GECOS prompt)
function addUserAccount() {
    echo "Calling addUserAccount.."
    local username=${1}
    local password=${2}
    local silent_mode=${3}

    # Check for silent mode; if provided, avoid extra prompts during user creation
    if [[ ${silent_mode} == "true" ]]; then
        sudo adduser --disabled-password --gecos '' "${username}"
    else
        sudo adduser --disabled-password "${username}"
    fi

    # Change the password for the user to the one provided
    echo "${username}:${password}" | sudo chpasswd

    # Add the user to the 'sudo' group
    sudo usermod -aG sudo "${username}"

    # If you still want the option to clear the password, you can leave this line.
    # However, since you're setting a password for the user, it might not be needed.
    # sudo passwd -d "${username}"
}

# Add the local machine public SSH Key for the new user account
# Arguments:
#   Account Username
#   Public SSH Key
function addSSHKey() {
    echo "Calling addSSHKey.."
    local username=${1}
    local sshKey=${2}

    execAsUser "${username}" "mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys"
    execAsUser "${username}" "echo \"${sshKey}\" | sudo tee -a ~/.ssh/authorized_keys"
    execAsUser "${username}" "chmod 600 ~/.ssh/authorized_keys"
}

# Execute a command as a certain user
# Arguments:
#   Account Username
#   Command to be executed
function execAsUser() {
    echo "Calling execAsUser.."
    local username=${1}
    local exec_command=${2}

    sudo -u "${username}" -H bash -c "${exec_command}"
}

# Modify the sshd_config file
# shellcheck disable=2116
function changeSSHConfig() {
    echo "Calling changeSSHConfig.."
    sudo sed -re 's/^(\#?)(PasswordAuthentication)([[:space:]]+)yes/\2\3no/' -i."$(echo 'old')" /etc/ssh/sshd_config
    sudo sed -re 's/^(\#?)(PermitRootLogin)([[:space:]]+)(.*)/PermitRootLogin no/' -i /etc/ssh/sshd_config
}

# Setup the Uncomplicated Firewall
function setupUfw() {
    echo "Calling setupUfw.."
    sudo apt-get install ufw
    sudo ufw default deny incoming
    sudo ufw allow OpenSSH
    sudo ufw allow 80
    sudo ufw allow 443
    yes y | sudo ufw enable

}
