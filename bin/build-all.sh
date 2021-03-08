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

#-----do not change below content-----------------------
origin_path=`pwd`
project_path=$(cd `dirname $0`; pwd)

cd ${project_path}/../
#pull new code
git checkout master
git pull

bash ./bin/build-docker-img-agent.sh ${TAG} ${HUB}
bash ./bin/build-docker-img-server.sh ${TAG} ${HUB}

#keep origin dir
cd ${origin_path}