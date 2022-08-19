#!/usr/bin/env bash
###########################################
# This script is for bootstrapping the
# configuration of the razor server.
# Most aspects can be controlled by
# modifying the parameters set in the
# CONFIGURATION section at the top of this
# script.
###########################################

###########################################
# CONFIGURATION
###########################################
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
["ubuntu-16.04.1-desktop-amd64.iso"]="ubuntu/xenial"
["ubuntu-16.04.1-server-amd64.iso"]="ubuntu/xenial"
["ubuntu-18.04-desktop-amd64.iso"]="ubuntu/bionic"
["ubuntu-18.04-live-server-amd64.iso"]="ubuntu/bionic"
)

###########################################
# CLI ARGUMENT FLAGS - DO NOT MODIFY!!!!
###########################################
CLEANUP=0


function print_help() {
    printf "options:\n"
    printf "    --cleanup -- deletes all isos, tasks, repos, and policies this script creates\n"
    printf "    -h -- print help\n\n"

    printf "examples:\n"
    printf "# deletes all isos, tasks, repos, and policies this script creates\n"
    printf "$0 --cleanup\n\n"
    printf "# creates all isos, tasks, repos, and policies\n"
    printf "$0\n\n"

    exit 1
}


function download_isos() {
    ###########################################
    # Download ISOs
    ###########################################
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
}


function delete_isos() {
    cd /var/lib/razor/repo-store

    # for each k/v pair
    for filename in "${!iso_urls[@]}"
    do
        # if the file doesn't already exist
        if [[ -f ${filename} ]]
        then
            rm -f ${filename}
        fi
    done
}


function create_repos() {
    ############################################
    # register isos with razor as repos
    ############################################
    # get a list of all repos now in razor
    repos=$(curl -s http://localhost:8150/api/collections/repos | jq -r '.items[].name')
    
    # for each k/v pair
    for filename in "${!iso_urls[@]}"
    do
        modified_repo_name=$(echo "${filename}" | sed -e 's/\.iso//g')

        # determine if the razor repo has already been created
        repo_found=0
        for repo in ${repos[@]}
        do
            if [[ "${repo}" == "${modified_repo_name}" ]]
            then
                repo_found=1
                break
            fi
        done
    
        if [[ ${repo_found} -eq 1 ]]
        then
            echo "repo already exists... skipping"
        else
            razor create-repo --name=${modified_repo_name} --iso-url file:///var/lib/razor/repo-store/${filename} --task ${iso_tasks[${filename}]}
        fi
    done
}


function destroy_repos() {
    # get a list of all repos now in razor
    repos=$(curl -s http://localhost:8150/api/collections/repos | jq -r '.items[].name')

    # for each k/v pair
    for filename in "${!iso_urls[@]}"
    do
        modified_repo_name=$(echo "${filename}" | sed -e 's/\.iso//g')

        # determine if the razor repo has already been created
        repo_found=0
        for repo in ${repos[@]}
        do
            if [[ "${repo}" == "${modified_repo_name}" ]]
            then
                repo_found=1
                break
            fi
        done

        if [[ ${repo_found} -eq 1 ]]
        then
            razor delete-repo ${modified_repo_name}
        else
            echo "repo does not exist... skipping"
        fi
    done
}


function create_brokers() {
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
}


function destroy_brokers() {
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
	echo "noop broker does not exist... skipping"
    else
        razor delete-broker noop
    fi
}


function create_tags() {
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
}


function destroy_tags() {
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
        echo "test-hosts tag does not exist... skipping"
    else
        razor delete-tag test-hosts
    fi
}


function create_policies() {
    #######################################################
    # create policies
    #######################################################
    
    policies=$(curl -s http://localhost:8150/api/collections/policies | jq -r '.items[].name')
    
    test_hosts_policy_found=0
    
    for policy in ${policies[@]}
    do
        if [[ "${policy}" == "test-hosts" ]]
        then
            test_hosts_policy_found=1
            break
        fi
    done
    
    if [[ ${test_hosts_policy_found} -eq 0 ]]
    then
        echo "test-hosts policy does not exist... creating"
    
        # note that this contains a password in a public repo. As a result
        # be sure your configuration code changes this secret
        razor create-policy --name "test-hosts" --repo "ubuntu-16.04.1-server-amd64" --task "ubuntu/xenial" --broker "noop" --enabled --max-count=100 --tag "test-hosts" --hostname 'host${id}' --root-password '&QP-t]5$xrTkdiyx'
    fi
}


function destroy_policies() {
    #######################################################
    # create policies
    #######################################################

    policies=$(curl -s http://localhost:8150/api/collections/policies | jq -r '.items[].name')

    test_hosts_policy_found=0

    for policy in ${policies[@]}
    do
        if [[ "${policy}" == "test-hosts" ]]
        then
            test_hosts_policy_found=1
            break
        fi
    done

    if [[ ${test_hosts_policy_found} -eq 0 ]]
    then
        echo "test-hosts policy does not exist... skipping"
    else
        razor delete-policy test-hosts
    fi
}


function main() {
    set -Eeo pipefail
    set -x

    if [[ ${CLEANUP} -eq 0 ]]
    then
        download_isos
        create_repos
        create_brokers
        create_tags
        create_policies
    else
        destroy_policies
        destroy_tags
        destroy_brokers
        destroy_repos
        delete_isos
    fi
}

########################################
# handle command line arguments
########################################
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
      --cleanup)
      CLEANUP=1
      shift # past value
      ;;
      -h|--help)
          print_help
      ;;
  esac
done

# call main function
main
