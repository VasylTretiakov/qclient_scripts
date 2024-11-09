#!/bin/bash

# Ensure version argument is provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <qclient_version>"
  echo "e.g.: $0 2.0.1-testnet"
  exit 1
fi

qclient_version=$1

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    release_os="linux"
    if [[ $(uname -m) == "aarch64"* ]]; then
        release_arch="arm64"
    else
        release_arch="amd64"
    fi
else
    release_os="darwin"
    release_arch="arm64"
fi

echo "Searching for coins"

# Get coins
coins=$(./qclient-$qclient_version-$release_os-$release_arch --signature-check=false token coins)

# Join coin addresses into space-separated string
coin_addrs=$(echo "$coins" | grep -oP '(?<=Coin\s)[0-9a-fx]+' | tr '\n' ' ')

# Exit if no coin addresses were found
if [[ -z "$coin_addrs" ]]; then
  echo "Sorry, no coins were found"
  exit 1
fi

echo "Merging coins: $coin_addrs"

# Merge coins
./qclient-$qclient_version-$release_os-$release_arch --signature-check=false token merge $coin_addrs
