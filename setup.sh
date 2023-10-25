#!/bin/bash

set -e

function getCurrentDir() {
    echo "Calling getCurrentDir.."
    local current_dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${current_dir}" ]]; then current_dir="$PWD"; fi
    echo "${current_dir}"
}

function includeDependencies() {
    echo "Calling includeDependencies.."
    # shellcheck source=./setupLibrary.sh
    source "${current_dir}/setupLibrary.sh"
}

current_dir=$(getCurrentDir)
includeDependencies
output_file="output.log"

function main() {
    echo "Calling main.."

    sudo apt-get update && sudo apt-get upgrade -y

    # Run setup functions
    trap cleanup EXIT SIGHUP SIGINT SIGTERM

    read -rp "Enter the username of the new user account: " username
    read -rsp "Enter the password for the new user account: " password
    echo  # This is to move to the next line after the silent password prompt
    addUserAccount "${username}" "${password}" "true"

    read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    echo 'Running setup script...'

    # disableSudoPassword "${username}"
    addSSHKey "${username}" "${sshKey}"
    changeSSHConfig
    setupUfw

    sudo service ssh restart
    
    installFail2Ban
    installDocker "${username}"
    installTraefik


    echo "Setup Done! Log file is located at ${output_file}" >&3
}
