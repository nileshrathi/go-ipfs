#!/usr/bin/env bash

test_description="Test reprovider"

. lib/test-lib.sh

NUM_NODES=6

init() {
    test_expect_success 'init iptb' '
        iptb testbed create -type localipfs -force -count $NUM_NODES -init
    '

    test_expect_success 'peer ids' '
        PEERID_0=$(iptb attr get 0 id) &&
        PEERID_1=$(iptb attr get 1 id)
    '

    startup_cluster
    connect_cluster ${NUM_NODES}
}

findprovs_expect() {
    test_expect_success 'prepare expected succeeds' '
        echo '$2' > expected
    '
    test_expect_success 'findprovs '$1' succeeds' '
        ipfsi 1 dht findprovs -n 1 '$1' > findprovsOut
    '

    test_expect_success "findprovs $1 output looks good" '
        test_cmp findprovsOut expected
    '
}

# Test providing
init

test_expect_success 'prepare test files' '
    echo foo > f1 &&
    echo bar > f2
'

test_expect_success 'add test objects' '
    HASH_FOO=$(ipfsi 0 add -q f1)
    HASH_BAR=$(ipfsi 0 add --offline -q f2)
'

findprovs_expect '$HASH_FOO' '$PEERID_0'
# $HASH_BAR was added --offline, but the node is also running a daemon
# so the hash is provided anyway
findprovs_expect '$HASH_BAR' '$PEERID_0'

test_expect_success 'Stop iptb' '
    iptb stop
'

test_done
