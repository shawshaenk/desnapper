#Import required modules
from subprocess import run
import os
import sys

def purge_snaps():
    #Warn user and list installed snaps
    data = run("snap list | awk 'NR > 1 {print $1}'", capture_output=True, shell=True, text=True)
    desnap_or_not = input(f"WARNING: THE FOLLOWING SNAP PACKAGES AND THEIR DATA WILL BE REMOVED:\n{data.stdout}\nDO YOU WANT TO CONTINUE? Y/n: ")

    #Run if the user enters Y, y, or enter
    if desnap_or_not.lower() == 'y' or desnap_or_not == '':
        installed_snaps = data.stdout.split('\n')

        #Iterate through installed snaps and purge them
        for num in range (0, 2):
            for snap_program in installed_snaps:
                if snap_program != 'snapd':
                    os.system(f'killall {snap_program}')
                    os.system(f'sudo snap remove --purge {snap_program}')

        #Remove snap remnants
        os.system('sudo snap remove --purge snapd && sudo rm -rf /var/cache/snapd/ && sudo apt autoremove --purge snapd gnome-software-plugin-snap && sudo rm -rf ~/snap && sudo apt-mark hold snapd')
        os.system('echo "\nAll snaps packages have been purged!"')   
    
    #Run if user did not consent to removing all snaps
    else:
        #Exit the script
        os.system('echo "Okay, exiting..."')
        sys.exit()

def install_flatpak():
    #Ask user if they want to install and enable Flatpak/Flathub
    install_flatpak_or_not = input('Would you like to install and enable Flatpak and Flathub? Y/n: ')

    #Run if the user enters Y, y, or enter
    if install_flatpak_or_not.lower() == 'y' or install_flatpak_or_not == '':

        #Install Flatpak/Flathub
        os.system('sudo apt install flatpak && sudo apt install gnome-software-plugin-flatpak && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo')
        os.system('echo "\nFlatpak and Flathub are now installed and enabled! Reboot for the changes to take effect."')

    #Run if the user did not consent to installing Flatpak/Flathub
    else:
        #Exit the script
        os.system('echo "Okay, exiting..."')
        sys.exit()

#Run script
purge_snaps()
install_flatpak()