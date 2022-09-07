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
######### adding a new iso ################
# update iso_urls map
# update iso_tasks map
###########################################

######## updating host targeting ##########
# update tags map
###########################################
###########################################


###########################################
# HELPER FUNCTIONS
###########################################
function addPolicy() {
  policy_names+=("$1")
  policies["$1_repo"]="$2"
  policies["$1_task"]="$3"
  policies["$1_broker"]="$4"
  policies["$1_tag"]="$5"
  policies["$1_root_password"]="$6"  
}


###########################################
# CONFIGURATION
###########################################

declare -A iso_urls

# k/v of filenames and download urls for isos
# repos names are the name of this key with .iso removed from the key
iso_urls=(
["ubuntu-16.04.1-desktop-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/q35kklGQHh8UnuX/download"
["ubuntu-16.04.1-server-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/NdvfibI06WdvTbi/download"
["ubuntu-18.04-desktop-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/FYhSU6icibEEFr2/download"
["ubuntu-18.04-live-server-amd64.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/5OehYpFeJ1xMl32/download"
["OracleLinux-R7-U9-Server-x86_64-dvd.iso"]="https://owncloud.tech-hell.com:8444/index.php/s/n2vGK0aUekfG9VQ/download"
)


declare -A iso_tasks

iso_tasks=(
["ubuntu-16.04.1-desktop-amd64.iso"]="ubuntu/xenial"
["ubuntu-16.04.1-server-amd64.iso"]="ubuntu/xenial"
["ubuntu-18.04-desktop-amd64.iso"]="ubuntu/bionic"
["ubuntu-18.04-live-server-amd64.iso"]="ubuntu/bionic"
["OracleLinux-R7-U9-Server-x86_64-dvd.iso"]="oracle/7"
)


declare -A tags

tags=(
["test-hosts"]='["in", ["fact", "macaddress"], "00:0c:29:f8:23:bf", "00:0c:29:f8:23:c0"]'
["opennebula"]='["in", ["fact", "macaddress"], "00:0c:29:e6:f1:07"]'
)

###################################
# WARNING!!!!!!!!
#
# This contains a secret that is no big deal if it gets leaked because it is for demo purposes.
# If you intend on using a real secret, you better use a secret manager and pull it from there rather
# than commit it to a public repo
###################################
declare -A policies=()
declare -a policy_names=()

addPolicy "test-hosts" "ubuntu-16.04.1-server-amd64" "ubuntu/xenial" "noop" "test-hosts" '&QP-t]5$xrTkdiyx'
addPolicy "opennebula" "OracleLinux-R7-U9-Server-x86_64-dvd" "oracle/7" "noop" "opennebula" '&QP-t]5$xrTkdiyx'


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
    
    razor_tags=$(curl -s http://localhost:8150/api/collections/tags | jq -r '.items[].name')
    
    # for each k/v pair
    for tag in "${!tags[@]}"
    do
        # determine if the razor tag has already been created
        tag_found=0
        for razor_tag in ${razor_tags[@]}
        do
            if [[ "${razor_tag}" == "${tag}" ]]
            then
                tag_found=1
                break
            fi
        done

        if [[ ${tag_found} -eq 1 ]]
        then
            echo "${tag} tag already exists... updating"
            razor update-tag-rule --name "${tag}" --rule "${tags[${tag}]}" --force
        else
            echo "${tag} tag does not exist... creating"
            razor create-tag --name "${tag}" --rule "${tags[${tag}]}"
        fi
    done
}


function destroy_tags() {
    #####################################################
    # register host tags
    #####################################################

    tags=$(curl -s http://localhost:8150/api/collections/tags | jq -r '.items[].name')

    # for each k/v pair
    for tag in "${!tags[@]}"
    do
        # determine if the razor tag has already been created
        tag_found=0
        for razor_tag in ${razor_tags[@]}
        do
            if [[ "${razor_tag}" == "${tag}" ]]
            then
                tag_found=1
                break
            fi
        done

        if [[ ${tag_found} -eq 0 ]]
        then
            echo "${tag} tag does not exist... skipping"
        else
            razor delete-tag "${tag}"
        fi
    done
}


function create_policies() {
    #######################################################
    # create policies
    #######################################################

    razor_policies=$(curl -s http://localhost:8150/api/collections/policies | jq -r '.items[].name')

    # for each k/v pair
    for policy in "${policy_names[@]}"; do
        # determine if the razor tag has already been created
        policy_found=0
        for razor_policy in ${razor_policies[@]}
        do
            if [[ "${razor_policy}" == "${policy}" ]]
            then
                policy_found=1
                break
            fi
        done


        if [[ ${policy_found} -eq 0 ]]
        then
            echo "${policy} policy does not exist... creating"

            razor create-policy --name "${policy}" --repo "${policies[${policy}_repo]}" --task "${policies[${policy}_task]}" --broker "${policies[${policy}_broker]}" --enabled --max-count=100 --tag "${policies[${policy}_tag]}" --hostname 'host${id}' --root-password "${policies[${policy}_root_password]}"
        fi
    done
}


function destroy_policies() {
    #######################################################
    # create policies
    #######################################################


    razor_policies=$(curl -s http://localhost:8150/api/collections/policies | jq -r '.items[].name')

    # for each k/v pair
    for policy in "${policy_names[@]}"; do
        # determine if the razor tag has already been created
        policy_found=0
        for razor_policy in ${razor_policies[@]}
        do
            if [[ "${razor_policy}" == "${policy}" ]]
            then
                policy_found=1
                break
            fi
        done


        if [[ ${policy_found} -eq 0 ]]
        then
            echo "${policy} policy does not exist... skipping"
        else
            razor delete-policy "${policy}"
        fi
    done
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
