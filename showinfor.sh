#!/usr/bin/env bash
#
# showinfo script
# Version: MASTER branch
# Author:  lit
#

# Execute a command as root (or sudo)
do_with_root() {
    # already root? "Just do it" (tm).
    if [[ `whoami` = 'root' ]]; then
        $*
    elif [[ -x /bin/sudo || -x /usr/bin/sudo ]]; then
        echo "sudo $*"
        sudo $*
    else
        echo "showinfor requires root privileges to install."
        echo "Please run this script as root."
        exit 1
    fi
}

# Detect distribution name
if [[ `which lsb_release 2>/dev/null` ]]; then
    # lsb_release available
    distrib_name=`lsb_release -is`
elif [[ `which sw_vers 2>/dev/null` ]]; then
    # sw_vers available (for Mac OS X)
    distrib_name=`sw_vers -productName`
else
    # try other method...
    lsb_files=`find /etc -type f -maxdepth 1 \( ! -wholename /etc/os-release ! -wholename /etc/lsb-release -wholename /etc/\*release -o -wholename /etc/\*version \) 2> /dev/null`
    for file in $lsb_files; do
        if [[ $file =~ /etc/(.*)[-_] ]]; then
            distrib_name=${BASH_REMATCH[1]}
            break
        else
            echo "Sorry, showinfo script is not compliant with your system."
            exit 1
        fi
    done
fi

echo "Detected system:" $distrib_name
do_with_root ls
