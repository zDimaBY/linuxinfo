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

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_message "${RED}" 'Error: This script must be run as root.'
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

# Source /etc/os-release
source "/etc/os-release"

# Check if the OS is supported
case "${ID}" in
"debian" | "ubuntu")
    print_message "${GREEN}" "Detected Operating System: ${YELLOW}${ID} ${VERSION_ID}${GREEN}"
    ;;
"rhel" | "almalinux" | "eurolinux" | "rocky" | "centos")
    print_message "${GREEN}" "Detected Operating System: ${YELLOW}${ID} ${VERSION_ID}${RED} (Red Hat-based system)."
    ;;
*)
    print_message "${RED}" "Your operating system is not officially supported."
    print_message "${RED}" "Supported releases include: Debian 10, 11, Ubuntu 18.04, 20.04, 22.04, and Red Hat-based systems."
    exit 1
    ;;
esac

# Function to check server info and control panel
checkInfoServerAndControlPanel() {
    load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    load_average=${load_average%,*}
    load_average=$(echo "${load_average/,/.}")

    if (($(echo "$load_average < 2" | bc -l))); then
        load_average="${GREEN}$load_average${RESET}"
    elif (($(echo "$load_average < 5" | bc -l))); then
        load_average="${YELLOW}$load_average${RESET}"
    else
        load_average="${RED}$load_average (!)${RESET}"
    fi

    largest_disk=$(df -h | grep '^/dev/' | sort -k 4 -hr | head -n 1)
    disk_usage=$(echo "$largest_disk" | awk '{print $5}') # Использование места на самом большом диске
    echo -e "Load Average: $load_average Disk Usage: $disk_usage"

    server_hostname=$(hostname)
    server_IP=$(hostname -I | awk '{print $1}')
    echo -e "Hostname:${GREEN}$server_hostname${RESET} IP: $server_IP"

    for panel_dir in "/usr/local/hestia" "/usr/local/vesta" "/usr/local/mgr5" "/usr/local/cpanel"; do
        if [ -d "$panel_dir" ]; then
            case $panel_dir in
            "/usr/local/hestia")
                source "$panel_dir/conf/hestia.conf"
                print_message "${CYAN}" "${APP_NAME} ${MAGENTA}$VERSION${RESET} backend: ${YELLOW}${WEB_SYSTEM}"
                ;;
            "/usr/local/vesta")
                source "$panel_dir/conf/vesta.conf"
                print_message "${CYAN}" "Vesta Control Panel ${MAGENTA}$VERSION${RESET} backend: ${YELLOW}${WEB_SYSTEM}"
                ;;
            "/usr/local/mgr5")
                print_message "${GREEN}" "ISPmanager is installed."
                "$panel_dir/sbin/licctl" info ispmgr
                ;;
            "/usr/local/cpanel")
                print_message "${GREEN}" "cPanel is installed."
                "$panel_dir/cpanel" -V
                cat /etc/*release
                ;;
            esac

            source /etc/os-release
            return
        fi
    done
    print_message "${RED}" "Control panel not found."
}

# Display OS information and check control panel
checkInfoServerAndControlPanel

# Display colored message before running the command
print_message "${GREEN}" "Running command..."
ports=(21 22 25 80 443 1500 3306 8083)
for port in "${ports[@]}"; do
    count=$(ss -an | grep ":$port " | wc -l)
    echo -e "Port $port: ${YELLOW}$count${RESET}"
done
ss -plns
ss -utpl | tr -d '\t' | column -t
