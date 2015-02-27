#!/bin/bash

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $UID -eq 0 ]; then
  echo "Error: running as root, pleas run as a regular user."
  exit 1
fi

KERNEL_VERSION=$(uname -r | awk -F. '{printf("%d%03d", $1, $2)}')
if [ $KERNEL_VERSION -lt 3008 ]; then
    echo "Warning: You are using a kernel older than 3.8!!"
    echo "         for docker to function properly, you should have kernel 3.8 or higher"
    echo "         the building process may fail."
    echo
    echo "         press Ctrl-C to abort, press enter to continue..."
    read
fi

if ! hash docker >/dev/null; then
    echo "Error: docker not found. Please install it first."
    echo
    echo "   instructions at https://docs.docker.com/installation/"
    echo
    exit 1
fi

if ! id | grep docker >/dev/null; then
    echo "Error: $USER is not in the docker group." 
    echo
    echo "  To add yourself to a docker group:"
    echo
    echo "   sudo usermod -a -G docker $USER"
    echo
    exit 1
fi

if [ ! -f "resources/image-name" ]; then
    echo "Error: unable to find resource folder."
    exit 1
fi

IMAGE=$(cat resources/image-name)

nvidia_version=$(cat /proc/driver/nvidia/version | head -n 1 | awk '{ print $8 }')

if [ -z $nvidia_version ]; then
    echo "Must be run on linux with nvidia hardware!"
    exit 3
else
    video_driver_uri=http://us.download.nvidia.com/XFree86/Linux-x86_64/${nvidia_version}/NVIDIA-Linux-x86_64-${nvidia_version}.run
    video_driver_run_cmd="exec sh /tmp/video-driver-pkg -a -N --ui=none --no-kernel-module"
fi

if [ ! -f resources/video-driver-pkg  ]; then
    if ! hash curl >/dev/null; then
        echo "Error: curl not found. Please install it first"
        echo
        exit 1
    fi
    curl -o resources/video-driver-pkg $video_driver_uri
fi

if [ ! -f resources/video-driver-install ]; then
    echo $video_driver_run_cmd > resources/video-driver-install
    chmod 755 resources/video-driver-install
fi


echo "building $IMAGE image ..."
sudo docker build --rm=true -t $IMAGE $* .

echo $0 done.
