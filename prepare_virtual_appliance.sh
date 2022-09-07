#!/usr/bin/env bash
systemctl stop puppet-razor

rm -rf /mnt/repo-store/*
rm -rf /mnt/postgresql_data/*
