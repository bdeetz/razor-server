#!/usr/bin/env bash

set -Eeo pipefail
set -x

declare -A iso_urls

# k/v of filenames and download urls for isos
iso_urls=(["ubuntu-16.04.1-server-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/NdvfibI06WdvTbi/download" )

cd /var/lib/razor/repo-store

echo "Bootstrapping isos"

# for each k/v pair
for filename in "${!iso_urls[@]}"
do
    # if the file doesn't already exist
    if [[ ! -f ${filename} ]]
    then
        # download the file
        curl -k -o ${filename} ${iso_urls[${filename}]}
    fi
done

