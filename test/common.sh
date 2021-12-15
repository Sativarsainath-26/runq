# vim:ft=sh

if [ -z "$RUNQ_ROOT" ]; then
    RUNQ_ROOT=/var/lib/runq
fi
runq_exec=$RUNQ_ROOT/runq-exec

image=alpine
rc_exit=0

uuid() {
    cat /proc/sys/kernel/random/uuid
}

rand_name() {
    printf "%s-%s" $(basename $0|sed 's/\.sh//') $(uuid | cut -c1-8)
}

rand_port() {
    read low high < /proc/sys/net/ipv4/ip_local_port_range
    while :;do
        local port=$(shuf -i $low-$high -n 1)
        ss -4tn | grep -q ":$port " || break
    done
    echo $port
}

checkrc() {
    local rc_given=$1
    local rc_want=$2
    local filename="$(basename $0)"
    local comment="$3"
    echo rc_want=$rc_want rc_given=$rc_given
    if [ $rc_given -eq $rc_want ]; then
        result=succeeded
    else
        result=failed
        ((rc_exit++))
    fi
    printf "test %-9s: %-19s : %s\n" $result $filename "$comment"
}

skip() {
    local filename="$(basename $0)"
    local comment="$1"
    printf "test skipped  : %-19s : %s\n" $filename "$comment"
    exit 0
}

skip_msg() {
    local filename="$(basename $0)"
    local comment="$1"
    local reason="$2"
    printf "test skipped  : %s [%s] : %s\n" $filename "$comment" "$reason"
}

myexit() {
    echo rc_exit=$rc_exit
    exit $rc_exit
}
