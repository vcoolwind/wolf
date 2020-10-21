#!/bin/bash

parse_json(){
  echo "${1//\"/}" | sed "s/.*$2:\([^,}]*\).*/\1/"
}

single_config(){
  echo "single_config--------->"
  if [ ! -n "${BACKEND_UPSTREAM}" ]; then
    BACKEND_UPSTREAM="http://127.0.0.1:10084"
  fi
  if [ ! -n "${RBAC_SERVER_URL}" ]; then
    RBAC_SERVER_URL="http://127.0.0.1:10080"
  fi
  if [ ! -n "${RBAC_APP_ID}" ]; then
    RBAC_APP_ID="unknown"
  fi
  if [ ! -n "${AGENT_PORT}" ]; then
    AGENT_PORT="10082"
  fi
  if [ ! -n "${UNAUTH_DIRECT}" ]; then
    UNAUTH_DIRECT="false"
  fi
  SERVER_NAME="localhost"
  sed -e "s|{BACKEND_UPSTREAM}|${BACKEND_UPSTREAM}|" \
    -e "s|{RBAC_SERVER_URL}|${RBAC_SERVER_URL}|" \
    -e "s|{RBAC_APP_ID}|${RBAC_APP_ID}|" \
    -e "s|{AGENT_PORT}|${AGENT_PORT}|" \
    -e "s|{SERVER_NAME}|${SERVER_NAME}|" \
    -e "s|{UNAUTH_DIRECT}|${UNAUTH_DIRECT}|" \
    -e "s|#EXTENSION_CONFIG|${EXTENSION_CONFIG}|" \
    conf/server-tmpl.conf \
  > /etc/nginx/conf.d/app-${RBAC_APP_ID}.conf
}

multiple_config(){
  echo "multiple_config--------->"
  if [ ! -n "${RBAC_SERVER_URL}" ]; then
    RBAC_SERVER_URL="http://127.0.0.1:10080"
  fi
  # generate multiple app conf
  #eg: {"AGENT_PORT":"10082","SERVER_NAME":"www.web1.com","BACKEND_UPSTREAM":"http://myapp1:8000","RBAC_APP_ID":"App-web1","UNAUTH_DIRECT":"true"}||{"AGENT_PORT":"10082","SERVER_NAME":"www.web2.com","BACKEND_UPSTREAM":"http://myapp2:8000","RBAC_APP_ID":"App-web2","UNAUTH_DIRECT":"false"}
  backends=(${MULTI_BACKEND//||/ })
  #echo ${backends}
  #echo "multiple--------->2"
  # shellcheck disable=SC2068
  for backend in ${backends[@]}
  do
      #echo ${backend}
      AGENT_PORT=$(parse_json ${backend} "AGENT_PORT")
      SERVER_NAME=$(parse_json ${backend} "SERVER_NAME")
      BACKEND_UPSTREAM=$(parse_json ${backend} "BACKEND_UPSTREAM")
      RBAC_APP_ID=$(parse_json ${backend} "RBAC_APP_ID")
      UNAUTH_DIRECT=$(parse_json ${backend} "UNAUTH_DIRECT")
      echo $AGENT_PORT $SERVER_NAME $BACKEND_UPSTREAM $RBAC_APP_ID $UNAUTH_DIRECT

      if [ ! -n "${AGENT_PORT}" ]; then
        AGENT_PORT="10082"
      fi
      if [ ! -n "${SERVER_NAME}" ]; then
        SERVER_NAME="localhost"
      fi
      if [ ! -n "${BACKEND_UPSTREAM}" ]; then
        BACKEND_UPSTREAM="http://127.0.0.1:10084"
      fi
      if [ ! -n "${RBAC_APP_ID}" ]; then
        RBAC_APP_ID="unknown"
      fi
      if [ ! -n "${UNAUTH_DIRECT}" ]; then
        UNAUTH_DIRECT="false"
      fi
      sed -e "s|{AGENT_PORT}|${AGENT_PORT}|" \
          -e "s|{SERVER_NAME}|${SERVER_NAME}|" \
          -e "s|{RBAC_SERVER_URL}|${RBAC_SERVER_URL}|" \
          -e "s|{BACKEND_UPSTREAM}|${BACKEND_UPSTREAM}|" \
          -e "s|{RBAC_APP_ID}|${RBAC_APP_ID}|" \
          -e "s|{UNAUTH_DIRECT}|${UNAUTH_DIRECT}|" \
          -e "s|#EXTENSION_CONFIG|${EXTENSION_CONFIG}|" \
          conf/server-tmpl.conf \
      > /etc/nginx/conf.d/app-${RBAC_APP_ID}.conf
  done
}

if [ ! -n "${RBAC_SERVER_URL}" ]; then
  RBAC_SERVER_URL="http://127.0.0.1:10080"
fi
if [ ! -n "${EXTENSION_CONFIG}" ]; then
  EXTENSION_CONFIG="#EXTENSION_CONFIG"
fi

if [ ! -n "${MULTI_BACKEND}" ]; then
  single_config
else
  multiple_config
fi

cp -f conf/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf

/usr/local/openresty/bin/openresty -g "daemon off;"