#!/bin/bash
IFS=$'\n'
set -e
#set -x

#
# Split coins down into one hundred milli coins.
# Or as close as we can given the 100 argument limit of qclient token split.
# So really it's 99 * 0.001 Quil coins, and another coin for remainder 
#

MILLI=0.001

main()
{
    local -A splitted=()
    while true; do
        local splits=0
        for coin in $(qclient token coins | sort -n); do
            # parse coin value and address
            local coinv=$(parse ' )' 1 $coin)
            local coina=$(parse ' )' 4 $coin)

            # 0.001 coins are filtered out by grep for speed
            # But ignore any other smaller coins
            ! big_enough $coinv && echo -n '#' && continue

            # Just a flag to know when we're done
            splits=$((splits+1))

            # Splits take a while for me
            # Avoid duplicate splits
            # Wonder how many splits never take?
	    [[ ${splitted[$coina]} ]] && echo "Wainting for $coinv $coina to split." && continue
            splitted[$coina]=x

            # Math for 100 argument split limit
            local split_count=$(coin_count $coinv)
            local remain=$(remaining_balance $coinv $split_count)

            #echo
            echo "Splitting $coinv $coina"
            #echo qclient token split $coina $remain $(rep 99 $MILLI)

            qclient token split $coina $remain $(rep 99 $MILLI)
        done
        (( 0 == splits )) && break
        echo
        echo "Waiting a bit for $splits splits to take."
        sleep 10
    done
    echo "All done"
}

qclient ()
{
    ./qclient-2.0.2.4-linux-amd64 --signature-check=false $* > >(\grep -v -E "(Signature check bypassed, be sure you know what you're doing|0\.001000000000 QUIL)")
    local retval=$?
    wait
    return $retval
}

big_enough()
{
    local coinv=$1
    (( 1 == $(echo "scale=15; $coinv > $MILLI" | bc) ))
}

coin_count()
{
    local coinv=$1
    count=$(echo "scale=0; x = $coinv / $MILLI; if (x > 99) 99 else x / 1" | bc)
    echo $count
}

remaining_balance()
{
    local coinv=$1
    local count=$2
    big_enough $coinv || errmsg "Error: coin split limit"
    remain=$(echo "scale=15; $coinv - $count * $MILLI" | bc)
    echo $remain    
}

parse()
{
    IFS=$1
    local col=$(( $2 - 1 ))
    shift 2
    local a=($*)
    echo ${a[$col]}
}

rep()
{
    local count=$1
    local str=$2
    for ((i=0; i < $count; i++)); do
        echo $str
    done
}

errmsg() { >&2 echo Error: $*; exit 1; }

main
