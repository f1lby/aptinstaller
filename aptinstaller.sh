#!/bin/bash

# Kali Linux APT Package Auto Installer
# F1lby
# November 2025
# V1.0
# Tested with Kali Linux x64 2025.4

echo "Kali Linux Additional Package Installer by F1lby"
echo " "
echo "Disclaimer 1: Running this script is making the assumption that all packages are trustworthy and fit for purpose and do not contain any malicious code - The onus is on you to ensure you are happy with these packages from a C,I and A perspective"
echo " "
echo "Disclaimer 2: This was tested on Kali Linux with the XFCE GUI. No warranty given for any failures of this package"
echo " "
echo " "


# Now we wait for 5 seconds to give the user a chance to press any key to quit early.

#!/bin/zsh

echo "Waiting for 5 seconds....."
echo "Press any key to terminate early if you don't wish to continue."

# Detect shell and use appropriate read command
if [ -n "$ZSH_VERSION" ]; then
    # Zsh
    read -k 1 -t 5 key && {
        echo "Key pressed. Terminating."
        exit 0
    }
else
    # Bash or other POSIX shell
    read -n 1 -t 5 key && {
        echo " "
        echo "Key pressed. TERMINATING."
        echo " "
        exit 0
    }
fi
echo " "
echo "No key pressed. Continuing with the install"



# Check if run as root and exit if NOT root
if [[ $EUID -ne 0 ]]; then
   echo " "
   echo "THIS SCRIPT MUST BE RUN AS ROOT. TRY AGAIN USING sudo."
   tput bel
   exit 1
fi


echo "This can take an extended period time to complete depending on the number of packages being installed."
echo " "
echo "You might need to go away and make yourself a cup of tea while the script runs....."
echo " "

sleep 2

echo  First we make a change to the /etc/needrestart/needrestart.conf file
echo This changes the # $nrconf{restart} = 'i'; parameter to $nrconf{restart} = 'a';
echo This changes the application to automatic restart of services when needed as opposed to
echo interactive mode where you are prompted. This stops any annoying prompts.


echo We will install needstart
sudo apt install needrestart -y
# read ans

CONFIG_FILE="/etc/needrestart/needrestart.conf"
BACKUP_FILE="/etc/needrestart/needrestart.conf.bak"

# Backup the original file
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Use SED to modify the restart parameter
sed -i "s/\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" "$CONFIG_FILE"
echo "Updated needrestart.conf: restart behavior set to automatic ('a')."



# Now we do a bunch of apt installs of packages that are listed in the aptpackages.txt.
# If you are on an unreliable network and the install fails, the MAX_RETRIES parameter can be increased to attempt a retry on failure. Normally this isn't required.

PACKAGE_FILE="aptpackages.txt"
LOG_FILE="install_log.txt"
MAX_RETRIES=1
DEBIAN_FRONTEND=noninteractive

if [[ ! -f "$PACKAGE_FILE" ]]; then
    echo "Error: $PACKAGE_FILE not found!"
    exit 1
fi

echo "Updating package list..."
sudo apt update && sudo apt upgrade -y


echo "Installation Log - $(date)" > "$LOG_FILE"

while IFS= read -r package; do
    [[ -z "$package" || "$package" =~ ^# ]] && continue

    if dpkg -l | grep -qw "$package"; then
        echo "[SKIP] $package is already installed." | tee -a "$LOG_FILE"
        continue
    fi

    echo "Installing $package..."
    attempt=1
    success=false

    while [[ $attempt -le $MAX_RETRIES ]]; do
        # Refresh package list before retry
        sudo apt-get update -y

        if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$package"; then
            echo "[SUCCESS] $package installed successfully on attempt $attempt." | tee -a "$LOG_FILE"
            success=true
            break
        else
            echo "[WARNING] Attempt $attempt to install $package failed." | tee -a "$LOG_FILE"
            sleep 10  # Wait before retry
            ((attempt++))
        fi
    done

    if [[ "$success" == false ]]; then
        echo "[ERROR] Failed to install $package after $MAX_RETRIES attempts." | tee -a "$LOG_FILE"
    fi
done < "$PACKAGE_FILE"

# Now we do a final cleanup

echo "Cleaning up..."
sudo apt-get autoremove -y
sudo apt-get clean

# The good work is done.
echo "Installation complete! Check $LOG_FILE for details."
echo "F1lby thanks you for using his code :-) - Have a nice day"
