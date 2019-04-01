#!/usr/bin/env bash

test_description="Test reprovider"

. lib/test-lib.sh

NUM_NODES=6

init_cluster() {
    test_expect_success 'init iptb' '
        iptb testbed create -type localipfs -force -count $NUM_NODES -init
    '

    test_expect_success 'peer ids' '
        PEERID_0=$(iptb attr get 0 id) &&
        PEERID_1=$(iptb attr get 1 id)
    '
}

findprovs_empty() {
    test_expect_success 'findprovs '$1' succeeds' '
        ipfsi 1 dht findprovs -n 1 '$1' > findprovsOut
    '

    test_expect_success 'findprovs $1 output is empty' '
        test_must_be_empty findprovsOut
    '
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

reprovide() {
    test_expect_success 'reprovide' '
        ipfsi 0 bitswap reprovide
    '
}

# Test providing roots
test_expect_success 'prepare test files' '
    echo foo > f1 &&
    echo bar > f2
'

test_expect_success 'init iptb' '
    iptb testbed create -type localipfs -force -count $NUM_NODES -init
'

test_expect_success 'peer ids' '
    PEERID_0=$(iptb attr get 0 id) &&
    PEERID_1=$(iptb attr get 1 id)
'

test_expect_success 'add test objects' '
    HASH_FOO=$(ipfsi 0 add -q f1)
    HASH_BAR=$(ipfsi 0 add --offline -q f2)
'

test_expect_success "start up node 0" '
    iptb start -wait 0
'

test_expect_success "start up node 1" '
    iptb start -wait 1
'

test_expect_success 'findprovs '$HASH_FOO' succeeds' '
    ipfsi 1 dht findprovs -n 1 '$HASH_FOO' > findprovsOut
'

test_expect_success 'findprovs $HASH_FOO output is empty' '
    test_must_be_empty findprovsOut
'

test_expect_success "connect node 1 to node 0" '
    iptb connect 0 1
'

test_expect_success 'prepare expected succeeds' '
    echo '$PEERID_0' > expected
'

test_expect_success 'findprovs '$HASH_FOO' succeeds' '
    ipfsi 1 dht findprovs -n 1 '$HASH_FOO' > findprovsOut
'

test_expect_success "findprovs $HASH_FOO output looks good" '
    test_cmp findprovsOut expected
'

test_expect_success 'stop node 0' '
    iptb stop 0
'
test_expect_success "stop node 1" '
    iptb stop 1
'

test_done

