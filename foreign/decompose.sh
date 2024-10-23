#!/bin/bash
IFS=$'\n'

number=${1:-0}

integer_part=${number%.*}
decimal_part=${number#*.}

tenxp() {
    x=$1
    echo -n 1
    for ((i=0; i<x; i++)); do
        echo -n 0
    done
}

tenxn() {
    x=$1
    echo -n 0.
    for ((i=-1; i>x; i--)); do
        echo -n 0
    done
    echo -n 1
}

# Positive exponents
length=${#integer_part}
for ((i = 0; i < $length; i++)); do
    digit=${integer_part:i:1}
    power=$((length - i - 1))
    col=$(tenxp $power)
    for ((j=0; j < digit; j++)); do
        echo $col
    done
done


# Negative exponents
length=${#decimal_part}
for ((i = 0; i < $length; i++)); do
    digit=${decimal_part:i:1}
    power=$((-(i + 1)))
    col=$(tenxn $power)
    for ((j=0; j<digit; j++)); do
        echo $col
    done
done
