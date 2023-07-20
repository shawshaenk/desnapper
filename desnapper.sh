#!/bin/bash

newline=$'\n'
snap_packages=$(snap list | awk 'NR > 1 {print $1}')

purge_snaps() {
    readarray -t snap_packages_list <<<"$snap_packages"
    for num in 1 3; do
        for snap in "${snap_packages_list[@]}"; do
            if [ "$snap" != "snapd" ]; then 
                killall $snap
                sudo snap remove --purge $snap
            fi
        done
    done
    
    sudo apt remove --autoremove snapd -y 
    sudo chmod o+w /etc/apt/preferences.d
    sudo touch /etc/apt/preferences.d/nosnap.pref
    sudo chmod o+w nosnap.pref
    echo "Package: snapd${newline}Pin: release a=*${newline}Pin-Priority: -10" >> /etc/apt/preferences.d/nosnap.pref
    sudo apt update
    sudo apt install --install-suggests gnome-software -y
    sudo add-apt-repository ppa:xtradeb/play -y
    sudo chmod o-w /etc/apt/preferences.d/nosnap.pref
    sudo chmod o-w /etc/apt/preferences.d

    echo $newline All snaps packages have been purged!
}

install_firefox_deb () {
    sudo add-apt-repository ppa:mozillateam/ppa -y 
    sudo apt update -y
    sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
    sudo chmod o+w /etc/apt/apt.conf.d
    sudo touch /etc/apt/apt.conf.d/51unattended-upgrades-firefox
    sudo chmod o+w /etc/apt/apt.conf.d/51unattended-upgrades-firefox
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
    sudo chmod o+w /etc/apt/preferences.d
    sudo touch /etc/apt/preferences.d/mozillateamppa
    sudo chmod o+w /etc/apt/preferences.d/mozillateamppa
    echo "Package: firefox*${newline}Pin: release o=LP-PPA-mozillateam${newline}Pin-Priority: 501" >> /etc/apt/preferences.d/mozillateamppa 
    sudo chmod o-w /etc/apt/apt.conf.d/51unattended-upgrades-firefox
    sudo chmod o-w /etc/apt/apt.conf.d
    sudo chmod o-w /etc/apt/preferences.d/mozillateamppa
    sudo chmod o-w /etc/apt/preferences.d

    echo $newline Firefox .deb sucessfully installed!
}

install_flatpak() {
    sudo apt install flatpak -y
    sudo apt install gnome-software-plugin-flatpak -y
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo $newline Flatpak and Flathub are now installed and enabled! Reboot for the changes to take effect.
}

while true; do
    read -p $"WARNING: THE FOLLOWING SNAP PACKAGES AND THEIR DATA WILL BE REMOVED:${newline}${snap_packages}${newline}DO YOU WANT TO CONTINUE? [Y/n]" yn
    case $yn in 
        [yY] ) purge_snaps;
        break;;
        [nN] ) echo Okay;
        break;;
        * ) echo "${newline}Invalid response, try again!${newline}";
    esac
done

while true; do
    read -p $"${newline}Would you like to install the Firefox .deb package? [Y/n]" yn
    case $yn in 
        [yY] ) install_firefox_deb;
        break;;
        [nN] ) echo $newline Okay;
        break;;
        * ) echo "${newline}Invalid response, try again!${newline}";
    esac
done

while true; do
    read -p $"${newline}Would you like to install Flatpak/Flathub? [Y/n]" yn
    case $yn in 
        [yY] ) install_flatpak;
        break;;
        [nN] ) echo $newline Okay;
        break;;
        * ) echo "${newline}Invalid response, try again!${newline}";
    esac
done
