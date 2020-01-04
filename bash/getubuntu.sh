#!/bin/bash
echo -e "Ubuntu ISO Downloader for Desktop x64 architectures\n"
echo -e "This script requires an active internet connection and superuser permissions.\nPlease ensure that you have access to both before proceeding."
cat < /dev/null > /dev/tcp/8.8.8.8/53; ONLINE=$( echo $? )
if [ $ONLINE -eq 0 ]; then
    echo -e "\nThe network connection is up. Proceeding...\n"
else
  echo -e "\nThe network connection is down.\nPlease connect to the internet and try again."
  exit
fi
echo -e "\nIn order for this bash script to work you first need to install the wget package for your distro, if not present.\nThis will require superuser permissions.\nA APT package list update will be necessary too, beforehand."
echo -e "\nAttempting to update package lists and install the prerequisites through APT...\nPlease provide superuser permissions."
sudo apt-get update
sudo apt-get install wget
echo -e "\nFetching download URLs for available Ubuntu versions and building menu. Please wait..."
wget -r --spider -l0 -A iso ftp://releases.ubuntu.com/releases/.pool/ 2>&1 | grep -Eo '(ftp)://[^/"].+\-desktop\-amd64\.iso' | sort -u > urls.txt
readarray urlarr < urls.txt
cat urls.txt | awk -F"-" '{ print $2 }' > vnrs.txt
readarray vnrarr < vnrs.txt
VERSION=""
while [[ $VERSION = "" ]]; do
    echo -e "\nPlease enter the number corresponding to the Ubuntu version you want to download.\n"
    select VERSION in "${vnrarr[@]}"; do
         if [[ $VERSION = "" ]]; then
              echo -e "\nInvalid choice! Please enter a number from 1 to ${#vnrarr[@]}"
         else
              ARRVNR=$(( REPLY - 1 ))
              echo -e "\nFile selected: ${urlarr[$ARRVNR]}"
              echo -e "\nInitiating download...\n"
              wget ${urlarr[$ARRVNR]} -q --show-progress --progress=bar:force 2>&1
              echo -e "\nDone! Thank you for using my script.\n"
         fi
         break
     done
done
echo "Tidying up and exiting script.”
rm -rf releases.ubuntu.com
rm urls.txt
rm vnrs.txt
exit 0
