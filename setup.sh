

###### -- system level - execute as sudo
## user setup
useradd svc_app
passwd -d svc_app

# system
yum -y update
yum install -y bash curl git patch
yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel
## options
yum install -y mod_dav_svn subversion

yum install -y gcc ruby-devel libxml2 libxml2-devel libxslt libxslt-devel
yum install -y mysql-server mysql mysql-devel qt-devel qt-config 
yum install -y memcached
yum install -y nginx

# application environment
mkdir /opt/app
chown user_name /opt/app


cat >/etc/nginx/nginx.conf << EOF
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log;
#error_log  /var/log/nginx/error.log  notice;
#error_log  /var/log/nginx/error.log  info;

pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    # include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
    server {
        listen       89;
        server_name  localhost;

        #charset koi8-r;
        #access_log  /var/log/nginx/host.access.log  main;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        # redirect server error pages to the static page /40x.html
        #
        error_page  404              /404.html;
        location = /40x.html {
            root   /usr/share/nginx/html;
        }

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
        #
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        #
        #location ~ \.php$ {
        #    root           html;
        #    fastcgi_pass   127.0.0.1:9000;
        #    fastcgi_index  index.php;
        #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
        #    include        fastcgi_params;
        #}

        # deny access to .htaccess files, if Apache's document root
        # concurs with nginx's one
        #
        #location ~ /\.ht {
        #    deny  all;
        #}
    }

    #Another virtual host using mix of IP-, name-, and port-based configuration
    #
    #server {
    #    listen       8000;
    #    listen       somename:8080;
    #    server_name  somename  alias  another.alias;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}


    # HTTPS server
    #server {
    #    listen       443;
    #    server_name  localhost;

    #    ssl                  on;
    #    ssl_certificate      cert.pem;
    #    ssl_certificate_key  cert.key;

    #    ssl_session_timeout  5m;

    #    ssl_protocols  SSLv2 SSLv3 TLSv1;
    #    ssl_ciphers  HIGH:!aNULL:!MD5;
    #    ssl_prefer_server_ciphers   on;

    #    location / {
    #        root   html;
    #        index  index.html index.htm;
    #    }
    #}

}

service nginx restart

# redis
mkdir ~/installations -p
cd ~/installations
wget 'http://download.redis.io/releases/redis-2.8.3.tar.gz'
tar xvzf redis-2.8.3.tar.gz && cd redis-2.8.3
make
mkdir /etc/redis /var/lib/redis -p
cp src/redis-server src/redis-cli src/redis-sentinel /usr/local/bin -n
cp redis.conf /etc/redis -n

cat >/etc/init.d/redis-server << EOF
#!/bin/sh
#
# redis - this script starts and stops the redis-server daemon
#
# chkconfig:   - 85 15 
# description:  Redis is a persistent key-value database
# processname: redis-server
# config:      /etc/redis/redis.conf
# config:      /etc/sysconfig/redis
# pidfile:     /var/run/redis.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

redis="/usr/local/bin/redis-server"
prog=$(basename $redis)

REDIS_CONF_FILE="/etc/redis/redis.conf"

[ -f /etc/sysconfig/redis ] && . /etc/sysconfig/redis

lockfile=/var/lock/subsys/redis

start() {
    [ -x $redis ] || exit 5
    [ -f $REDIS_CONF_FILE ] || exit 6
    echo -n $"Starting $prog: "
    daemon $redis $REDIS_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}

restart() {
    stop
    start
}

reload() {
    echo -n $"Reloading $prog: "
    killproc $redis -HUP
    RETVAL=$?
    echo
}

force_reload() {
    restart
}

rh_status() {
    status $prog
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
	    ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload}"
        exit 2
esac
EOF
mkdir /etc/nginx/sites-enabled -p

chmod 755 /etc/init.d/redis-server
chkconfig --add redis-server
chkconfig --level 345 redis-server on
service redis-server start 2>&1 >/dev/null &


# -- user level
# rvm
sudo -u user_name -H bash -c "
source ~/.bash_profile
mkdir ~/installations && cd ~/installations
curl -L 'https://get.rvm.io' | bash -s stable
source ~/.bash_profile
rvm reload
rvm install ruby-2.0.0-p353
rvm use ruby-2.0.0-p353 --default
mkdir ~/.ssh -p
chmod 0700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
echo 'ssh-rsa key"

POST INSTALL NOTES:
  1. Link manually nginx configuration: 
    ln -s /opt/oiv-api/oiv-api_[ENVIRONMENT]/current/config/nginx_staging.conf /etc/nginx/sites-enabled/oiv-api
  2. Verify if your ruby version is default by 'rvm current'
