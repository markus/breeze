# This script is sourced at the end of install.sh when packages have been installed
# and aliases and functions have been defined.

# set up the shell environment for user ubuntu
cat >> $HOME/.profile <<END_PROFILE
# export EDITOR=vi
END_PROFILE
