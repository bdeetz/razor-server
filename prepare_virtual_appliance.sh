#!/usr/bin/env bash
docker exec -it -u postgres puppet-razor /var/lib/razor/repo-store/ccdc_bootstrap.sh --cleanup

systemctl stop puppet-razor

cwd=$(pwd)

# cleanup repo-store
cd /mnt/repo-store/
rm -v !("ccdc_bootstrap.sh"|"bootstrap.ipxe")

cd ${cwd}

# cleanup database storage
rm -rf /mnt/postgresql_data/*

# check if boostraps are modified in repo-store
diff ./ccdc_bootstrap.sh /mnt/repo-store/ccdc_bootstrap.sh
ret=$?

if [[ ${ret} -ne 0 ]]
then
  echo "the repository's ccdc_boostrap.sh file is not equal to"
  echo "/mnt/repo-store/ccdc_bootstrap.sh"
  echo ""
  echo "you should run 'diff ./ccdc_bootstrap.sh /mnt/repo-store/ccdc_bootstrap.sh'"
  echo "to determine if you would like to update the bootstrap file at /mnt/repo-store/ccdc_bootstrap.sh"
  echo "with the version in this repo."
  echo ""
  echo ""
  echo ""
fi

diff ./bootstrap.ipxe /mnt/repo-store/bootstrap.ipxe
ret=$?

if [[ ${ret} -ne 0 ]]
then
  echo "the repository's bootstrap.ipxe file is not equal to"
  echo "/mnt/repo-store/bootstrap.ipxe"
  echo ""
  echo "you should run 'diff ./bootstrap.ipxe /mnt/repo-store/bootstrap.ipxe'"
  echo "to determine if you would like to update the bootstrap file at /mnt/repo-store/bootstrap.ipxe"
  echo "with the version in this repo."
  echo ""
  echo ""
  echo ""
fi
