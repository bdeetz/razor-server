#!/usr/bin/env bash
docker exec -it -u postgres puppet-razor /var/lib/razor/repo-store/ccdc_bootstrap.sh --cleanup

systemctl stop puppet-razor

rm -rf /mnt/repo-store/*
rm -rf /mnt/postgresql_data/*
