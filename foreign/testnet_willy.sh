!/bin/bash
IFS=$'\n'
set -e
set -x

# check for running node process
t=$(mktemp)
ps x > $t
grep -q 'node-*' $t && echo Error: node running && exit 1

# clean folder
[[ $(basename $(pwd)) = "testnet" ]] || {
  mkdir -p testnet
  cd testnet
}

# download binaries
curl -O https://releases.quilibrium.com/qclient-2.0.1-b3-testnet-linux-amd64
curl -O https://releases.quilibrium.com/node-2.0.1-b3-testnet-linux-amd64
chmod +x *-linux-amd64

# shortcuts
testnet-node() { ./node-2.0.1-b3-testnet-linux-amd64 --signature-check=false --network=1 $*; }
testnet-qclient() {
   ./qclient-2.0.1-b3-testnet-linux-amd64 --signature-check=false $* \
     | fgrep -v "Signature check bypassed, be sure you know what you're doing"
}

# .config/ folder is needed
[[ -d .config ]] || {
  # This command fails to start a node, but it does create a .config/ tree
  testnet-node || true

  # Update config.yml settings
  sedscript='
    s| listenMultiaddr: .*| listenMultiaddr: /ip4/0.0.0.0/tcp/8336|;
    s|listenGrpcMultiaddr: .*|listenGrpcMultiaddr: /ip4/127.0.0.1/tcp/8337|;
    s|listenRESTMultiaddr: .*|listenRESTMultiaddr: /ip4/127.0.0.1/tcp/8338|;
    /  - /d;
    /bootstrapPeers:/a\  - /ip4/91.242.214.79/udp/8336/quic-v1/p2p/QmNSGavG2DfJwGpHmzKjVmTD6CVSyJsUFTXsW4JXt2eySR
  '
  sed -i "$sedscript" .config/config.yml
}

# now node should run
testnet-node
