#!/bin/bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "Usage: $0 instance-name [command] [command-args..]"
    echo
    echo "  If no command is specified, a new container will be started"
    echo "  to which you will be provided ssh access."
    echo
    echo "  If you specify a command (and optionally command arguments)"
    echo "  a new container will be started and you will be dropped in"
    echo "  an interactive prompt."
}

container_info() {
    local IPADDRESS=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1)
    local MACADDRESS=$(docker inspect --format '{{ .NetworkSettings.MacAddress }}' $1)
    echo "Container info"
    echo "  name: $CONTAINER"
    echo "  ipaddress: $IPADDRESS"
    echo "  macaddress: $MACADDRESS"
    echo
    echo "To login to the container use:"
    echo "  ssh $IMAGE_USER@$IPADDRESS"
    echo
    echo "To stop the continery use:"
    echo "  docker rm -f $1"
    echo
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

if [ $UID -eq 0 ]; then
    echo "Error: running as root, run as a regular user"
    exit 1
fi

if [ ! -f "resources/image-name" ]; then
    echo "Error: unable to find resource folder."
    exit 1
fi

IMAGE_NAME=$(cat resources/image-name)
IMAGE_USER=$(cat resources/image-user)
INSTANCE=$1
CONTAINER="$IMAGE_NAME-$INSTANCE"
shift

docker inspect --format="{{ .State.Running  }}" $CONTAINER > /dev/null 2>&1

if [ $? -ne 1  ]; then
    echo "Error: $CONTAINER already exists"
    echo
    container_info $CONTAINER
    exit 3
fi

if [ "$#" -lt 1 ]; then
    OPTS="-d"
    EXTRA_PARAMS="/usr/bin/startup.sh"
else
    OPTS="--rm=true -ti"
    EXTRA_PARAMS="$*"
fi

docker run $OPTS --name $CONTAINER $IMAGE_NAME $EXTRA_PARAMS

if docker inspect --format '{{ .State.Running }}' $CONTAINER | grep false; then
    echo "Error: starting container failed"
    exit 1
fi

if [ "$#" -lt 1 ]; then
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R $(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $CONTAINER) 2> /dev/null
    container_info $CONTAINER
fi

exit 0
