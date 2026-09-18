#!/usr/bin/env bash
set -o pipefail

exec 9>/tmp/pacman-maintenance.lock

flock -n 9 || {
    echo "Another instance of the script is already running."
    exit 1
}

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
   #used endpoint that returns a JSON object
   curl  -s "https://archlinux.org/mirrors/status/json/" \
   |jq -r '.urls[] | select(.active and .completion_pct == 1.0 and .protocol == "https") | "Server = \(.url)$repo/os/$arch"' > /tmp/mirrorlist.new 

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