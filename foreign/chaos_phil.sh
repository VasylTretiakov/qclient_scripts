#!/bin/bash

#
# Chaotic Philanthropist
# - give it all away
# - double+ spend
# - send to self
# - runs forever
#
# I make a game of it. Each server tries to get
# balance to zero.
#

IFS=$'\n'
set -e
#set -x

#
# Send each local coins to these accounts, random order.
#
accounts='
0x19a925f14d102b9945c0bd20a6b5ec5b330f94f8f91085185f8eef89b550b43b
0x040281732a81e96626e12aa522bf643a79736c544ef6843a74eb31ca687592c8
0x04ff6eaf4061665b3c6b33de54de5c180b1578130199160ec4f7d8fd2c7a2908
0x16aaeb3c6366dfd7b2e989668415f7b62fa67bd43a23b1e068112c445e285299
'

main()
{
    balance
    while true; do
        chaos_phil
        balance
        sleep 1
    done
}

#
# Runs qclient in background, trying to go faster.
# Build coins linst once (dynamic), and try to send
# each coin to each account. This will double spend
# and send coins to self. Great! See what happens.
#
chaos_phil ()
{
    local bg=$1
    local txs=()
    for coin in $(coin_addrs)
    do
        for acct in $accounts
        do
            txs+=("$acct $coin")
        done
    done
    for pick in $(seqrand ${#txs[@]})
    do
        throttle
        token_transfer $(p12 ${txs[$((pick-1))]}) &
    done
    wait || true
}

balance()
{
    echo -n "$(date +%Y%m%d_%H%M%S) "
    qclient token balance
}

nproc=$(nproc)
trottle()
{
    local running=$(jobs -r)
    (( $running >= $nproc )) && wait -n
}

token_transfer()
{
    target_acct=$1
    send_coin=$2
    qclient token transfer $target_acct $send_coin
}

seqrand ()
{
    seq $* | sort -R
}

qclient ()
{
    ./qclient-2.0.1-b2-testnet-linux-amd64 --signature-check=false $* \
        | fgrep -v "Signature check bypassed, be sure you know what you're doing"
}

coin_addrs ()
{
    for line in $(qclient token coins);
    do
        echo $(p4 $line);
    done
}

p4 ()
{
    IFS=' ()'
    e4 $*
}

p12 ()
{
    IFS=' ()'
    e12 $*
}

e4 ()
{
    echo $4
}

e12 ()
{
    echo $1
    echo $2
}

main $*

