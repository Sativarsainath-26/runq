#!/bin/bash
. $(cd ${0%/*};pwd;)/../common.sh

image=docker:20.10-dind
port=$(rand_port)
name=$(rand_name)
disk=$PWD/disk$$
dd if=/dev/zero of=$disk bs=1M count=512 >/dev/null
mkfs.ext4 -F $disk

cleanup() {
    echo cleanup
    docker rm -f $name
    rm -f $disk
    myexit
}
trap cleanup EXIT

comment="Docker"
docker run \
    --runtime runq \
    -e RUNQ_CPU=2 \
    -e RUNQ_MEM=1024 \
    -e RUNQ_ROOTDISK=0001 \
    -p $port:2375 \
    --name $name \
    -d \
    --volume $disk:/dev/runq/0001/none/ext4 \
    --security-opt seccomp=unconfined \
    --cap-add net_admin \
    --cap-add sys_admin \
    --cap-add sys_module \
    --cap-add sys_resource \
    $image \
    dockerd \
        -s overlay2 \
        --host=tcp://0.0.0.0:2375

# wait for dind to show up
for ((i=1;i<30;i++)); do
    sleep 1
    echo "$i please wait ..."
    if docker -H tcp://localhost:$port ps &>/dev/null; then
        break
    fi
done

docker -H tcp://localhost:$port run alpine env
checkrc $? 0 "$comment"

