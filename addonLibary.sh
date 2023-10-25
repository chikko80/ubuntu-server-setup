# Setup Fail2Ban
function installFail2Ban() {
    echo "Installing Fail2Ban.."
    # Install fail2ban
    sudo apt install fail2ban

    # Copy jail.local from the current directory to /etc/fail2ban/
    sudo cp ./jail.local /etc/fail2ban/jail.local

    # Start the fail2ban service
    sudo service fail2ban start
}


# Setup Fail2Ban
function installDocker() {
    local username=$1

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo usermod -aG docker "${username}"

}


function installTraefik() {
    # Download and extract Traefik
    sudo apt install apache2-utils

    wget https://github.com/traefik/traefik/releases/download/v2.10.4/traefik_v2.10.4_linux_amd64.tar.gz
    tar -zxvf traefik_v2.10.4_linux_amd64.tar.gz

    # Move Traefik binary and set up its state directory
    sudo mkdir -p /opt/traefik/bin
    sudo mkdir -p /opt/traefik/state
    sudo mv traefik /opt/traefik/bin
    sudo touch /opt/traefik/state/acme.json
    sudo chmod 600 /opt/traefik/state/acme.json

    # Prompt for email, domain, and web GUI authentication details
    read -rp "Enter the email for SSL certificates: " traefik_email
    read -rp "Enter the domain for Traefik basis domain (used for webgui): " traefik_domain
    read -rp "Enter the username for the Traefik web GUI: " webgui_user
    read -rsp "Enter the password for the Traefik web GUI: " webgui_pass
    echo  # This is to move to the next line after the silent password prompt

    # Generate the credentials using htpasswd and store in a variable
    credentials=$(htpasswd -nb "$webgui_user" "$webgui_pass")

    # Ensure the /etc/traefik directory exists
    sudo mkdir -p /etc/traefik

    # Copy configuration files and replace placeholders
    sed "s/email_placeholder/${traefik_email}/" traefik.toml | sudo tee /etc/traefik/traefik.toml > /dev/null
    sed -e "s/domain_placeholder/${traefik_domain}/" -e "s|credentials|${credentials}|" traefik_dynamic.toml | sudo tee /etc/traefik/traefik_dynamic.toml > /dev/null
}