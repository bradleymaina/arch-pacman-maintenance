#!/usr/bin/env bash

check_network(){
    ping -q -c 1 google.com
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "Network is down. Please  check your internet connection."
        return 1
    else 
        echo "Network is up. Proceeding with mirrorlist update........"
    fi
}

update_mirrorlist(){
   # safely backup exisisting mirrorlist
   sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup || {
        echo "Failed to backup mirrorlist."
        return 1
   }

   # fetch live mirrorlist, filter and sort by speed and update the mirrorlist
   curl  "https://archlinux.org/mirrorlist/?country=all&protocol=https&use_mirror_status=on" \
   | sed -e 's/^#Server/Server/' -e '/^#/d' > /tmp/mirrorlist.new 

   if [ "$?" -ne 0 ]; then
        echo "Failed to fetch mirrorlist."
        return 1
   fi

   rankmirrors -m 10 -w -n 6 -p /tmp/mirrorlist.new > /tmp/mirrorlist.ranked

   if [ "$?"  -ne 0 ]; then
        echo "Failed to rank mirrrors."
        return 1
    fi

    cp /tmp/mirrorlist.ranked /etc/pacman.d/mirrorlist || {
        echo "Failed to update mirrorlist."
        return 1 
        }

    echo "Mirrorlist updated successfully."
    return 0
}

upgrade_system(){
    sudo pacman -Syu --noconfirm || {
        echo "System upgrade failed."
        return 1
    }

}

check_network || exit 1
update_mirrorlist || exit 1 
upgrade_system || exit 1