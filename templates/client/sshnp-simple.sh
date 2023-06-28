#!/bin/bash
#v1.0.0
BINARY_NAME="sshnp";
# -f = client atSign ("from")
# -t = device manager atSign ("to")
# -h = host rendezvous server atSign (SRS)
# -d = device name
eval "$HOME/.local/bin/$BINARY_NAME -f $1 -t $2 -h $3 -d $4";