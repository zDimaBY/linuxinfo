#!/bin/bash
# Color codes
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"
LIGHT_GREEN="\e[92m"
BROWN='\033[0;33m'
RESET="\e[0m"

# Function to display colored messages
print_message() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    print_message "${RED}" 'Error: this script can only be executed by root'
    exit 1
fi

# Source /etc/os-release
if [ -e "/etc/os-release" ]; then
    source "/etc/os-release"
else
    print_message "${RED}" "Error: /etc/os-release not found"
    exit 1
fi

# Detect OS
if [ -e "/etc/os-release" ] && [ ! -e "/etc/redhat-release" ]; then
    type=$(grep "^ID=" /etc/os-release | cut -f 2 -d '=')
    if [ "$type" = "ubuntu" ]; then
        # Check if lsb_release is installed
        if [ -e '/usr/bin/lsb_release' ]; then
            release="$(lsb_release -s -r)"
            VERSION='ubuntu'
        else
            print_message "${RED}" "lsb_release is currently not installed, please install it:"
            print_message "${RED}" "apt-get update && apt-get install lsb-release"
            exit 1
        fi
    elif [ "$type" = "debian" ]; then
        release=$(cat /etc/debian_version | grep -o "[0-9]\{1,2\}" | head -n1)
        VERSION='debian'
    fi
elif [ -e "/etc/os-release" ] && [ -e "/etc/redhat-release" ]; then
    type=$(grep "^ID=" /etc/os-release | cut -f 2 -d '"')
    if [ "$type" = "rhel" ]; then
        release=$(cat /etc/redhat-release | cut -f 1 -d '.' | awk '{print $3}')
        VERSION='rhel'
    elif [ "$type" = "almalinux" ]; then
        release=$(cat /etc/redhat-release | cut -f 1 -d '.' | awk '{print $3}')
        VERSION='almalinux'
    elif [ "$type" = "eurolinux" ]; then
        release=$(cat /etc/redhat-release | cut -f 1 -d '.' | awk '{print $3}')
        VERSION='eurolinux'
    elif [ "$type" = "rocky" ]; then
        release=$(cat /etc/redhat-release | cut -f 1 -d '.' | awk '{print $3}')
        VERSION='rockylinux'
    fi
else
    type="NoSupport"
fi

no_support_message() {
    print_message "${RED}" "****************************************************"
    print_message "${RED}" "Your operating system (OS) is not supported by"
    print_message "${RED}" "Linux info. Officially supported releases:"
    print_message "${RED}" "****************************************************"
    print_message "${RED}" "  Debian 10, 11"
    print_message "${RED}" "  Ubuntu 18.04 20.04, 22.04"
    print_message "${RED}" "  AlmaLinux, EuroLinux, Red Hat EnterPrise Linux, Rocky Linux 8,9"
    print_message "${RED}" ""
    exit 1
}

if [ "$type" = "NoSupport" ]; then
    no_support_message
fi

# Displaying colored message before running the command
print_message "${GREEN}" "Your operating system ${YELLOW}${type} ${VERSION_ID}${GREEN}. Running command..."
ss -utplns
