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
```

## Installation from a container repository
TODO

## Configuring the bootstrap
Bootstrap of the CCDC provisioning configuration is defined in `ccdc_bootstrap.sh`. When the container starts for the first time, it will copy the bootstrap script to your container's `repo-store` volume mount point on the container host. That path is defined as `/mnt/repo-store/` in this document.

The `ccdc_bootstrap.sh` script is executed after the razor service is fully up every time the container is restarted. As a result, updating `/mnt/repo-store/ccdc_bootstrap.sh` then executing `systemctl restart puppet-razor` on the container host will result in newly defined configuration objects being created.
