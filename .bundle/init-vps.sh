#!/bin/bash

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

CMD_INSTALL="yum install -y "

console() {
  echo -e "${1}${@:2}${PLAIN}"
}

resetTimezone() {
  console $GREEN "重置为中国时区"
  timezone=`timedatectl | cut -d: -f2 | sed -n 4p`
  console $GREEN "之前时区:$timezone"
  timedatectl set-timezone Asia/Shanghai
  timezone=`timedatectl | cut -d: -f2 | sed -n 4p`
  console $GREEN "当前时区:$timezone"
}

updateSystem() {
  console $GREEN "更新系统"
  yum update
  console $GREEN "安装 make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel libxslt-devel git tar vim unzip"
  $CMD_INSTALL make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel libxslt-devel git tar vim unzip
}

startFirewall() {
  # https://www.linode.com/docs/security/firewalls/introduction-to-firewalld-on-centos/
  console $GREEN "开启防火墙，打开 80/443 端口"
  systemctl start firewalld
  systemctl enable firewalld
  firewall-cmd --zone=public --add-service=http --permanent
  firewall-cmd --zone=public --add-service=https --permanent
  # firewall-cmd --zone=public --add-port=9055/tcp --permanent
  # firewall-cmd --zone=public --remove-port=18646/tcp --permanent
  # firewall-cmd --list-ports
  # firewall-cmd --state
  firewall-cmd --reload
}

cloneJSGardenSite() {
  console $GREEN "配置 JS 花园站点"
  mkdir /opt/site
  git clone https://github.com/xbf321/js-garden-page.git /opt/site/js-garden
}

installACME() {
  # https://github.com/acmesh-official/acme.sh/wiki/%E8%AF%B4%E6%98%8E
  console $GREEN "安装 ACME"
  cd ~
  curl -sL https://get.acme.sh | sh -s email=xbf321@gmail.com
  ~/.acme.sh/acme.sh  --upgrade  --auto-upgrade
}

installNginx() {
  console $GREEN "安装 Nginx ..."
  $CMD_INSTALL epel-release
  $CMD_INSTALL nginx
  if [[ "$?" != "0" ]]; then
    console $RED " Nginx安装失败，请手动安装"
    exit 1
  fi
  # 证书都放到这里
  mkdir /etc/nginx/ssl/
  systemctl enable nginx
  systemctl start nginx
}

installTrojanGo() {
  console $GREEN "安装 Trojan-Go ..."
  ZIP_FILE="trojan-go"
  wget -O /tmp/${ZIP_FILE}.zip https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.zip
  if [[ ! -f /tmp/${ZIP_FILE}.zip ]]; then
    console $RED "trojan-go安装文件下载失败，请检查网络或重试"
    exit 1
  fi
  mkdir -p /etc/trojan-go
  rm -rf /tmp/${ZIP_FILE}
  unzip /tmp/${ZIP_FILE}.zip  -d /tmp/${ZIP_FILE}
  cp /tmp/${ZIP_FILE}/trojan-go /usr/bin
  cp /tmp/${ZIP_FILE}/geoip.dat /etc/trojan-go/
  cp /tmp/${ZIP_FILE}/geosite.dat /etc/trojan-go/
  cp /tmp/${ZIP_FILE}/example/trojan-go.service /etc/systemd/system/
  sed -i '/User=nobody/d' /etc/systemd/system/trojan-go.service
  systemctl daemon-reload
  systemctl enable trojan-go
  rm -rf /tmp/${ZIP_FILE}
  console $YELLOW "trojan-go安装成功！"
}

installFrps() {
  console $GREEN "安装 Frp 服务端 ..."
  ZIP_FILE="frp"
  mkdir -p /tmp/frp
  mkdir -p /etc/frp
  wget -O /tmp/${ZIP_FILE}.tar.gz https://github.com/fatedier/frp/releases/download/v0.39.0/frp_0.39.0_linux_amd64.tar.gz
  if [[ ! -f /tmp/${ZIP_FILE}.tar.gz ]]; then
    console $RED "frp安装文件下载失败，请检查网络或重试"
    exit 1
  fi
  tar -xzvf /tmp/${ZIP_FILE}.tar.gz  --strip-components 1  -C /tmp/frp
  cp /tmp/frp/frps /usr/bin
  cp /tmp/frp/frps.ini /etc/frp/
  cp /tmp/frp/systemd/frps.service /etc/systemd/system/
  sed -i '/User=nobody/d' /etc/systemd/system/frps.service
  systemctl daemon-reload
  systemctl enable frps
  rm -rf /tmp/${ZIP_FILE}
  console $YELLOW "frps 安装成功！"
}

