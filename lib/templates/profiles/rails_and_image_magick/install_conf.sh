# This script is sourced at the beginning of install.sh.
# PACKAGES, RUBY_PACKAGE, IMAGE_MAGICK_PACKAGE, IMAGE_MAGICK_OPTIONS and NGINX_OPTIONS are required.
# The IMAGE_MAGICK_PACKAGE defined below may no longer be available from the download url specified
# in install_cust.sh. Find the latest release at http://www.imagemagick.org/script/download.php.

# define packages to install
SYSTEM_PACKAGES="git-core monit"
DB_CLIENT_PACKAGES="mysql-client libmysqlclient16 libmysqlclient16-dev"
RUBY_BUILD_DEPENDENCIES="\
  build-essential bison openssl zlib1g libxslt1.1 libssl-dev libxslt1-dev libxml2 \
  libffi-dev libyaml-dev libxslt-dev autoconf libc6-dev libreadline6-dev zlib1g-dev"
NGINX_AND_PASSENGER_DEPENDENCIES="libpcre3-dev libcurl4-openssl-dev"

# $PACKAGES is used by install.sh
PACKAGES="$SYSTEM_PACKAGES $DB_CLIENT_PACKAGES $RUBY_BUILD_DEPENDENCIES $NGINX_AND_PASSENGER_DEPENDENCIES"

# the rest is used by install_cust.sh
RUBY_PACKAGE=ruby-1.9.2-p136
IMAGE_MAGICK_PACKAGE=ImageMagick-6.6.7-7
IMAGE_MAGICK_OPTIONS='--disable-static --with-modules --without-perl --without-magick-plus-plus --with-quantum-depth=8'
NGINX_OPTIONS="\
  --conf-path=/etc/nginx/nginx.conf \
  --lock-path=/var/lock/nginx.lock \
  --http-client-body-temp-path=/tmp/nginx/client_body_temp \
  --http-proxy-temp-path=/tmp/nginx/proxy_temp \
  --http-fastcgi-temp-path=/tmp/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/tmp/nginx/uwsgi_temp \
  --http-scgi-temp-path=/tmp/nginx/scgi_temp \
  --with-pcre \
  --with-http_ssl_module \
  --with-http_realip_module"
# more options at http://wiki.nginx.org/Modules
