#!/bin/bash
IFS=$'\n'
set -e
#set -x

#
# Split coins down into one hundred milli coins.
# Or as close as we can given the 100 argument limit of qclient token split.
# So really it's 99 * 0.001 Quil coins, and another coin for remainder 
#

# Main 0x1cd5b62ef0a5ef970ca7607c3428feccc73f80443ec896f9ad4ab02bc1121c1e
transfer_to_accounts=(
0x1e2a8152cf4d4af255ad58a07a92f74133853b880d19c3bc68ec0a01cc69213f
0x1a6c472f2404d749f0d50c8a88874fd9859f22d09afefc669a555f056dc2d70d
0x12140a4357a4d5452bf16eec609295cac2e4b5fc5e675285cd43150a94abfa69
)

main()
{
    local -A seen=()

    local i=0
    while qclient token balance; do
        local cmd_count=0
        local skipped=0 
        local nnl=0
        SECONDS=0
        for coin in $(qclient token coins | \fgrep '0.00'); do
            # parse coin address
            coina=$(parse ' )' 4 $coin)

	    [[ ${seen[$coina]} ]] && {
                skipped=$((skipped+1))
                nnl=1
                echo -n .
                continue
            }
            seen[$coina]=$i

            (( nnl == 0 )) || {
                echo
                nnl=0
            }

            # 0.001 coins are filtered out by grep for speed
            # But ignore any other smaller coins
            chaos_phil $coina
            cmd_count=$((cmd_count+1))
        done
        i=$((i+1)) 
        (( nnl == 0 )) || {
            echo
            nnl=0
        }
        echo "cmd_cout: $cmd_count, skipped: $skipped, seconds: $SECONDS, $(date)"
        tail -n 12 millie.log
        sleep 10
        echo
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

errmsg() { >&2 echo Error: $*; exit 1; }

main
