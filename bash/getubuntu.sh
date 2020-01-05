#!/bin/bash
echo -e "Ubuntu ISO Downloader for Desktop x64 architectures\n"
echo -e "This bash script requires an active internet connection and may also require superuser permissions.\nPlease ensure that you have both before proceeding."
cat < /dev/null > /dev/tcp/8.8.8.8/53; ONLINE=$( echo $? )
if [ $ONLINE -eq 0 ]; then
    echo -e "\nThe network connection is up. Proceeding...\n"
else
  echo -e "\nThe network connection is down.\nPlease connect to the internet and try again."
  exit
fi
echo -e "\nIn order for this bash script to work you first need to install the wget package, if not present.\nThis will require superuser permissions.\nAn APT package list update will be necessary too."
if [[ -z $(which wget) ]]; then
    echo -e "\nwget package is not installed."
    if [[ ! -z $(which apt-get) ]]; then
        echo -e "\nAttempting to update package list and install via APT. Please provide superuser permissions.\n"
        sudo apt-get update
        sudo apt-get install wget
        if [ $? -eq 0 ]; then
            echo -e "\nDone. Proceeding...\n"
        else
            echo -e "\nThere was an error while installing the missing wget package. apt-get exit code is: $?\nPlease install wget manually and rerun this script."
            exit
        fi
    else
        echo -e "\nUnable to retrieve missing package wget.\nYou'll have to manually install it and rerun this script."
        exit
    fi
fi
echo -e "\nFetching download URLs for available Ubuntu versions and building menu. Please wait..."
wget -r --spider -l0 -A iso ftp://releases.ubuntu.com/releases/.pool/ 2>&1 | grep -Eo '(ftp)://[^/"].+\-desktop\-amd64\.iso' | sort -u > urls.txt
readarray urlarr < urls.txt
cat urls.txt | awk -F"-" '{ print $2 }' > vnrs.txt
readarray vnrarr < vnrs.txt
if [ ${#vnrarr[@]} -eq 0 ]; then
    echo -e "\nThe filelist returned seems to be empty. Please check connectivity and retry later.\nIf this issue persists, please contact the developer of this script.\n"
    echo -e "Cleaning up and terminating script..."
    rm -rf releases.ubuntu.com
    rm urls.txt
    rm vnrs.txt
    exit
fi
VERSION=""
while [[ $VERSION = "" ]]; do
    echo -e "\nPlease enter the choice number corresponding to the Ubuntu version you want to download.\n"
    select VERSION in "${vnrarr[@]}"; do
        if [[ $VERSION = "" ]]; then
            echo -e "\nInvalid choice! Please enter a number from 1 to ${#vnrarr[@]}.\n"
        else
            ARRVNR=$(( REPLY - 1 ))
            TARGET=$urlarr[$ARRVNR]
            echo -e "\nFile selected: $TARGET\n"
            read -p "Download the file? (Type Y to download or anything else to exit) " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "\nUser aborted. Tidying up and exiting script."
                rm -rf releases.ubuntu.com
                rm urls.txt
                rm vnrs.txt
                exit
            fi
            echo -e "\nInitiating download...\n"
            wget $TARGET -c --quiet --tries=0 --read-timeout=30 --show-progress --progress=bar:force 2>&1
            echo -e "\nDone! Thank you for using my script.\n"
        fi
        break
    done
done
echo "\nTidying up and exiting script."
rm -rf releases.ubuntu.com
rm urls.txt
rm vnrs.txt
exit 0
