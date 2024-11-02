#!/bin/bash
IFS=$'\n'

#
# Download Quilibrium testnet binaries (for -linux-amd64) to current
# folder and run a node.
#
# Existing .config/ folders will used as-is, otherwise a new .config/
# tree will be created and configured.
#

#
# Shortcut functions.
# You can type ". testnet_willy.sh" at Bash prompt to expose these shortcuts
#
testnet-node() { ./node-2.0.3-testnet-linux-amd64 --signature-check=false --network=1 $*; }
testnet-qclient ()
{
    ./qclient-2.0.2.4-linux-amd64 --signature-check=false $* > >(\grep -v "Signature check bypassed, be sure you know what you're doing")
    local retval=$?
    wait
    return $retval
}

# Wierd bash script vs source test.
[[ $(basename -- $0) != "testnet_willy.sh" ]] && echo 'Shortcuts defined.' && return

errmsg() { >&2 echo Error: $*; exit 1; }

set -e
set -x

## check for running node process
[[ $(ps fax | grep -f <(echo node)) ]] && errmsg 'Node already running.'

# download binaries always, they can change
curl -O https://releases.quilibrium.com/node-2.0.3-testnet-linux-amd64
curl -O https://releases.quilibrium.com/qclient-2.0.2.4-linux-amd64
chmod +x *-linux-amd64

# .config/ folder is needed
! [[ -d .config ]] && {
  # This command fails to start a node, but it does create a .config/ tree
  testnet-node || true

  # Update config.yml settings
  sedscript='
    s|^  listenMultiaddr: .*|  listenMultiaddr: /ip4/0.0.0.0/tcp/8336|
    s|^listenGrpcMultiaddr: .*|listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337|
    s|^listenRESTMultiaddr: .*|listenRESTMultiaddr: /ip4/127.0.0.1/tcp/8338|
    /  - /d
    /bootstrapPeers:/a\  - /ip4/91.242.214.79/udp/8336/quic-v1/p2p/QmNSGavG2DfJwGpHmzKjVmTD6CVSyJsUFTXsW4JXt2eySR
  '
  sed -i "$sedscript" .config/config.yml
}
! grep -q QmNSGavG2DfJwGpHmzKjVmTD6CVSyJsUFTXsW4JXt2eySR .config/config.yml && errmsg 'Error: .config/config.yml needs testnet bootstrap.'

# now node should run
testnet-node
