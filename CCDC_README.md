# SWCCDC Puppet Razor Deployment and Development
## How does razor work?
Razor is a baremetal provisioning system that allows you to provision hosts based on defined policies. There are 4 primary components of razor you will likely need to worry about within the context of a CCDC game.

components:
* repos
  * This is the install media you're booting to
* tags
  * metadata driven tags assigned to nodes
  * there can be more than 1 tag associated with a node
  * logic for a tag could be based on number of cores, serial number, mac addresses, amount of ram, etc.
* policies
  * policies tie everything together
  * a policy will say something like "install ubuntu using this repo when the following tags are assigned to the node"

## BUILDING AND STARTING
NOTE: This service expects the razor server to be at 192.168.94.3.
      If the ip address of the razor server needs to be different, update bootstrap.ipxe,
      rebuild the container using the instruction below, and restart the puppet-razor
      systemd service.

NOTE: If you are using the CCDC virtual appliance, the appliance expects the first network interface to be a management network with DHCP. The second network interface is used for provisioning and expects to have a static IP configured. As shipped it is 192.168.94.3/24. If you need something else, update netplan and the bootstrap.ipxe and the boostrap.ipxe file mentioned above. These changes will require a rebuild of the container on the appliance using the process described below.

```
################################################
# BEGIN DOCKER INSTALL (Ubuntu 20.04)
################################################
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
################################################
# END DOCKER INSTALL (Ubuntu 20.04)
################################################

sudo -s

# NOTE: You can skip this if you are working from the CCDC virtual appliance
git clone https://github.com/bdeetz/razor-server.git

cd razor-server

# create directories for docker volumes
mkdir /mnt/postgresql_data
mkdir /mnt/repo-store
chown -R 70 /mnt/repo-store

docker build . -t puppet-razor:latest

# NOTE: You can skip this if you are working from the CCDC virtual appliance
cat << EOF > /etc/systemd/system/puppet-razor.service
[Unit]
Description=Puppet Razor
After=docker.service
Requires=docker.service
[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm -u root -v '/mnt/postgresql_data:/var/lib/postgresql/data' -v '/mnt/repo-store:/var/lib/razor/repo-store' --privileged --network host --name puppet-razor puppet-razor:latest
ExecStop=/usr/bin/docker stop puppet-razor
TimeoutStopSec=120
[Install]
WantedBy=default.target
EOF

# NOTE: Only necessary if you're on the virtual appliance
systemctl stop puppet-razor.service

# NOTE: You can skip this if you are working from the CCDC virtual appliance
systemctl daemon-reload

# NOTE: You can skip this if you are working from the CCDC virtual appliance
systemctl enable puppet-razor.service

# this will start the container
systemctl start puppet-razor.service

# redirects the razor cli command from the container host into the container
echo 'alias razor="docker exec -it -u postgres puppet-razor razor $@"' >> ~/.profile
source ~/.profile
```

## Installation from a container repository
TODO

## Configuring the bootstrap
Bootstrap of the CCDC provisioning configuration is defined in `ccdc_bootstrap.sh`. When the container starts for the first time, it will copy the bootstrap script to your container's `repo-store` volume mount point on the container host. That path is defined as `/mnt/repo-store/` in this document.

The `ccdc_bootstrap.sh` script is executed after the razor service is fully up every time the container is restarted. As a result, updating `/mnt/repo-store/ccdc_bootstrap.sh` then executing `systemctl restart puppet-razor` on the container host will result in newly defined configuration objects being created.

## DHCP SERVER CONFIGURATION
### isc-dhcp-server
```
default-lease-time 600;
max-lease-time 7200;
ddns-update-style none;
authoritative;

subnet 192.168.94.0 netmask 255.255.255.0 {
  range 192.168.94.100 192.168.94.200;
  option subnet-mask 255.255.255.0;

  option domain-name-servers 192.168.1.1;

  if exists user-class and option user-class = "iPXE" {
    filename "bootstrap.ipxe";
  } else {
    filename "undionly.kpxe";
  }
  next-server 192.168.94.3;
}
```

## ADDING A NEW MATCHING TAG