configFrps() {
  console $GREEN "配置 Frp 服务端 ..."
  cat > /etc/frp/frps.ini <<-EOF
[common]
bind_addr = 0.0.0.0
bind_port = 9000
bind_udp_port = 9001
kcp_bind_port = 9000

# auth token
token = da013ce4-2a80-4858-aacd-3af80d6cae46

# dashboard
dashboard_addr = 0.0.0.0
dashboard_port = 9500
dashboard_user = root
dashboard_pwd = sasasa

log_file = /var/log/frps.log
log_level = info
log_max_days = 3

# only allow frpc to bind ports you list, if you set nothing, there won't be any limit
allow_ports = 9000-9999

# pool_count in each proxy will change to max_pool_count if they exceed the maximum value
max_pool_count = 5

# max ports can be used for each client, default value is 0 means no limit
# if tcp stream multiplexing is used, default is true
tcp_mux = true
EOF
  systemctl restart frps
}

buildXingBaifangSSL() {
  console $GREEN "生成 xingbaifang.com 域名证书"
  export GD_Key="9ZhriYea41m_QeU73krAACuW4uALvMXizV"
  export GD_Secret="QeUC3cXBh7s6qcjjZsUeEV"
  ~/.acme.sh/acme.sh --issue --dns dns_gd -d xingbaifang.com -d www.xingbaifang.com
  ~/.acme.sh/acme.sh --issue --dns dns_gd -d tro-go.xingbaifang.com
  console $GREEN "安装 xingbaifang.com 域名证书到 Nginx SSL 目录下"
  ~/.acme.sh/acme.sh --installcert -d xingbaifang.com -d www.xingbaifang.com \
    --key-file /etc/nginx/ssl/xingbaifang.com.key \
    --fullchain-file /etc/nginx/ssl/xingbaifang.com.fullchain.cer
  ~/.acme.sh/acme.sh --installcert -d tro-go.xingbaifang.com \
    --key-file /etc/nginx/ssl/tro-go.xingbaifang.com.key \
    --fullchain-file /etc/nginx/ssl/tro-go.xingbaifang.com.fullchain.cer
}

buildXingshuoSSL() {
  console $GREEN "生成 xingshuo.me 域名证书"
  export GD_Key="9ZhriYea41m_2mYuxVjF49a8HD3YReFyEs"
  export GD_Secret="2mZ4FvZjGVXohUmLNczrLT"
  ~/.acme.sh/acme.sh --issue --dns dns_gd -d xingshuo.me -d www.xingshuo.me
  ~/.acme.sh/acme.sh --issue --dns dns_gd -d tro-go.xingshuo.me
  console $GREEN "安装 xingshuo.me 域名证书到 Nginx SSL 目录下"
  ~/.acme.sh/acme.sh --installcert -d xingshuo.me -d www.xingshuo.me \
    --key-file /etc/nginx/ssl/xingshuo.me.key \
    --fullchain-file /etc/nginx/ssl/xingshuo.me.fullchain.cer
  ~/.acme.sh/acme.sh --installcert -d tro-go.xingshuo.me \
    --key-file /etc/nginx/ssl/tro-go.xingshuo.me.key \
    --fullchain-file /etc/nginx/ssl/tro-go.xingshuo.me.fullchain.cer
}

configXingBaifangTrojan() {
  console $GREEN "配置 tro-go.xingbaifang.com"
  cat > /etc/trojan-go/config.json <<-EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 11443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [
    "d933afb4-7297-11ec-90d6-0242ac120003",
    "jm-c52e0ae2-89b7-4d9d-af9a-51902db13f32",
    "jl-cbc78a15-07b4-4514-81f8-f2cf86b99039",
    "xh-6f84cbed-153d-4eab-a5d8-2cf0e671e6bc"
  ],
  "ssl": {
    "cert": "/etc/nginx/ssl/tro-go.xingbaifang.com.fullchain.cer",
    "key": "/etc/nginx/ssl/tro-go.xingbaifang.com.key"
  },
  "mux": {
    "enabled": true,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": true,
    "block": [
        "geoip:private"
    ],
    "geoip": "/etc/trojan-go/geoip.dat",
    "geosite": "/etc/trojan-go/geosite.dat"
  }
}
EOF
}

