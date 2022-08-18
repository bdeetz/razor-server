# SWCCDC Puppet Razor Deployment and Development
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


docker build . -t puppet-razor:latest

# only necessary on the first container start
# this is not necessary after rebuilds
docker run -d --restart unless-stopped -u root -v '/mnt/postgresql_data:/var/lib/postgresql/data' -v '/mnt/repo-store:/var/lib/razor/repo-store' --privileged --network host --name puppet-razor puppet-razor:latest

docker stop puppet-razor
docker start puppet-razor
```

## Installation from a container repository
TODO

## Configuring the bootstrap
TODO
