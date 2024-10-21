node () 
{ 
    ./node-2.0.1-b2-testnet-linux-amd64 --signature-check=false --network=1 $*
}
qclient () 
{ 
    ./qclient-2.0.1-b2-testnet-linux-amd64 --signature-check=false $* | fgrep -v "Signature check bypassed, be sure you know what you're doing"
}
