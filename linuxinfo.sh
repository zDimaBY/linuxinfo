#!/bin/bash

# Function to display colored messages
print_color_message() {
    local red=$1
    local green=$2
    local blue=$3
    local message=$4
    echo -e "\033[38;2;${red};${green};${blue}m${message}\033[m"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_color_message 200 0 0 'Error: This script is not run as root.'
fi

# Source /etc/os-release
if [ -e "/etc/os-release" ]; then
    source "/etc/os-release"
else
    print_color_message 200 0 0 "Error: /etc/os-release not found"
    print_color_message 200 0 0 "lsb_release is currently not installed, please install it:"

    case "$(uname -s)" in
    Linux)
        if [ -x "$(command -v apt-get)" ]; then
            print_color_message 200 0 0 "On $(print_color_message 200 165 0 "Debian or Ubuntu:")"
            print_color_message 200 0 0 "sudo apt-get update && sudo apt-get install lsb-release"
        elif [ -x "$(command -v yum)" ]; then
            print_color_message 200 0 0 "On $(print_color_message 200 165 0 "Red Hat-based systems:")"
            print_color_message 200 0 0 "sudo yum install redhat-lsb-core"
        elif [ -x "$(command -v dnf)" ]; then
            print_color_message 200 0 0 "On $(print_color_message 200 165 0 "AlmaLinux:")"
            print_color_message 200 0 0 "sudo dnf install redhat-lsb-core"
        elif [ -x "$(command -v zypper)" ]; then
            print_color_message 200 0 0 "On $(print_color_message 200 165 0 "SUSE:")"
            print_color_message 200 0 0 "sudo zypper install lsb-release"
        elif [ -x "$(command -v pacman)" ]; then
            print_color_message 200 0 0 "On $(print_color_message 200 165 0 "Arch Linux:")"
            print_color_message 200 0 0 "sudo pacman -S lsb-release"
        else
            print_color_message 200 0 0 "Unsupported package manager. Please install lsb-release manually."
        fi
        ;;
    *)
        print_color_message 200 0 0 "Unsupported operating system. Please install lsb-release manually."
        ;;
    esac

    exit 1
fi

# Check if the OS is supported
case "${ID}" in
"debian" | "ubuntu")
    if [ -n "$VERSION" ]; then
        print_color_message 0 200 0 "You have a system installed: $(print_color_message 200 0 200 "${ID} ${VERSION}")"
    else
        print_color_message 0 200 0 "You have a system installed: $(print_color_message 200 0 200 "${ID} ${VERSION_ID}")"
    fi
    ;;
"rhel" | "almalinux" | "eurolinux" | "rocky" | "centos")
    print_color_message 0 200 0 "You have a system installed: $(print_color_message 200 0 0 "${ID} ${VERSION_ID} (Red Hat-based system)")."
    ;;
*)
    print_color_message 200 0 0 "Your operating system is not officially supported."
    print_color_message 200 0 0 "Supported releases include: Debian 10, 11, Ubuntu 18.04, 20.04, 22.04, and Red Hat-based systems."
    exit 1
    ;;
esac

