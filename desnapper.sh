#!/bin/bash

newline=$'\n'
snap_packages=$(snap list | awk 'NR > 1 {print $1}')

purge_snaps() {
    readarray -t snap_packages_list <<<"$snap_packages"
    for num in 1 3; do
        for snap in "${snap_packages_list[@]}"; do
            if [ "$snap" != "snapd" ]; then 
                killall "$snap"
                sudo snap remove --purge "$snap"
            fi
        done
    done
    
    sudo snap remove --purge snapd && sudo rm -rf /var/cache/snapd/ && sudo apt autoremove --purge snapd gnome-software-plugin-snap -y && sudo rm -rf ~/snap && sudo apt-mark hold snapd && sudo apt install gnome-software -y
    echo $newline All snaps packages have been purged!
}

install_flatpak() {
    sudo apt install flatpak -y && sudo apt install gnome-software-plugin-flatpak -y && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo $newline Flatpak and Flathub are now installed and enabled! Reboot for the changes to take effect.
}

while true; do
    read -p $"${newline} WARNING: THE FOLLOWING SNAP PACKAGES AND THEIR DATA WILL BE REMOVED:${newline}${snap_packages}${newline}DO YOU WANT TO CONTINUE? [Y/n]" yn
    case $yn in 
        [yY] ) purge_snaps;
        break;;
        [nN] ) echo Okay;
        break;;
        * ) echo "${newline}Invalid response, try again!${newline}";
    esac
done

while true; do
    read -p $"${newline} Would you like to install Flatpak/Flathub?" yn
    case $yn in 
        [yY] ) install_flatpak;
        break;;
        [nN] ) echo $newline Okay;
        break;;
        * ) echo "${newline}Invalid response, try again!${newline}";
    esac
done

