#!/usr/bin/bash

echo "RDeploy Copyright (c) 2015, Blas Orlando Soto Muñoz"
echo ""

if [[ ! $# -eq 3 ]]; then
	echo "Error: Syntax incorrect, the correct syntax is"
	echo "./rdeploy.sh vhost_file_name server_name url_git"
	exit
fi

in_array() {
    local hay needle=$1
    shift
    for hay; do
        [[ $hay == $needle ]] && return 0
    done
    return 1
}

VERSION_UBUNTU_NAME=$(lsb_release -c | awk '{ print $2 }')

SUPPORTED_UBUNTU=("trusty" "saucy" "raring" "precise" "lucid" "wheezy" "squeeze")
SUPPORTED_UBUNTU_STR=$( IFS=$', '; echo "${SUPPORTED_UBUNTU[*]}" )

if ! in_array $SUPPORTED_UBUNTU $VERSION_UBUNTU_NAME; then
	echo "Error: This ubuntu version is not supported, actual version is ${VERSION_UBUNTU_NAME} and supported version are ${SUPPORTED_UBUNTU_STR}."
	exit
fi

VHOST_FILE_NAME=$1
SERVER_NAME=$2
NOTHING=""
DEV="develop."
ONLY_NAME="${SERVER_NAME/\www./$NOTHING}"
DEV_NAME="${SERVER_NAME/\www./$DEV}"
DIR_BASE="/web"
URL_GIT=$3
mkdir $DIR_BASE

PATH_TO_PROJECT="$DIR_BASE/$VHOST_FILE_NAME"
PATH_TO_PROJECT_DEVELOP="$DIR_BASE/$VHOST_FILE_NAME_develop"

PATH_TO_PUBLIC="$PATH_TO_PROJECT/public"
PATH_TO_PUBLIC_DEVELOP="$PATH_TO_PROJECT_DEVELOP/public"

SITES_AVAILABLED="/etc/nginx/sites-available/"
SITES_ENABLED="/etc/nginx/sites-enabled/"

mkdir $PATH_TO_PROJECT
mkdir $PATH_TO_PROJECT_DEVELOP

cd $PATH_TO_PROJECT
git init
git remote add origin $URL_GIT
git fetch --all
git checkout master
git pull origin master

cd $PATH_TO_PROJECT_DEVELOP
git init
git remote add origin $URL_GIT
git fetch --all
git checkout develop
git pull origin develop

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
apt-get install apt-transport-https ca-certificates

passenger_file="/etc/apt/sources.list.d/passenger.list"

echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger $VERSION_UBUNTU_NAME main" > $passenger_file

chown root: /etc/apt/sources.list.d/passenger.list
chmod 600 /etc/apt/sources.list.d/passenger.list

apt-get update
apt-get -y upgrade
apt-get -y install nginx-extras passenger

echo "passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;" > /etc/nginx/conf.d/passenger.conf 
echo "passenger_ruby /usr/bin/ruby;" >> /etc/nginx/conf.d/passenger.conf

echo "    server {" > $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        listen 80;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        server_name $SERVER_NAME $ONLY_NAME;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        root $PATH_TO_PUBLIC;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        passenger_enabled on;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        access_log /var/log/nginx/access_$VHOST_FILE_NAME.log;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        error_log /var/log/nginx/error_$VHOST_FILE_NAME.log;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "    }" >> $SITES_AVAILABLED$VHOST_FILE_NAME

echo "    server {" > $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        listen 80;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        server_name $DEV_NAME;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        root $PATH_TO_PUBLIC_DEVELOP;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        passenger_enabled on;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        access_log /var/log/nginx/access_$VHOST_FILE_NAME_develop.log;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "        error_log /var/log/nginx/error_$VHOST_FILE_NAME_develop.log;" >> $SITES_AVAILABLED$VHOST_FILE_NAME
echo "    }" >> $SITES_AVAILABLED$VHOST_FILE_NAME

ln $SITES_AVAILABLED$VHOST_FILE_NAME -s $SITES_ENABLED$VHOST_FILE_NAME

while [[ $PATH_TO_PUBLIC != "/" ]]; do chmod +x $PATH_TO_PUBLIC; PATH_TO_PUBLIC=$(dirname $PATH_TO_PUBLIC); done;

service nginx restart

echo ""
echo ""
echo "Deploy is finish!"