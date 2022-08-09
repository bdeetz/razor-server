# SWCCDC Puppet Razor Deployment and Development
## BUILDING AND STARTING
NOTE: This service expects the razor server to be at 192.168.94.3.
      If the ip address of the razor server needs to be different, update bootstrap.ipxe,
      rebuild the container using the instruction below, and restart the puppet-razor
      systemd service.

```
# NOTE: You can skip this if you are working from the CCDC virtual appliance
git clone https://github.com/bdeetz/razor-server.git

cd razor-server

docker build . -t puppet-razor:latest

# NOTE: You can skip this if you are working from the CCDC virtual appliance
cat << EOF > /etc/systemd/system/puppet-razor.service
[Unit]
Description=Puppet Razor
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm -u root --privileged --network host --name puppet-razor puppet-razor:latest
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
TODO
