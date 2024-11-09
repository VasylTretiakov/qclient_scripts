#!/bin/bash
IFS=$'\n'
set -e
#set -x

#
# Split coins down into one hundred milli coins.
# Or as close as we can given the 100 argument limit of qclient token split.
# So really it's 99 * 0.001 Quil coins, and another coin for remainder 
#

# Mine 0x1cd5b62ef0a5ef970ca7607c3428feccc73f80443ec896f9ad4ab02bc1121c1e
transfer_to_accounts=(
0x1e2a8152cf4d4af255ad58a07a92f74133853b880d19c3bc68ec0a01cc69213f
0x1a6c472f2404d749f0d50c8a88874fd9859f22d09afefc669a555f056dc2d70d
0x12140a4357a4d5452bf16eec609295cac2e4b5fc5e675285cd43150a94abfa69
)

main()
{
    local -A splitted=()
    local qclient_cmd_count=0
    local qclient_cmd_miss=0
    local coin coinv coina splits split_count remain split_values
    while true; do
        splits=0

        {
          date
          qclient token balance
          ./node-2.0.3-b3-testnet-linux-amd64 --signature-check=false -node-info
          echo "Coin count: $(qclient token coins | wc -l)"
	  echo
        } | tee -a millie.log

        for coin in $(qclient token coins | \grep -v  '^0\.001000000000 QUIL' | sort -nr); do
            # parse coin value and address
            coina=$(parse ' )' 4 $coin)

            # Splits take a while for me
            # Avoid duplicate splits
            # Wonder how many splits never take?
	    [[ ${splitted[$coina]} ]] && {
                echo -n "#"
                if (( ++splitted[$coina] > 55 )); then
                    # give up waiting for this command to execute, it missed
                    qclient_cmd_miss=$((qclient_cmd_miss+1))
                    unset splitted[$coina]
                else
                    continue
                fi
            }

            coinv=$(parse ' )' 1 $coin)

            # 0.001 coins are filtered out by grep for speed
            # But ignore any other smaller coins
            ! big_enough $coinv && echo -n '#' && chaos_phil $coina && continue

            # Just a flag to know when we're done
            splits=$((splits+1))

            splitted[$coina]=0

            split_values=''

            to_hot_form=$(denomination_breakdown $coinv)
            if [[ $to_hot_form ]]; then
                #echo "first split into hot form ,$to_hot_form,"
                split_values=$to_hot_form
            else
                # we can easily divide by 100, but dont go below 0.001
                if (( 1 == $(echo "scale=12; $coinv == 1.0" | bc) )); then
                    # optimize 1.0 --> 10*0.1 --> 100*0.001
                    split_values=$(rep 10 .1)
                elif big_enough_zero_point_one $coinv; then
                    #echo "divide by 100 while we can"
                    split_count=100
                    hundreth=$(echo "scale=3; $coinv / 100" | bc)
                    split_values=$(rep 100 $hundreth)
                else
                    #echo "down to millies as final step"
                    # Math for 100 argument split limit
                    split_count=$(coin_count $coinv)
                    remain=$(remaining_balance $coinv $split_count)
                    (( remain != 0 )) && errmsg "remain value should be zero"
                    split_values=$(rep $split_count 0.001)
                fi
            fi

            (( $(echo $split_values | wc -w) > 100 )) && errmsg "coin split limit too much"

            echo
            echo "Splitting $coinv $coina"
            echo qclient token split $coina $split_values

            throttle
            qclient token split $coina $split_values &
            qclient_cmd_count=$((qclient_cmd_count + 1))
        done
        echo
        echo "Waiting a bit for $splits splits to take. cmd=$qclient_cmd_count miss=$qclient_cmd_miss"
        wait || true
        #sleep 10
        # (( 0 == splits )) && break
        echo
        for coin in $(qclient token coins | \grep "^0\.001000000000 QUIL" | head -n 1000); do
            # parse coin address
            coina=$(parse ' )' 4 $coin)

            # 0.001 coins are filtered out by grep for speed
            # But ignore any other smaller coins
            chaos_phil $coina
        done
 
    done
    echo "All done"
}

qclient ()
{
    ./qclient-2.0.2.4-linux-amd64 --signature-check=false $* > >(\grep -v "Signature check bypassed, be sure you know what you're doing")
    local retval=$?
    wait
    return $retval
}

chaos_phil()
{
  local coina=$1
  local target=${transfer_to_accounts[$(( RANDOM % ${#transfer_to_accounts[@]} ))]}
  throttle
  qclient token transfer $target $coina &
  echo qclient token transfer $target $coina
}
 
joblimit=$(($(nproc)/4 + 1))
echo "joblimit $joblimit"
throttle()
{
    local running=$(jobs -r | wc -l)
    (( $running < $joblimit )) || (echo .; wait -n) || true
}


big_enough()
{
    local coinv=$1
    (( 1 == $(echo "scale=15; $coinv > 0.001" | bc) ))
}

big_enough_zero_point_one()
{
    local value=$1
    (( 1 == $(echo "scale=15; $value >= 0.1" | bc) ))
}

coin_count()
{
    local coinv=$1
    count=$(echo "scale=0; x = $coinv / 0.001; if (x > 99) 99 else x / 1" | bc)
    echo $count
}

remaining_balance()
{
    local coinv=$1
    local count=$2
    big_enough $coinv || errmsg "coin split limit"
    remain=$(echo "scale=15; $coinv - $count * 0.001" | bc)
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
    local i
    for ((i=0; i < $count; i++)); do
        echo $str
    done
}

#
# Given a number, return a series of standard-value numbers that sum to original.
# But not smaller than milli.
# And not more that a hundred in the series? Nope... I have hope it will work.
#
denomination_breakdown()
{
    local number=$1
    
    local integer_part=${number%.*}
    local decimal_part=${number#*.}

    local decimal_milli=${decimal_part:0:3}
    local decimal_residual=${decimal_part:3}

    # Return nothing if form is already good
    is_one_hot_form $integer_part$decimal_part && return

    # Return nothing if number too small
    # Zeros all the way down to milli place
    [[ $integer_part$decimal_milli =~ '^0*$' ]] && return

    local i length digit power col
 
    # Positive exponents
    length=${#integer_part}
    for ((i = 0; i < $length; i++)); do
        digit=${integer_part:i:1}
        power=$((length - i - 1))
        col=$(tenxp $power)
        rep $digit $col
    done
    
    # Negative exponents
    length=${#decimal_milli}
    for ((i = 0; i < $length; i++)); do
        digit=${decimal_milli:i:1}
        power=$((-(i + 1)))
        col=$(tenxn $power)
        rep $digit $col
    done

    (( decimal_residual == 0 )) || echo 0.000$decimal_residual
}

#
# 1000000 00010000 000001 or 000000, with any number of zeros but at most one 1
#
is_one_hot_form()
{
    local numstr=$1
    [[ $numstr =~ ^0*1?0*$ ]]
}

tenxp()
{
    local i
    local x=$1
    echo -n 1
    for ((i=0; i<x; i++)); do
        echo -n 0
    done
}

tenxn()
{
    local i
    local x=$1
    echo -n 0.
    for ((i=-1; i>x; i--)); do
        echo -n 0
    done
    echo -n 1
}



errmsg() { >&2 echo Error: $*; exit 1; }


main
