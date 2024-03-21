#!/bin/bash
. $(cd ${0%/*};pwd;)/../common.sh

tmpfileA=$(mktemp)
tmpfileB=$(mktemp)
cleanup() {
    rm -f $tmpfileA
    rm -f $tmpfileB
}
trap "cleanup; myexit" EXIT

comment="insmod is forbidden by default"
docker run \
    --runtime runq \
    --name $(rand_name) \
    --rm \
    -e RUNQ_CPU=2 \
   $image \
   sh -c "modprobe xfs"

checkrc $? 1 "$comment"

#
#
#
comment="insmod is allowed by '--cap-add sys_module'"
docker run \
    --runtime runq \
    --name $(rand_name) \
    --rm \
    --cap-add sys_module \
    -e RUNQ_CPU=2 \
    $image \
        sh -c "modprobe xfs"

checkrc $? 0 "$comment"

#
#
#
comment="mknod is allowed by default"
docker run \
    --runtime runq \
    --name $(rand_name) \
    --rm \
    -e RUNQ_CPU=2 \
    $image \
        sh -c "mknod -m 0600 /tmp/loop0 b 7 0"

checkrc $? 0 "$comment"

#
#
#
comment="mknod is forbidden by '--cap-drop mknod'"
docker run \
    --runtime runq \
    --name $(rand_name) \
    --rm \
    --cap-drop mknod \
    -e RUNQ_CPU=2 \
    $image \
        sh -c "mknod -m 0600 /tmp/loop0 b 7 0"

checkrc $? 1 "$comment"

#
#
#
comment="drop all capabilities"
docker run \
    --runtime runq \
    --name $(rand_name) \
    --rm \
    --cap-drop all \
    -e RUNQ_CPU=2 \
    $image \
        sh -c "grep -c '^Cap.*0000000000000000' /proc/self/status | xargs test 5 -eq "

checkrc $? 0 "$comment"

#
#
#
comment="capture capabilities from runc"
docker run \
    --runtime runc \
    --name $(rand_name) \
    --rm \
    -e RUNQ_CPU=2 \
    -v $tmpfileA:/results \
    --cap-drop sys_time \
    --cap-add sys_admin \
    $image \
    sh -c 'grep ^Cap /proc/$$/status >/results'

checkrc $? 0 "$comment"

#
#
comment="capture capabilities from runq"
docker run \
    --runtime runq \
    --name $(rand_name) \
    --rm \
    -e RUNQ_CPU=2 \
    -v $tmpfileB:/results \
    --cap-drop sys_time \
    --cap-add sys_admin \
    $image \
    sh -c 'grep ^Cap /proc/$$/status >/results'

checkrc $? 0 "$comment"

#
#
#
comment="runc and runq drop same capabilities"
diff $tmpfileA $tmpfileB
checkrc $? 0 "$comment"

