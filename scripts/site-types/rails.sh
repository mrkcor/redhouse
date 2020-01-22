#!/usr/bin/env bash

block="server {
  listen 80;
  listen 443 ssl http2;
  server_name ${1};
  root \"$2\";

  ssl_certificate     /etc/nginx/ssl/$1.crt;
  ssl_certificate_key /etc/nginx/ssl/$1.key;

  location / {
    proxy_set_header    X-Real-IP \$remote_addr;
    proxy_set_header    X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header    X-Forwarded-Proto \$scheme;
    proxy_set_header    Host \$http_host;

    proxy_pass          http://0.0.0.0:${3};
  }
}
"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"
