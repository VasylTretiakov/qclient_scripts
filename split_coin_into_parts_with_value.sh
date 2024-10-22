
#!/bin/bash

# Ensure version, coin address, part and part value arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
  echo "Usage: $0 <qclient_version> <coin_addr> <parts> <part_value>"
  echo "e.g.: $0 2.0.1-testnet 0x0533c4c10d2246e4a9fead69e57fef2d6a5ab8fe112ddcd7986590affed09d20 2 0.002500000000"
  exit 1
fi

qclient_version=$1
coin_addr=$2
parts=$3
part_value=$4

max_parts=100

if [ $parts -gt $max_parts ]; then
  echo "Sorry, can't split into more than $max_parts parts"
  exit 2
fi

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

echo "Splitting coin $coin_addr into $parts parts of value $part_value"
./qclient-$qclient_version-$release_os-$release_arch --signature-check=false token split $coin_addr $(for i in $(seq 1 $parts); do echo -n "$part_value "; done)

