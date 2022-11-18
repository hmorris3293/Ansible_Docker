#!/bin/bash

source <ssinclude StackScriptID="401712">

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# Set hostname, apt configuration and update/upgrade
set_hostname
apt_setup_update

# Install GIT
apt-get update && apt-get install -q -y git

# Cloning AzuraCast and install
mkdir -p /var/azuracast
cd /var/azuracast
curl -fsSL https://raw.githubusercontent.com/AzuraCast/AzuraCast/master/docker.sh > docker.sh
chmod a+x docker.sh
./docker.sh install

# Cleanup
stackscript_cleanup