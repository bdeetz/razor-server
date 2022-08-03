# installation
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
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker exec %n stop
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run -it -u root --privileged --network host puppet-razor:latest

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload

systemctl enable puppet-razor.service

systemctl start puppet-razor.service
```
