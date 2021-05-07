#!/bin/bash

platform=$1

docker image prune -a -f
docker pull quay.io/prabhav/che-theia-dev:next
docker tag quay.io/prabhav/che-theia-dev:next prabhav/che-theia-dev:next
./build.sh --root-yarn-opts:--ignore-scripts --dockerfile:Dockerfile.${platform}