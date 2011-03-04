#!/bin/bash
# This example script downloads a tarball from github and deploys it to /srv.
# You can pass in user_data to invoke this script with different command line
# arguments when new server instances are launched.
set -e -x
shopt -s expand_aliases

HOME=/home/ubuntu
exec 1>$HOME/deploy.log 2>&1

source $HOME/credentials.sh

# command line arguments with default values
BRANCH=${1:-master} # can also be the name of a tag
APP_NAME=${2:-YOUR-APP}
BASE_URL=${3:-"https://github.com/YOUR-LOGIN/YOUR-APP/tarball/$BRANCH"}
# NOTICE: user_data is readable by anyone who can log in but
# credentials.sh is readable only by user ubuntu (and sudoers)
QUERY_STRING=${4:-"?login=YOUR-GITHUB-LOGIN&token=$GITHUB_TOKEN"}

DOWNLOAD_URL="$BASE_URL$QUERY_STRING"
DEPLOY_PATH=/srv/$APP_NAME

# don't do anything if the app has already been deployed
if [ -d $DEPLOY_PATH ]; then exit; fi

# add a user (rails) to run your application
if ! id rails &> /dev/null; then sudo adduser --system --group rails; fi

wget -q --no-check-certificate --directory-prefix=$HOME --output-document=tarball.tar.gz $DOWNLOAD_URL
tar --directory $HOME -xzf tarball.tar.gz

sudo mv $HOME/*$APP_NAME* $DEPLOY_PATH
sudo chown -R rails $DEPLOY_PATH
cd $DEPLOY_PATH
sudo bundle install
sudo breeze deploy_server_configuration
sudo /etc/init.d/monit start
