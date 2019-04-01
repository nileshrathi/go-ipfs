#!/usr/bin/env bash

test_description="Test reprovider"

. lib/test-lib.sh

NUM_NODES=2

init_cluster() {
    test_expect_success "init iptb" "
        iptb testbed create -type localipfs -force -count $1 -init
    "

    for ((i=0; i<$1; i++));
    do
        test_expect_success "node id $i" "
            node$i=$(iptb attr get $i id)
        "
    done
}

start_node() {
    echo "iptb start -wait $1"
    test_expect_success "start up node $1" "
        iptb start -wait $1
    "
}

stop_node() {
    test_expect_success "stop node $1" "
        iptb stop $1
    "
}

add_data_to_node() {
    test_expect_success "generate test object" "
        head -c 256 </dev/urandom >object$1
    "

    test_expect_success "add test object" "
        hash$1=$(ipfsi $1 add -q "object$1")
    "
}

connect_peers() {
    test_expect_success "connect node $1 to node $2" "
        iptb connect $1 $2
    "
}

peer_id() {
    test_expect_success "peer id $1" "
        peer$1=$(iptb attr get $1 id)
    "
}

not_find_provs() {
    test_expect_success "findprovs "$2" succeeds" "
        ipfsi $1 dht findprovs -n 1 "$2" > findprovs_$2
    "

    test_expect_success "findprovs $2 output is empty" "
        test_must_be_empty findprovs_$2
    "
}

find_provs() {
    test_expect_success "prepare expected succeeds" "
        echo $3 > expected$1
    "

    test_expect_success "findprovs "$2" succeeds" "
        ipfsi $1 dht findprovs -n 1 "$2" > findprovs_$2
    "

    test_expect_success "findprovs $2 output looks good" "
        test_cmp findprovs_$2 expected$1
    "
}

has_no_peers() {
    test_expect_success "get peers for node 0" "
        ipfsi $1 swarm peers >swarm_peers_$1
    "

    test_expect_success "swarm_peers_$1 is empty" "
        test_must_be_empty swarm_peers_$1
    "
}

has_peer() {
    test_expect_success "prepare expected succeeds" "
        echo $2 > expected$1
    "

    test_expect_success "get peers for node $1" "
        ipfsi $1 swarm peers >swarm_peers_$1
    "

    test_expect_success "swarm_peers_$1 contains $2" "
        cat swarm_peers_$1 | grep $2
    "
}

reprovide() {
    test_expect_success "reprovide" "
        ipfsi $1 bitswap reprovide
    "
}

# Test providing roots

init_cluster ${NUM_NODES} # sets $nodeX

start_node 0
add_data_to_node 0 # sets $hash0
stop_node 0

start_node 1
not_find_provs 1 $hash0
start_node 0

has_no_peers 0
has_no_peers 1
connect_peers 0 1
has_peer 0 $node1
has_peer 1 $node0

reprovide 0

stop_node 0

find_provs 1 $hash0 $node0

stop_node 1

test_done

