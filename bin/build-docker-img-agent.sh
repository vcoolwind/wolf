#!/bin/bash

TAG="$1"
HUB="$2"
if [ ! -n "${TAG}" ]; then
  echo "use default TAG"
  TAG=`git describe`"-"`date +%Y%m%d%H`
fi
if [ ! -n "${HUB}" ]; then
  echo "use default HUB"
  HUB="wolf"
fi

echo "BUILD TAG: ${TAG} HUB:${HUB}"

###------------------------------###
origin_path=`pwd`
project_path=$(cd `dirname $0`; pwd)
cd ${project_path}/../

target_img=yourdockerhub.com/${HUB}/wolf-agent
docker build -t ${target_img}:${TAG} -f ./agent/Dockerfile ./agent

## uncomment The following two lines when you need auto push
# docker login --username=xxxxxx yourdockerhub.com -p xxxxxx
# docker push ${target_img}:${TAG}

cd ${origin_path}