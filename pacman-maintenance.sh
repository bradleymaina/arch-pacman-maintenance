#!/usr/bin/env bash
set -o pipefail

exec 9>/tmp/pacman-maintenance.lock

log(){
    severity="$1"
    message="$2"

    echo "$(date '+%Y-%m-%d %H:%M:%S') [$severity] $message" >> /var/log/pacman-maintenance.log

}


flock -n 9 || {
    log "ERROR" "Another instance of the script is already running."
    exit 1
}

check_network(){
    ping -q -c 1 google.com
    status=$?
    if [ "$status" -ne 0 ]; then
        log "ERROR" "Network is down. Please check your internet connection."
        return 1
    else 
        log "INFO" "Network is up. Proceeding with mirrorlist update........"
        return 0
    fi
}

update_mirrorlist(){
   # safely backup exisisting mirrorlist
   sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup || {
        log "ERROR" "Failed to backup mirrorlist."
        return 1
   }

   # fetch live mirrorlist, filter and sort by speed and update the mirrorlist
   #used endpoint that returns a JSON object
   curl  -s "https://archlinux.org/mirrors/status/json/" \
   |jq -r '.urls[] | select(.active and .completion_pct == 1.0 and .protocol == "https") | "Server = \(.url)$repo/os/$arch"' > /tmp/mirrorlist.new 

   if [ "$?" -ne 0 ]; then
        log "ERROR" "Failed to fetch mirrorlist."
        return 1
   fi

   rankmirrors -m 10 -w -n 6 -p /tmp/mirrorlist.new > /tmp/mirrorlist.ranked

   if [ "$?"  -ne 0 ]; then
        log "ERROR" "Failed to rank mirrors."
        return 1
    fi

    cp /tmp/mirrorlist.ranked /etc/pacman.d/mirrorlist || {
        log "ERROR" "Failed to update mirrorlist."
        return 1 
        }

    log "INFO" "Mirrorlist updated successfully."
    return 0
}

upgrade_system(){
    sudo pacman -Syu --noconfirm

    if [ "$?" -eq 0 ]; then
        log "INFO" "System upgraded successfully."
        return 0
    else
        log "ERROR" "System upgrade failed."
        return 1
    fi
}


check_network || exit 1
update_mirrorlist || exit 1 
upgrade_system || exit 1
