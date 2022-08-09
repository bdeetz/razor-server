# SWCCDC Puppet Razor Deployment and Development
## Installation from a fresh build
NOTE: This process expects the razor server to be at 192.168.94.3.
      If the ip address of the razor server is changed, update bootstrap.ipxe,
      rebuild the container, and restart the puppet-razor systemd service.

```
git clone https://github.com/bdeetz/razor-server.git

cd razor-server

docker build . -t puppet-razor:latest

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

systemctl daemon-reload

# the host will start the container at boot now
systemctl enable puppet-razor.service

# this will start the container
systemctl start puppet-razor.service
```

## Installation from a container repository
TODO

## Configuring the bootstrap
modify the `_main` function of `bin/run-local` within this repository
