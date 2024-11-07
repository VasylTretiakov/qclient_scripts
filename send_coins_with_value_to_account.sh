
#!/bin/bash

# Ensure version, account address and coin value arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Usage: $0 <qclient_version> <account_addr> <coin_value>"
  echo "e.g.: $0 2.0.1-testnet 0x16aaeb3c6366dfd7b2e989668415f7b62fa67bd43a23b1e068112c445e285200 0.002500000000"
  exit 1
fi

qclient_version=$1
account_addr=$2
coin_value=$3

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

# Get coins
coins=$(./qclient-$qclient_version-$release_os-$release_arch --signature-check=false token coins)

# For each coin address with requested value, send coin to account address
echo "$coins" | grep -F $coin_value | grep -oP '(?<=Coin\s)[0-9a-fx]+' | while read -r coin_addr; do
  echo "Transferring coin $coin_addr to $account_addr"
  ./qclient-$qclient_version-$release_os-$release_arch --signature-check=false token transfer "$account_addr" "$coin_addr"
done

