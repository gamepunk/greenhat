#!/bin/bash
# ─────────────────────────────────────────────────────────
# GreenHat NFT — Set Tier Metadata URIs (IPFS mode)
# Usage: ./scripts/set_uris.sh <NFT_ADDRESS> <RPC_URL> <PRIVATE_KEY>
# ─────────────────────────────────────────────────────────
set -euo pipefail

NFT=$1
RPC=$2
PK=$3

echo "Setting IPFS metadata URIs..."
echo "NFT: $NFT"

# ── Upload assets/ to IPFS first, then get CID ──
# Example via Pinata CLI:
#   pinata upload assets/hats/
#   pinata upload assets/metadata/
# Then set CID here:
CID="__YOUR_IPFS_CID__"

declare -A TIERS
TIERS[1]="bronze"
TIERS[2]="silver"
TIERS[3]="gold"
TIERS[4]="diamond"

for TIER in 1 2 3 4; do
    NAME=${TIERS[$TIER]}
    URI="ipfs://$CID/metadata/$NAME.json"
    echo "  Tier $TIER ($NAME): $URI"
    cast send "$NFT" "setTierURI(uint8,string)" "$TIER" "$URI" \
        --rpc-url "$RPC" --private-key "$PK" > /dev/null
done

echo "✅ Done!"
