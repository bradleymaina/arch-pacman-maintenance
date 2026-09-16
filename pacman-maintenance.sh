#!/usr/bin/env bash

check_network(){
    ping -c 1 google.com
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "Network is down. Please  check your internet connection."
        return 1
    fi
}

check_network