#!/bin/bash

newline=$'\n'
snap_packages=$(snap list | awk 'NR > 1 {print $1}')

installed_packages() {
    IFS=' ' read -r -a snap_packages_list <<< "$snap_packages"
    for num in 1 3; do
        for snap in "${snap_packages_list[@]}"; do
            if [ "$snap" != "snapd" ]; then 
                killall "$snap"
                sudo snap remove --purge "$snap"
            fi
        done
    done
    
    sudo snap remove --purge snapd && sudo rm -rf /var/cache/snapd/ && sudo apt autoremove --purge snapd gnome-software-plugin-snap -y && sudo rm -rf ~/snap && sudo apt-mark hold snapd && sudo apt install gnome-software -y
    echo All snaps packages have been purged!
}

while true; do
    read -p $"WARNING: THE FOLLOWING SNAP PACKAGES AND THEIR DATA WILL BE REMOVED:${newline}${snap_packages}${newline}DO YOU WANT TO CONTINUE? [Y/n]" yn
    case $yn in 
        [yY] ) installed_packages;
        break;;
        [nN] ) echo Okay;
        break;;
        * ) echo "${newline}Invalid response, try again!${newline}";
    esac
done
