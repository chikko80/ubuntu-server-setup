# Setup Fail2Ban
function installFail2Ban() {
    echo "Calling installFail2Ban.."
    echo "Installing Fail2Ban.."
    # Install fail2ban
    sudo apt install fail2ban -y

    # Copy jail.local from the current directory to /etc/fail2ban/
    sudo cp ./jail.local /etc/fail2ban/jail.local

    # Start the fail2ban service
    sudo systemctl enable fail2ban
    sudo service fail2ban start
}


# Setup Fail2Ban
function installDocker() {
    echo "Calling installDocker.."
    local username=$1

    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

    sudo usermod -aG docker "${username}"

    sudo apt install docker-compose -y

}


function installTraefik() {
    echo "Calling installTraefik.."
    local traefik_email=$1
    local traefik_domain=$2
    local webgui_user=$3
    local webgui_pass=$4

    # Download and extract Traefik
    sudo apt install apache2-utils -y

    wget https://github.com/traefik/traefik/releases/download/v2.10.4/traefik_v2.10.4_linux_amd64.tar.gz
    tar -zxvf traefik_v2.10.4_linux_amd64.tar.gz

    # Move Traefik binary and set up its state directory
    sudo mkdir -p /opt/traefik/bin
    sudo mkdir -p /opt/traefik/state
    sudo mv traefik /opt/traefik/bin
    sudo touch /opt/traefik/state/acme.json
    sudo chmod 600 /opt/traefik/state/acme.json

    # Prompt for email, domain, and web GUI authentication details
    echo  # This is to move to the next line after the silent password prompt

    # Generate the credentials using htpasswd and store in a variable
    credentials=$(htpasswd -nb "$webgui_user" "$webgui_pass")

    # Ensure the /etc/traefik directory exists
    sudo mkdir -p /etc/traefik

    # Copy configuration files and replace placeholders
    sed "s/email_placeholder/${traefik_email}/" traefik.toml | sudo tee /etc/traefik/traefik.toml > /dev/null
    sed -e "s/domain_placeholder/${traefik_domain}/" -e "s|credentials|${credentials}|" traefik_dynamic.toml | sudo tee /etc/traefik/traefik_dynamic.toml > /dev/null

    sudo cp ./traefik.service /etc/systemd/system/traefik.service
    
    sudo systemctl enable traefik
    sudo service traefik start

}


function installNodeExporter() {
    read -rp "Install node exporter for prometheus on bare metal? (y/n) " choice
    case "${choice}" in
        y|Y) 
            echo "Calling installNodeExporter.."
            wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
            tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz

            sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
            sudo useradd -rs /bin/false node_exporter
            
            sudo cp ./node_exporter.service /etc/systemd/system/node_exporter.service

            sudo systemctl daemon-reload
            sudo systemctl start node_exporter
            sudo systemctl enable node_exporter
            ;;
        n|N) 
            echo "Skipping node exporter install."
            ;;
        *) 
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}




function installK3() {
    read -rp "Install k3 cluster? (y/n) " choice
    case "${choice}" in
        y|Y) 
            echo "Calling installK3.."
            curl -sfL https://get.k3s.io | sh -
            sudo chown $USER /etc/rancher/k3s/k3s.yaml
            echo "Disabling public cluster export.."
            kubectl -n kube-system patch svc traefik --type=merge -p '{"spec": {"type": "ClusterIP"}}'
            ;;
        n|N) 
            echo "Skipping node exporter install."
            ;;
        *) 
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
}