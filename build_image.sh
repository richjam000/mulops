#!/bin/bash
set -e
TAG="1.0"
IMAGE="gitlab.scsuk.net:5005/scsuk/mulops:$TAG"
set -x
docker build -t "$IMAGE" .
docker push "$IMAGE"
set +x

