#!/bin/bash

set -e

function includeDependencies() {
    echo "Calling includeDependencies.."
    # shellcheck source=./setupLibrary.sh
    source "./setupLibrary.sh"
    source "./addonLibrary.sh"
}

includeDependencies

function main() {
    echo "Calling main.."

    # read -rp "Do you wish to update and upgrade the system? (y/n) " choice
    # case "${choice}" in
    #     y|Y) 
    #         sudo apt-get update && sudo apt-get upgrade -y
    #         ;;
    #     n|N) 
    #         echo "Update and upgrade skipped."
    #         ;;
    #     *) 
    #         echo "Invalid choice. Exiting."
    #         exit 1
    #         ;;
    # esac

    # # Run setup functions

    # read -rp "Enter the username of the new user account: " username
    # read -rsp "Enter the password for the new user account: " password
    # read -rp "Enter the email for SSL certificates: " traefik_email
    # read -rp "Enter the domain for Traefik basis domain (used for webgui): " traefik_domain
    # read -rp "Enter the username for the Traefik web GUI: " webgui_user
    # read -rsp "Enter the password for the Traefik web GUI: " webgui_pass


    # echo  # This is to move to the next line after the silent password prompt
    # addUserAccount "${username}" "${password}" "true"

    # read -rp $'Paste in the public SSH key for the new user:\n' sshKey
    # echo 'Running setup script...'

    # # disableSudoPassword "${username}"
    # addSSHKey "${username}" "${sshKey}"
    # changeSSHConfig
    # setupUfw

    # sudo service ssh restart
    
    # installFail2Ban
    # installDocker "${username}"
    installTraefik "${traefik_email}" "${traefik_domain}" "${webgui_user}" "${webgui_pass}"


    echo "Setup Done!"
}


main