#!/usr/bin/env bash

set -Eeo pipefail
set -x

test_hosts_filter='["in", ["fact", "macaddress"], "00:0c:29:f8:23:bf", "00:0c:29:f8:23:c0"]'

declare -A iso_urls
declare -A iso_tasks

# k/v of filenames and download urls for isos
iso_urls=(
["ubuntu-16.04.1-desktop-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/q35kklGQHh8UnuX/download"
["ubuntu-16.04.1-server-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/NdvfibI06WdvTbi/download"
["ubuntu-18.04-desktop-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/FYhSU6icibEEFr2/download"
["ubuntu-18.04-live-server-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/5OehYpFeJ1xMl32/download"
)

iso_tasks=(
["ubuntu-16.04.1-desktop-amd64.iso"]="ubuntu"
["ubuntu-16.04.1-server-amd64.iso"]="ubuntu"
["ubuntu-18.04-desktop-amd64.iso"]="ubuntu"
["ubuntu-18.04-live-server-amd64.iso"]="ubuntu"
)

cd /var/lib/razor/repo-store

echo "Bootstrapping isos"

###########################################
# Download ISOs
###########################################
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

############################################
# register isos with razor as repos
############################################
# get a list of all repos now in razor
repos=$(curl -s http://localhost:8150/api/collections/repos | jq -r '.items[].name')

# for each k/v pair
for filename in "${!iso_urls[@]}"
do
    # determine if the razor repo has already been created
    repo_found=0
    for repo in ${repos[@]}
    do
        if [[ "${repo}" == "${filename}" ]]
        then
            repo_found=1
            break
        fi
    done

    if [[ ${repo_found} -eq 1 ]]
    then
        echo "repo already exists... skipping"
    else
        razor create-repo --name=${filename} --iso-url file:///var/lib/razor/repo-store/${filename} --task ${iso_tasks[${filename}]}
    fi
done

#################################################
# register noop broker
#################################################
brokers=$(curl -s http://localhost:8150/api/collections/brokers | jq -r '.items[].name')

noop_found=0

for broker in ${brokers[@]}
do
    if [[ "${broker}" == "noop" ]]
    then
        noop_found=1
        break
    fi
done

if [[ ${noop_found} -eq 0 ]]
then
    razor create-broker --name=noop --broker-type=noop
else
    echo "noop broker already exists... skipping"
fi

#####################################################
# register host tags
#####################################################

tags=$(curl -s http://localhost:8150/api/collections/tags | jq -r '.items[].name')

test_hosts_tag_found=0

for tag in ${tags[@]}
do
    if [[ "${tag}" == "test-hosts" ]]
    then
        test_hosts_tag_found=1
        break
    fi
done

if [[ ${test_hosts_tag_found} -eq 0 ]]
then
    echo "test-hosts tag does not exist... creating"
    razor create-tag --name test-hosts --rule "${test_hosts_filter}"
else
    echo "test-hosts tag already exists... updating"
    razor update-tag-rule --name test-hosts --rule "${test_hosts_filter}" --force
fi