# Function to check server info and control panel
checkInfoServerAndControlPanel() {
    load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    load_average=${load_average%,*}
    load_average=$(echo "${load_average/,/.}")

    if (($(awk 'BEGIN {print ($load_average < 2)}'))); then
        load_average=$(print_color_message 0 200 0 "$load_average")
    elif (($(awk 'BEGIN {print ($load_average < 5)}'))); then
        load_average=$(print_color_message 200 200 0 "$load_average")
    else
        load_average=$(print_color_message 200 0 0 "$load_average (!)")
    fi

    largest_disk=$(df -h | grep '^/dev/' | sort -k 4 -hr | head -n 1)
    disk_usage=$(echo "$largest_disk" | awk '{print $5}')
    echo -e "Load Average: $load_average Disk Usage: $disk_usage"

    server_hostname=$(hostname)
    server_IP=$(hostname -I | awk '{print $1}')
    echo -e "Hostname: $(print_color_message 0 200 0 "$server_hostname") IP: $(print_color_message 0 200 0 "$server_IP")"

    for panel_dir in "/usr/local/hestia" "/usr/local/vesta" "/usr/local/mgr5" "/usr/local/cpanel" "/usr/local/fastpanel2"; do
        if [ -d "$panel_dir" ]; then
            case $panel_dir in
            "/usr/local/hestia")
                source "$panel_dir/conf/hestia.conf"
                print_color_message 0 102 204 "${APP_NAME} $(print_color_message 51 153 102 "$VERSION") backend: $(print_color_message 200 200 0 "$WEB_SYSTEM")"
                ;;
            "/usr/local/vesta")
                source "$panel_dir/conf/vesta.conf"
                print_color_message 0 200 200 "Vesta Control Panel $(print_color_message 200 0 200 "$VERSION") backend: $(print_color_message 200 200 0 "$WEB_SYSTEM")"
                ;;
            "/usr/local/mgr5")
                print_color_message 0 200 0 "ISPmanager is installed."
                "$panel_dir/sbin/licctl" info ispmgr
                ;;
            "/usr/local/cpanel")
                print_color_message 0 200 0 "cPanel is installed."
                "$panel_dir/cpanel" -V
                cat /etc/*release
                ;;
            "/usr/local/fastpanel2")
                fastuser_passwd_dir="/usr/local/fastpanel2/app/config/.my.cnf"
                print_color_message 0 150 230 "FastPanel is installed."
                if [ -f $fastuser_passwd_dir ]; then
                    cat "$fastuser_passwd_dir" | tr '\n' ' ' && echo
                else
                    print_color_message 200 0 0 "File $fastuser_passwd_dir not found."
                fi
                ;;
            "/usr/local/brainycp")
                print_color_message 0 123 193 "BrainyCP is installed."
                #  Memory detector
                arr=(mysqld exim dovecot httpd nginx named brainyphp-fpm pure-ftpd memcached redis fail2ban csf xinetd sshd clamd clamsmtp-clamd spamassassin proftpd network NetworkManager postgresql tuned)
                for t in "${arr[@]}"; do
                    #systemctl reload $t
                    mem=$(systemctl status "$t" | grep Memory:)
                    echo "$mem - $t"
                done

                fpm=$(ls /lib/systemd/system | grep php | grep fpm@ | cut -d' ' -f1)
                for t in ${fpm[@]}; do
                    #systemctl reload "$t"
                    mem=$(systemctl status "$t" | grep Memory:)
                    echo "$mem - $t"
                done
                ;;
            esac

            source /etc/os-release
            return
        fi
    done
    print_color_message 200 0 0 "Control panel not found."

}

# Display OS information and check control panel
checkInfoServerAndControlPanel

if command -v mysql >/dev/null 2>&1; then
    print_color_message 0 200 0 "MySQL $(print_color_message 0 117 143 "$(mysql -V)")"
fi

if command -v mariadb >/dev/null 2>&1; then
    print_color_message 0 200 0 "MariaDB $(print_color_message 0 117 143 "$(mariadb -V)")"
fi

if command -v psql >/dev/null 2>&1; then
    print_color_message 0 200 0 "PostgreSQL $(print_color_message 0 117 143 "$(psql --version)")"
fi

if command -v sqlite3 >/dev/null 2>&1; then
    print_color_message 0 200 0 "SQLite $(print_color_message 0 117 143 "$(sqlite3 --version)")"
fi

if ! command -v mysql >/dev/null 2>&1 && ! command -v mariadb >/dev/null 2>&1 && ! command -v psql >/dev/null 2>&1 && ! command -v sqlite3 >/dev/null 2>&1; then
    print_color_message 200 0 0 "MySQL, MariaDB, PostgreSQL, or SQLite is not installed."
fi

if command -v php >/dev/null 2>&1; then
    print_color_message 200 215 0 "PHP $(print_color_message 79 93 149 "$(php -v | grep -Eo 'PHP ([0-9]+\.[0-9]+\.[0-9]+)' | grep -Eo '([0-9]+\.[0-9]+\.[0-9]+)')")"
fi

if command -v python3 >/dev/null 2>&1; then
    print_color_message 0 200 0 "Python is installed: $(print_color_message 0 117 143 "$(python3 --version 2>&1 | head -n 1)")"
fi

if command -v node >/dev/null 2>&1; then
    print_color_message 0 200 0 "Node.js is installed: $(print_color_message 0 117 143 "$(node --version)")"
fi

if ! command -v php >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
    print_color_message 200 0 0 "PHP, Python or Node.js is not installed."
fi

if command -v docker >/dev/null 2>&1; then
    print_color_message 0 102 204 "$(docker -v)"
    docker ps -a
else
    print_color_message 200 0 0 "Docker is not installed."
fi

if command -v composer >/dev/null 2>&1; then
    print_color_message 0 200 0 "Composer is installed: $(print_color_message 0 117 143 "$(composer --version | head -n 1)")"
else
    print_color_message 200 0 0 "Composer is not installed."
fi

ports=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d ':' -f 2 | sort -n | uniq)
for port in $ports; do
    count=$(ss -an | grep ":$port " | wc -l)
    if [[ $count -ge 3 ]]; then
        echo -e "Port $port: $(print_color_message 200 165 0 "$count")"
    fi
done
ss -plns
ss -utnpl | awk '{printf "%-6s %-6s %-7s %-7s %-42s %-42s %-s\n", $1, $2, $3, $4, $5, $6, $7}'
