#!/bin/bash
# This example script downloads a tarball from github and deploys it to /srv.
# You can pass in user_data to invoke this script with different command line
# options when new instances are launched.
set -e -x
shopt -s expand_aliases

HOME=/home/ubuntu
exec 1>$HOME/deploy.log 2>&1

# command line parameters with default values
BRANCH=${1:-master} # can also be the name of a tag
APP_NAME=${2:-YOUR-APP}
BASE_URL=${3:-"https://github.com/YOUR-LOGIN/YOUR-APP/tarball/$BRANCH"}
# user_data is readable by anyone who can log in so it may be better
# to put the access credentials here (readable by user ubuntu only).
# Add this file to .gitignore if it includes credentials.
QUERY_STRING=${4:-'?login=YOUR-LOGIN&token=YOUR-GITHUB-ACCESS-TOKEN'}

DOWNLOAD_URL="$BASE_URL$QUERY_STRING"
DEPLOY_PATH=/srv/$APP_NAME

# don't do anything if the app has already been deployed
if [ -d $DEPLOY_PATH ]; then exit; fi

# add a user (rails) to run your application
if ! id rails &> /dev/null; then sudo adduser --system --group rails; fi

wget -q --no-check-certificate --directory-prefix=$HOME --output-document=tarball.tar.gz $DOWNLOAD_URL
tar --directory $HOME -xzf tarball.tar.gz

sudo mv $HOME/*$APP_NAME* $DEPLOY_PATH
chown -R rails $DEPLOY_PATH
cd $DEPLOY_PATH
sudo bundle install
# sudo breeze deploy_server_configuration
