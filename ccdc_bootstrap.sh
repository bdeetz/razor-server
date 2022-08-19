#!/usr/bin/env bash
cd /var/lib/razor/repo-store

echo "Bootstrapping isos"

curl -k -o ubuntu-16.04.1-server-amd64.iso https://owncloud.tech-hell.com:8444/index.php/s/NdvfibI06WdvTbi/download