configXingshuoTrojan() {
  console $GREEN "配置 tro-go.xingshuo.me"
  cat > /etc/trojan-go/config.json <<-EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 11443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [
    "d933afb4-7297-11ec-90d6-0242ac120003",
    "jm-c52e0ae2-89b7-4d9d-af9a-51902db13f32",
    "jl-cbc78a15-07b4-4514-81f8-f2cf86b99039",
    "xh-6f84cbed-153d-4eab-a5d8-2cf0e671e6bc"
  ],
  "ssl": {
    "cert": "/etc/nginx/ssl/tro-go.xingshuo.me.fullchain.cer",
    "key": "/etc/nginx/ssl/tro-go.xingshuo.me.key"
  },
  "mux": {
    "enabled": true,
    "concurrency": 8,
    "idle_timeout": 60
  },
  "router": {
    "enabled": true,
    "block": [
        "geoip:private"
    ],
    "geoip": "/etc/trojan-go/geoip.dat",
    "geosite": "/etc/trojan-go/geosite.dat"
  }
}
EOF
}

configXingBaifangNginx() {
  console $GREEN "配置 xingbaifang.com Nginx"
  cat > /etc/nginx/nginx.conf<<-EOF
  load_module /usr/lib64/nginx/modules/ngx_stream_module.so;
  user  root;
  worker_processes  auto;
  error_log  /var/log/nginx/error.log notice;
  pid        /var/run/nginx.pid;
  events {
    worker_connections  1024;
  }
  stream {
    map $ssl_preread_server_name $backend_name {
      tro-go.xingbaifang.com 127.0.0.1:11443;
      xingbaifang.com 127.0.0.1:10443;
    }
    server {
      listen 443 reuseport;
      listen [::]:443 reuseport;
      proxy_pass  $backend_name;
      ssl_preread on;
    }
  }
  http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml;
    gzip_vary on;
    # ssl common config
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE';
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Securit max-age=15768000;
    ssl_stapling on;
    ssl_stapling_verify on;
    server {
      listen       80;
      server_name  localhost;
      root /opt/site/js-garden;
      location / {
        index  index.html;
      }
    }
    include /etc/nginx/conf.d/*.conf;
  }
EOF
cat > /etc/nginx/conf.d/xingbaifang.com.conf<<-EOF
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=2r/s;
server {
  listen 80;
  server_name xingbaifang.com www.xingbaifang.com;
  return 301 https://$host$request_uri;
}
server {
  listen 10443 ssl http2;
  server_name xingbaifang.com www.xingbaifang.com;
  ssl_certificate      /etc/nginx/ssl/xingbaifang.com.fullchain.cer;
  ssl_certificate_key  /etc/nginx/ssl/xingbaifang.com.key;
  location / {
    proxy_pass http://xingshuo.me:9055;
    proxy_set_header HOST $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
  location /test {
    default_type text/html;
    return 200  "hello world! ";
  }
  client_max_body_size 1024m;
}
EOF
}

configXingshuoNginx() {
  console $GREEN "配置 xingshuo.me Nginx"
  cat > /etc/nginx/nginx.conf<<-EOF
  load_module /usr/lib64/nginx/modules/ngx_stream_module.so;
  user  root;
  worker_processes  auto;
  error_log  /var/log/nginx/error.log notice;
  pid        /var/run/nginx.pid;
  events {
    worker_connections  1024;
  }
  stream {
    map $ssl_preread_server_name $backend_name {
      tro-go.xingshuo.me 127.0.0.1:14443;
      x.xingshuo.me 127.0.0.1:13443;
      frp.xingshuo.me 127.0.0.1:12443;
      trojan.xingshuo.me 127.0.0.1:11443;
      xingshuo.me 127.0.0.1:10443;
    }
    server {
      listen 443 reuseport;
      listen [::]:443 reuseport;
      proxy_pass  $backend_name;
      ssl_preread on;
    }
  }
  http {
    include       mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  logs/access.log  main;
    sendfile        on;
    server_tokens   off;
    keepalive_timeout  65;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types text/plain application/x-javascript text/css application/xml;
    gzip_vary on;
    # ssl common config
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4:!DH:!DHE';
    ssl_prefer_server_ciphers on;
    add_header Strict-Transport-Securit max-age=15768000;
    ssl_stapling on;
    ssl_stapling_verify on;
    server {
      listen       80;
      server_name  localhost;
      root /opt/site/js-garden;
      location / {
        index  index.html;
      }
    }
    include /etc/nginx/conf.d/*.conf;
  }
EOF
cat > /etc/nginx/conf.d/xingshuo.me.conf<<-EOF
  limit_req_zone $binary_remote_addr zone=mylimit:10m rate=2r/s;
  server {
    listen 80;
    server_name xingshuo.me www.xingshuo.me;
    return 301 https://$host$request_uri;
  }
  server {
    listen 10443 ssl http2;
    server_name xingshuo.me www.xingshuo.me;
    root /opt/site/js-garden;
    ssl_certificate      /etc/nginx/ssl/xingshuo.me.fullchain.cer;
    ssl_certificate_key  /etc/nginx/ssl/xingshuo.me.key;
    location / {
      index index.html;
    }
    location /test {
      default_type text/html;
      return 200  "hello world! ";
    }
    # v2ray
    location /2dhcp {
      limit_req zone=mylimit burst=4 nodelay;
      proxy_redirect off;
      proxy_pass http://127.0.0.1:9527;
      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      # Show realip in v2ray access.log
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    client_max_body_size 50m;
  }
EOF
cat > /etc/nginx/conf.d/frp.xingshuo.me.conf<<-EOF
server {
  listen 80;
  server_name frp.xingshuo.me;
  return 301 https://$host$request_uri;
}
server {
  listen 12443 ssl http2;
  server_name frp.xingshuo.me;
  ssl_certificate      /etc/nginx/ssl/frp.xingshuo.me.fullchain.cer;
  ssl_certificate_key  /etc/nginx/ssl/frp.xingshuo.me.key;
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_redirect off;
    proxy_buffering off;
    proxy_pass http://127.0.0.1:9500;
  }
  client_max_body_size 50m;
}
EOF
cat > /etc/nginx/conf.d/wildcard.frp.xingshuo.me.conf<<-EOF
upstream printer {
  server 127.0.0.1:9011;
}
upstream router {
  server 127.0.0.1:9080;
}
upstream router-wq {
  server 127.0.0.1:9082;
}
upstream adguard {
  server 127.0.0.1:9043;
}
upstream adguard-wq {
  server 127.0.0.1:9044;
}
server {
  listen 80;
  server_name *.frp.xingshuo.me;
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_redirect off;
    proxy_buffering off;
    if ( $host ~* (.*)\.frp\.xingshuo\.me ) {
      set $prefix $1;
    }
    proxy_pass http://$prefix;
  }
  client_max_body_size 50m;
}
EOF
}

installBasePackage() {
  resetTimezone
  updateSystem
  startFirewall
  cloneJSGardenSite
  installNginx
  installACME
  installTrojanGo
  installFrps
}

menu() {
  clear
  echo "#############################################################"
  echo -e "  ${GREEN}1.${PLAIN}  安装基础服务(更新系统/Nginx/ACME/Trojan-Go/JSGardenSite/Frps)"
  echo -e "  ${GREEN}2.${PLAIN}  配置 frps"
  echo -e "  ${GREEN}3.${PLAIN}  安装 xingbaifang.com 证书且配置 Nginx 和 Trojan-Go"
  echo -e "  ${GREEN}4.${PLAIN}  安装 xingshuo.me 证书且配置 Nginx 和 Trojan-Go"
  echo -e "  ${GREEN}0.${PLAIN} 退出"
  echo "#############################################################"
  echo 

  read -p " 请选择操作[0-4]：" answer
  case $answer in
    0)
      exit 0
      ;;
    1)
      installBasePackage
      ;;
    2)
      configFrps
      ;;
    3)
      #buildXingBaifangSSL
      #configXingBaifangTrojan
      configXingBaifangNginx
      systemctl restart trojan-go
      nginx -s reload
      ;;
    4)
      buildXingshuoSSL
      configXingshuoTrojan
      configXingshuoNginx
      systemctl restart trojan-go
      nginx -s reload
      ;;
    *)
      echo -e "$RED 请选择正确的操作！${PLAIN}"
      exit 1
      ;;
  esac
}

action=$1
[[ -z $1 ]] && action=menu
case "$action" in
  menu)
    ${action}
    ;;
  *)
    echo " 参数错误"
    echo " 用法: `basename $0` [menu]"
    ;;
esac

