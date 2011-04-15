# This script is sourced at the end of install.sh when packages have been installed
# and aliases and functions have been defined.

# install ruby
download ftp://ftp.ruby-lang.org//pub/ruby/1.9/$RUBY_PACKAGE.tar.gz
extract_and_install $RUBY_PACKAGE
sudo gem update --system
sudo gem install --no-ri --no-rdoc bundler passenger breeze

# install nginx and passenger
sudo passenger-install-nginx-module --auto --auto-download --prefix=/usr --extra-configure-flags="$NGINX_OPTIONS"
# remove confusing nginx configuration files that are not used
sudo rm -rf /etc/nginx/{conf.d,fastcgi*,scgi_params*,sites-*,uwsgi*}

# install ImageMagick
package_manager -y build-dep imagemagick
download ftp://ftp.imagemagick.org/pub/ImageMagick/$IMAGE_MAGICK_PACKAGE.tar.gz
extract_and_install $IMAGE_MAGICK_PACKAGE "$IMAGE_MAGICK_OPTIONS"

# set up the shell environment for user ubuntu
cat >> $HOME/.profile <<END_PROFILE
# export RAILS_ENV=production
# export EDITOR=vi
# alias rails='sudo -E -u rails ./script/rails'
END_PROFILE
