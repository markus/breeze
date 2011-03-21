#!/bin/bash
# This example script downloads a tarball from github and deploys it to /srv.
# You can pass in user_data to invoke this script with different command line
# arguments when new server instances are launched.
set -e -x
shopt -s expand_aliases

HOME=/home/ubuntu
# exec 1>$HOME/deploy.log 2>&1
exec > >(tee $HOME/deploy.log) 2>&1

source $HOME/credentials.sh

# command line arguments with default values
PUBLIC_SERVER_NAME=$1
DB_SERVER=$2
BRANCH=${3:-master} # can also be the name of a tag
APP_NAME=${4:-YOUR-APP}
BASE_URL=${5:-"https://github.com/YOUR-LOGIN/YOUR-APP/tarball/$BRANCH"}
# NOTICE: user_data is readable by anyone who can log in but
# credentials.sh is readable only by user ubuntu (and sudoers)
QUERY_STRING=${6:-"?login=YOUR-GITHUB-LOGIN&token=$GITHUB_TOKEN"}

DOWNLOAD_URL="$BASE_URL$QUERY_STRING"
DEPLOY_PATH=/srv/$APP_NAME

# don't do anything if the app has already been deployed
if [ -d $DEPLOY_PATH ]; then exit; fi

# add a user (rails) to run your application
sudo adduser --system --group rails
# add user ubuntu to the rails group so that ubuntu can read database.yml
sudo usermod --groups rails ubuntu

wget -q --no-check-certificate --directory-prefix=$HOME --output-document=tarball.tar.gz $DOWNLOAD_URL
tar --directory $HOME -xzf tarball.tar.gz
sudo mv $HOME/*$APP_NAME* $DEPLOY_PATH

cd $DEPLOY_PATH
bundle install --deployment --without=test development
sudo chown -R rails:rails $DEPLOY_PATH
sudo PUBLIC_SERVER_NAME=$PUBLIC_SERVER_NAME DB_SERVER=$DB_SERVER thor configuration:deploy_to_localhost
sudo /etc/init.d/monit start
