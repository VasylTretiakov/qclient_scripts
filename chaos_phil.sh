#!/bin/bash
IFS=$'\n'
set -e
#set -x

#
# Send each local coins to these accounts, random order.
#
accounts='
0x00e9b9c94206fffdf18bfd0189c369ebe844d4a0980c980ee21fcff6753f64d8
0x02d8b848988a61b8bc0e3e0de127a85f66d85ee35bc20241d77e9ac0c3a3cae7
0x22ba7a92caca45e0f0154c942253219bd1a6aaba42d5c0cac0c292bb0a0dd957
'

main()
{
    local bg=${1:-24}
    balance
    while true; do
        chaos_phil $bg
        balance
        sleep 1
    done
}

#
# Chaotic Philanthropist
# - give it all away
# - double+ spend
#
# Runs qclient in background, trying to go faster.
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
        throttle $bg
        token_transfer $(p12 ${txs[$((pick-1))]}) &
    done
    wait || true
}

balance()
{
        echo -n "$(date +%Y%m%d_%H%M%S) "
        qclient token balance
}

throttle()
{
    local limit=$1
    local running=$(jobs -r | wc -l)
    if (( limit <= running ))
    then
        wait -n || true
    fi
}

token_transfer()
{
    target_acct=$1
    send_coin=$2
    #echo qclient token transfer $target_acct $send_coin
    qclient token transfer $target_acct $send_coin
    #sleep $((RANDOM % 5 + 3))
}

seqrand ()
{
    seq $* | sort -R
}

qclient ()
{
    ./qclient-2.0.1-testnet-linux-amd64 --signature-check=false $* \
        | fgrep -v "Signature check bypassed, be sure you know what you're doing"
}

coin_addrs ()
{
    local coin
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

