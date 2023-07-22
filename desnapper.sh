#!/bin/bash

newline=$'\n'
snap_packages=$(snap list | awk 'NR > 1 {print $1}')
readarray -t snap_packages_list <<<"$snap_packages"
distro_name=$(grep -w NAME= --no-group-separator /etc/*-release)
flavor=""
deb_or_snap=""

if [ $distro_name != '/etc/os-release:NAME="Ubuntu"' ]
then
    echo "${newline}Sorry, this script only supports Ubuntu and its flavors"
    exit
fi

ask_for_flavor() {
    while true
    do
        read -p "FLAVOR IS NEEDED TO DECIDE WHICH COMMANDS TO RUN${newline}Input either Ubuntu or Kubuntu. If you're running Kubuntu, put in Kubuntu. If you're running ANY other flavor, just put in Ubuntu: " flavor

        # Convert the input to lowercase for case-insensitive comparison
        flavor=$(echo "$flavor" | tr '[:upper:]' '[:lower:]')

        # Check if the flavor is valid and break the loop if it is
        if [ "$flavor" == "ubuntu" ] || [ "$flavor" == "kubuntu" ]
        then
            break
        else
            echo "${newline}Invalid response, please try again!"
        fi
    done
}

purge_snaps() {
    for num in 1 3; do
        for snap in "${snap_packages_list[@]}"
        do
            if [ "$snap" != "snapd" ]; then 
                killall $snap
                sudo snap remove --purge $snap
            fi
        done
    done
    
    sudo apt remove --autoremove snapd -y 
    echo "Package: snapd${newline}Pin: release a=*${newline}Pin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
    sudo apt update -y

    if [ "$flavor" == "ubuntu" ]
    then
        sudo apt install --install-suggests gnome-software -y
    fi

    echo "${newline}All snaps packages have been purged!"
}

install_firefox_deb () {
    sudo add-apt-repository ppa:mozillateam/ppa -y 
    sudo apt update -y
    sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
    echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
    echo "Package: firefox*${newline}Pin: release o=LP-PPA-mozillateam${newline}Pin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa

    echo "${newline}Firefox .deb sucessfully installed!"
}

install_flatpak() {
    sudo apt install flatpak -y

    if [ "$flavor" == "ubuntu" ]
    then
        sudo apt install gnome-software-plugin-flatpak -y
    else
        sudo apt install plasma-discover-backend-flatpak -y
    fi

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    echo "${newline}Flatpak and Flathub are now installed and enabled!"
}

replace_snaps() {
    if [ $deb_or_snap == 'deb' ]
    then
        for package_to_install in "${snap_packages_list[@]}"
        do
            sudo apt install $package_to_install -y
        done
    else
        if grep -Fxq "$package_to_install" excluded_snaps.txt
        then
            :
        else
            for package_to_install in "${snap_packages_list[@]}"
            do
                snap_to_flatpak=$(grep "^${package_to_install}," applist.csv | cut -d',' -f2)
                flatpak install $snap_to_flatpak -y
            done
        fi
    fi
}

ask_for_flavor

while true
do
    read -p "${newline}WARNING: THE FOLLOWING SNAP PACKAGES AND THEIR DATA WILL BE REMOVED:${newline}${snap_packages}${newline}DO YOU WANT TO CONTINUE? [Y/n] " yn
    case $yn in 
        [yY] ) purge_snaps;
        break;;
        [nN] ) echo "${newline}Okay";
        break;;
        * ) echo "${newline}Invalid response, try again!";
    esac
done

while true
do
    read -p "${newline}Would you like to install the Firefox .deb package? [Y/n] " yn
    case $yn in 
        [yY] ) install_firefox_deb;
        break;;
        [nN] ) echo "${newline}Okay";
        break;;
        * ) echo "${newline}Invalid response, try again!";
    esac
done

while true
do
    read -p "${newline}Would you like to install Flatpak/Flathub? [Y/n] " yn
    case $yn in 
        [yY] ) install_flatpak;
        break;;
        [nN] ) echo "${newline}Okay";
        break;;
        * ) echo "${newline}Invalid response, try again!";
    esac
done

while true
do
    read -p "${newline}Would you like to replace all removed snaps with .deb/Flatpak packages?${newline}NOTE: NOT ALL SNAPS HAVE EQUIVALENT .DEBS/FLATPAKS [Y/n] " yn
    case $yn in 
        [yY] )
            read -p "${newline}Would you like to replace all removed snaps with .deb/Flatpak packages? [deb/Flatpak] " deb_or_snap
            deb_or_snap=$(echo "${deb_or_snap}" | tr '[:upper:]' '[:lower:]')
            case $deb_or_snap in
                deb) replace_snaps
                break;;
                flatpak) replace_snaps
                break;;
                *) echo "${newline}Invalid response, try again!";
            esac
            ;;
        [nN] ) echo "${newline}Okay";
        break;;
        * ) echo "${newline}Invalid response, try again!";
    esac
done
