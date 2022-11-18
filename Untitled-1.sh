#!/bin/bash
#<UDF name="domain" label="Your domain" default="">
#<UDF name="token" label="Your Linode API Token. This is needed to create your DNS records and automate Lets Encrypt certificate creation" default="">
#<UDF name="email_address" label="Admin Email for Lets Encrypt certificate" default="">


# Helper function
source <ssinclude StackScriptID="1">
source <ssinclude StackScriptID="401712">
source <ssinclude StackScriptID="632759">

# Logging
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# Set hostname, configure apt and perform update/upgrade
apt_setup_update

### Set hostname, Apt configuration and update/upgrade
if [[ "$DOMAIN" = "" ]]; then
  readonly FQDN=$(dnsdomainname -A | awk '{print$1}')
elif [[ "$HOSTNAME" = "" ]]; then
  readonly FQDN=${DOMAIN}
else
  readonly FQDN="${HOSTNAME}.${DOMAIN}"
fi
echo $IP $FQDN $FQDN >> /etc/hosts
hostnamectl set-hostname $FQDN
readonly ip=$(hostname -I | awk '{print$1}')
apt_setup_update

# Create the DNS records, if desired
if [ "${TOKEN}" != "" ]; then
    apt install -y jq
    set_basic_dns "${TOKEN}" "${HOSTNAME}" "${ip}" "${DOMAIN}" "a"
fi

# Install Prereq's & Services
tee /etc/apt/sources.list.d/mongodb-org-4.2.list << EOF
deb https://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main
EOF

tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt buster main
EOF

apt-get install dirmngr -y
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv E162F504A20CDF15827F718D4B7C549A058F8B6B
apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A
apt_setup_update
apt-get install pritunl mongodb-org -y
systemctl start mongod pritunl
systemctl enable mongod pritunl

# Cleanup 
stackscript_cleanup	



#!/bin/bash
#<UDF name="rabbitmquser" Label="RabbitMQ User" />
#<UDF name="rabbitmqpassword" Label="RabbitMQ Passwrod" example="s3cure_p4ssw0rd" />

# Helper function
source <ssinclude StackScriptID="401712">

# Set hostname, configure apt and perform update/upgrade
apt_setup_update

## Install prerequisites
apt-get install curl gnupg -y

## Install RabbitMQ signing key
curl -fsSL https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc | sudo apt-key add -

## Install apt HTTPS transport
apt-get install apt-transport-https

## Add Bintray repositories that provision latest RabbitMQ and Erlang 23.x releases
tee /etc/apt/sources.list.d/bintray.rabbitmq.list <<EOF
## Installs the latest Erlang 23.x release
deb https://dl.bintray.com/rabbitmq-erlang/debian bionic erlang
## Installs latest RabbitMQ release
deb https://dl.bintray.com/rabbitmq/debian bionic main
EOF

## Update packages
apt_setup_update

## Install rabbitmq-server and its dependencies
apt-get install rabbitmq-server -y --fix-missing
rabbitmq-plugins enable rabbitmq_management

# Add rabbitmq admin users
rabbitmqctl add_user $RABBITMQUSER $RABBITMQPASSWORD
rabbitmqctl set_user_tags $RABBITMQUSER administrator
rabbitmqctl set_permissions -p / $RABBITMQUSER ".*" ".*" ".*"

# Cleanup 
stackscript_cleanup	