#!/bin/bash

cp /usr/local/openresty/lualib/cjson.so ./
luajit entrypoint.lua

cp -f conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

/usr/local/openresty/bin/openresty -g "daemon off;"