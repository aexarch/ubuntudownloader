#!/bin/bash
echo -e "Ubuntu ISO Downloader for Desktop x64 architectures\n"

# The following code segment checks for internet connectivity, then enters an if statement.
echo -e "This bash script requires an active internet connection and may also require superuser permissions.\nPlease ensure that you have both before proceeding."
cat < /dev/null > /dev/tcp/8.8.8.8/53; ONLINE=$? 
if [ $ONLINE -eq 0 ]; then
    echo -e "\nThe network connection is up. Proceeding...\n"
else
  echo -e "\nThe network connection is down.\nPlease connect to the internet and try again."
  exit 1
fi

# The following code segment checks if the wget dependency is installed, and, if apt-get is present, installs the missing package.
echo -e "\nIn order for this bash script to work the wget package needs to be installed, if not present.\nIn such case, the script will try to install it."
if [[ -z $(which wget) ]]; then
    echo -e "\nwget package is not installed."
    if [[ ! -z $(which apt-get) ]]; then
        echo -e "\nAttempting to update package list and install via APT. Please provide superuser permissions.\n"
        sudo apt-get update
        sudo apt-get install wget
        INSTALLSTATUS=$?
        if [ $INSTALLSTATUS -ne 0 ]; then
            echo -e "\nThere was an error while installing the missing wget package.\nPlease install wget manually and rerun this script."
            exit 127
        fi
        echo -e "\nDone. Proceeding...\n"
    else
        echo -e "\nUnable to retrieve missing package wget.\nYou'll have to manually install it and rerun this script."
        exit 127
    fi
fi

# The following code segment is a function that deletes the script's temporary files when called.
cleanup () {
    rm -rf releases.ubuntu.com
    rm urls.txt
    rm vnrs.txt
}

# The following code segment uses wget in spider mode, pipes its output to grep to be filtered for ftp urls using regex, then pipes to sort to only keep unique occurrences of pattern matches, saves output in urls.txt, reads the lines of text into an array
echo -e "\nFetching download URLs for available Ubuntu versions and building menu. Please wait..."
wget -r --spider -l0 -A iso ftp://releases.ubuntu.com/releases/.pool/ 2>&1 | grep -Eo '(ftp)://[^/"].+\-desktop\-amd64\.iso' | sort -u > urls.txt
readarray urlarr < urls.txt

# The following code processes urls.txt with awk to only print the version numbers into a text file called vnrs.txt, then reads the file into an array
awk -F"-" '{ print $2 }' urls.txt > vnrs.txt
readarray vnrarr < vnrs.txt

# The following code segment checks if the array is empty. If it is, it exits.
if [ ${#vnrarr[@]} -eq 0 ]; then
    echo -e "\nThe filelist returned seems to be empty.\nPlease check connectivity and retry later.\nIf this issue persists, please contact the developer of this script.\n"
    echo -e "Tidying up and exiting script."
    cleanup
    exit 1
fi

# The following code segment generates a selection menu using version numbers as entries, matching the choice to the array of urls
VERSION=""
while [[ $VERSION = "" ]]; do
    echo -e "\nPlease enter the choice number corresponding to the Ubuntu version you want to download.\n"
    select VERSION in "${vnrarr[@]}"; do
        if [[ $VERSION = "" ]]; then
            echo -e "\nInvalid choice! Please enter a number from 1 to ${#vnrarr[@]}.\n"
        else
            ARRVNR=$(( REPLY - 1 )) # Since array indexes start with zero we need to decrement the number by one
            TARGET=${urlarr[$ARRVNR]}
            echo -e "\nFile selected: $TARGET\n"

# The following code segment adds option to abort by requesting confirmation before download
            read -p "Download the file? Type Y to download or anything else to exit. " -n 1 -r
            echo -e "\n"
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "\nUser aborted. Tidying up and exiting script."
                cleanup
                exit 0
            fi

# The following code segment utilizes wget to download the file, in quiet mode, resumable and with infinite tries
            echo -e "\nInitiating download...\n"
            wget $TARGET -c --quiet --tries=0 --read-timeout=30 --show-progress --progress=bar:force 2>&1
            echo -e "\nDone! Thank you for using my script.\n"
        fi
        break
    done
done
echo "Tidying up and exiting script."
cleanup
exit 0
