#!/bin/bash

# [ ! -f ~/.vimrc ] && { echo -e "set number\nsyntax on" > ~/.vimrc && trap 'rm ~/.vimrc' EXIT && (command -v curl &> /dev/null && curl -sSL https://raw.githubusercontent.com/zDimaBY/linuxinfo/main/linuxinfo.sh | bash || (command -v wget &> /dev/null && wget -qO- https://raw.githubusercontent.com/zDimaBY/linuxinfo/main/linuxinfo.sh -O - | bash || { print_message "${RED}" "Error: Neither 'curl' nor 'wget' found. Please install one of them to continue." && exit 1; })) && echo "Settings applied for the current session."; } || echo "File .vimrc already exists, no changes made."

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
    print_message "${RED}" "lsb_release is currently not installed, please install it:"

    case "$(uname -s)" in
        Linux)
            if [ -x "$(command -v apt-get)" ]; then
                print_message "${RED}" "On ${YELLOW}Debian or Ubuntu${RED}:"
                print_message "${RED}" "sudo apt-get update && sudo apt-get install lsb-release"
            elif [ -x "$(command -v yum)" ]; then
                print_message "${RED}" "On ${YELLOW}Red Hat-based${RED} systems:"
                print_message "${RED}" "sudo yum install redhat-lsb-core"
            elif [ -x "$(command -v dnf)" ]; then
                print_message "${RED}" "On ${YELLOW}AlmaLinux${RED}:"
                print_message "${RED}" "sudo dnf install redhat-lsb-core"
            elif [ -x "$(command -v zypper)" ]; then
                print_message "${RED}" "On ${YELLOW}SUSE${RED}:"
                print_message "${RED}" "sudo zypper install lsb-release"
            elif [ -x "$(command -v pacman)" ]; then
                print_message "${RED}" "On ${YELLOW}Arch Linux${RED}:"
                print_message "${RED}" "sudo pacman -S lsb-release"
            else
                print_message "${RED}" "Unsupported package manager. Please install lsb-release manually."
            fi
            ;;
        *)
            print_message "${RED}" "Unsupported operating system. Please install lsb-release manually."
            ;;
    esac

    exit 1
fi

# Check for supported OS
case "${ID}" in
    "debian" | "ubuntu")
        print_message "${GREEN}" "Detected Operating System: ${YELLOW}${ID} ${VERSION_ID}${GREEN}"
        ;;
    "rhel" | "almalinux" | "eurolinux" | "rocky" | "centos")
        print_message "${GREEN}" "Detected Operating System: ${YELLOW}${ID} ${VERSION_ID}${GREEN} Red Hat-based system."
        ;;
    *)
        print_message "${RED}" "Your operating system is not officially supported."
        print_message "${RED}" "Supported releases include: Debian 10, 11, Ubuntu 18.04, 20.04, 22.04 and on a Red Hat-based system."
        exit 1
        ;;
esac

# Displaying colored message before running the command
print_message "${GREEN}" "Running command..."
ports=(21 22 25 443 1500 3306 8083)
for port in "${ports[@]}"; do
    count=$(ss -an | grep ":$port " | wc -l)
    echo "Port $port: $count"
done
ss -utplns
