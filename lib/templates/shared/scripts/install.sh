#!/bin/bash
# Modify install_conf.sh and install_cust.sh first.
set -e -x
shopt -s expand_aliases

# set up $HOME and output redirection
HOME=/home/ubuntu
exec > >(tee $HOME/install.log) 2>&1

# use all available disk space
sudo resize2fs /dev/sda1

SCRIPT_DIR=`dirname $0`
source $SCRIPT_DIR/install_conf.sh

alias package_manager='sudo DEBIAN_FRONTEND=noninteractive apt-get -q'

# upgrade and install system packages
package_manager update
package_manager -y upgrade
package_manager -y install $PACKAGES

# define an alias and a function to install source packages
alias download='wget -q --directory-prefix=$HOME'
function extract_and_install {
  local package=$1
  local options=$2
  cd $HOME
  tar -xzf $package.tar.gz
  cd $package
  ./configure --prefix=/usr $options && make && sudo make install
  cd ..
  rm -rf $package*
}

source $SCRIPT_DIR/install_cust.sh

: "=========== SUCCESSFULLY REACHED THE END OF install.sh ==========="
