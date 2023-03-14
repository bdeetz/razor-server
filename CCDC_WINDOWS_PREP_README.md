# building a windows iso for razor
## add default gateway config to the dhcp server's config
within /etc/dhcp/dhcpd.conf ensure the subnet defintion for the dhcp pool contains:
`option routers 10.66.0.1;`

## Convert the iso from udf to iso-13346
```
# create scratch directories
mkdir -p isos/mount

cd isos

# download the iso to a linux machine
curl -o "windows_10_x64_10240_16384.iso" "https://owncloud.tech-hell.com:8444/index.php/s/9l10TlnsMF40Uta/download"

# extract boot.bin
geteltorito udfimage.iso > boot.bin

# mount the udf iso
mount -o loop -t auto windows_10_x64_10240_16384.iso mount

# prep new iso
cp -r mount udfimagecontents

# unmount the udf iso
umount mount

# include boot.bin
cp boot.bin udfimagecontents

# create the iso
mkisofs -udf -b boot.bin -no-emul-boot -hide boot.bin -relaxed-filenames -joliet-long -D -o converted_windows_10_x64_10240_16384.iso udfimagecontents

# cleanup
rm -rf udfimagecontents
rm -rf mount
rm boot.bin
```

## Prepare razor-winpe
on a windows computer install the Windows ADK as described here https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install

pull the `build-winpe` directory from the root of the `razor-server` repo onto a windows computer
- https://github.com/bdeetz/razor-server/tree/master/build-winpe

download dell drivers from https://www.dell.com/support/home/en-us/product-support/product/latitude-e7470-ultrabook/drivers

extract dell drivers using 7zip to the `extra-drivers` path of the `build-winpe` directory

run the followoing command from the build-winpe directory as administrator within powershell:
`powershell -executionpolicy bypass -file build-razor-winpe.ps1 -razorurl http://10.66.0.10:8150/svc -allowunsigned`

The above creates a files in the `razor-winpe` subdirectory of `build-winpe` named `boot.wim`

copy the boot.wim file to /mnt/repo-store/windows_10_x64_10240_16384/ on the razor server
`chown 70:70 /mnt/repo-store/windows_10_x64_10240_16384/boot.wim`

## modify install.wim to install drivers
download the install.wim file from the razor server onto the same computer you modified boot.wim. the file is loacated at /mnt/repo-store/windows_10_x64_10240_16384/sources/install.wim

create a directory to mount the wim to
`mkdir E:\temp\wim`

ensure the install.wim file is not set to "ready only" in properties

mount the image useing the following command
`dism /mount-wim /wimfile:.\install.wim /index:1 /mountdir:E:\temp\wim`

add the drivers to the image.wim file
`dism /image:E:\temp\wim /add-driver /Driver:.\extra-drivers /recurse`

commit the changes to install.wim

copy the install.wim file to the root user's home directory on the razor server
`scp /mnt/e/Users/bdeet/Downloads/build-winpe/install.wim root@10.66.0.10:~/`

backup the old install.wim file on the razor server
`cp /mnt/repo-store/windows_10_x64_10240_16384/sources/install.wim /mnt/repo-store/windows_10_x64_10240_16384/install.wim.bak`

replace the old install.wim file with the new one on the razor server
`mv /root/install.wim /mnt/repo-store/windows_10_x64_10240_16384/sources/install.wim`

set permissions for install.wim
```
chown 70:70 sources/install.wim
setfacl -Rm "g:nogroup:rx,d:g:nogroup:rx" /mnt/repo-store/
setfacl -Rm "u:nobody:rx,d:u:nobody:rx" /mnt/repo-store/
```

## Create the samba share
```
sudo apt-get install -y samba acl

setfacl -Rm "g:nogroup:rx,d:g:nogroup:rx" /mnt/repo-store/
setfacl -Rm "u:nobody:rx,d:u:nobody:rx" /mnt/repo-store/

# create a linux user named `user` with password `password`
# this is required by the scripts that run on the windows host as it installs windows
adduser user

# create a samba user named `user` with password `password`

cat << EOF >> /etc/samba/smb.conf
[razor]
   comment = razor repos
   path = /mnt/repo-store/
   public = yes
   guest only = yes
   read only = yes
   force create mode = 0666
   force directory mode = 0777
   browseable = yes
EOF

sudo systemctl restart smbd
```
