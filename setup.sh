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

    if !hasSwap; then
        setupSwap
    fi

    # echo "Configuring System Time... " >&3
    # setupTimezone
    # configureNTP

    sudo service ssh restart
    
    installFail2Ban
    installDocker "${username}"
    installTraefik

    cleanup

    echo "Setup Done! Log file is located at ${output_file}" >&3
}

function setupSwap() {
    echo "Calling setupSwap.."
    createSwap
    mountSwap
    tweakSwapSettings "10" "50"
    saveSwapSettings "10" "50"
}

function hasSwap() {
    echo "Calling hasSwap.."
    [[ "$(sudo swapon -s)" == *"/swapfile"* ]]
}

function cleanup() {
    echo "Calling cleanup.."
    if [[ -f "/etc/sudoers.bak" ]]; then
        revertSudoers
    fi
}

function logTimestamp() {
    echo "Calling logTimestamp.."
    local filename=${1}
    {
        echo "===================" 
        echo "Log generated on $(date)"
        echo "==================="
    } >>"${filename}" 2>&1
}

function setupTimezone() {
    echo "Calling setupTimezone.."
    echo -ne "Enter the timezone for the server (Default is 'Asia/Singapore'):\n" >&3
    read -r timezone
    if [ -z "${timezone}" ]; then
        timezone="Asia/Singapore"
    fi
    setTimezone "${timezone}"
    echo "Timezone is set to $(cat /etc/timezone)" >&3
}

main
