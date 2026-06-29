#!/bin/bash
# ─────────────────────────────────────────────────────────
# GreenHat NFT — Set Tier Metadata URIs (Data URI mode)
# No IPFS needed — embeds SVG directly as data URIs.
# Usage: ./scripts/set_data_uris.sh <NFT_ADDRESS> <RPC_URL> <PRIVATE_KEY>
# ─────────────────────────────────────────────────────────
set -euo pipefail

NFT=$1
RPC=$2
PK=$3

echo "Setting data URI metadata (no IPFS needed)..."

SvgEncode() {
    # base64 encode SVG, strip newlines for data URI
    echo -n "$1" | base64 -w0 | tr -d '\n'
}

JsonEncode() {
    local NAME="$1" DESC="$2" SVG_B64="$3"
    local JSON='{"name":"'"$NAME"'","description":"'"$DESC"'","image":"data:image/svg+xml;base64,'"$SVG_B64"'","attributes":[{"trait_type":"Tier","value":"'"$NAME"'"}]}'
    echo -n "$JSON" | base64 -w0 | tr -d '\n'
}

# ── Tier 1: Bronze ──
SVG1='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#CD7F32"/><stop offset="100%" stop-color="#8B5E3C"/></linearGradient></defs><rect width="300" height="300" fill="#1a1a2e" rx="20"/><ellipse cx="150" cy="180" rx="90" ry="30" fill="url(#g)"/><ellipse cx="150" cy="100" rx="70" ry="50" fill="url(#g)"/><rect x="60" y="175" width="180" height="12" rx="6" fill="url(#g)"/><rect x="80" y="130" width="140" height="10" rx="3" fill="#8B5E3C" opacity="0.8"/><text x="150" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="150" y="240" font-size="22" font-weight="bold" fill="#CD7F32" text-anchor="middle">Bronze GreenHat</text><text x="150" y="265" font-size="12" fill="#4CAF50" text-anchor="middle">🌿 GREEN</text></svg>'
B64_SVG1=$(SvgEncode "$SVG1")
URI1=$(JsonEncode "Bronze GreenHat" "A humble bronze hat for GREEN believers." "$B64_SVG1")
echo "  Setting Bronze..."
cast send "$NFT" "setTierURI(uint8,string)" 1 "data:application/json;base64,$URI1" --rpc-url "$RPC" --private-key "$PK" > /dev/null

# ── Tier 2: Silver ──
SVG2='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#C0C0C0"/><stop offset="100%" stop-color="#8C8C8C"/></linearGradient></defs><rect width="300" height="300" fill="#1a1a2e" rx="20"/><ellipse cx="150" cy="180" rx="90" ry="30" fill="url(#g)"/><ellipse cx="150" cy="100" rx="70" ry="50" fill="url(#g)"/><rect x="60" y="175" width="180" height="12" rx="6" fill="url(#g)"/><rect x="80" y="130" width="140" height="10" rx="3" fill="#8C8C8C" opacity="0.8"/><text x="135" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="165" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="150" y="240" font-size="22" font-weight="bold" fill="#C0C0C0" text-anchor="middle">Silver GreenHat</text><text x="150" y="265" font-size="12" fill="#4CAF50" text-anchor="middle">🌿 GREEN</text></svg>'
B64_SVG2=$(SvgEncode "$SVG2")
URI2=$(JsonEncode "Silver GreenHat" "A shiny silver hat for dedicated GREEN holders." "$B64_SVG2")
echo "  Setting Silver..."
cast send "$NFT" "setTierURI(uint8,string)" 2 "data:application/json;base64,$URI2" --rpc-url "$RPC" --private-key "$PK" > /dev/null

# ── Tier 3: Gold ──
SVG3='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#FFD700"/><stop offset="100%" stop-color="#DAA520"/></linearGradient></defs><rect width="300" height="300" fill="#1a1a2e" rx="20"/><ellipse cx="150" cy="180" rx="90" ry="30" fill="url(#g)"/><ellipse cx="150" cy="100" rx="70" ry="50" fill="url(#g)"/><rect x="60" y="175" width="180" height="12" rx="6" fill="url(#g)"/><rect x="80" y="130" width="140" height="10" rx="3" fill="#DAA520" opacity="0.8"/><text x="120" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="150" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="180" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="150" y="240" font-size="22" font-weight="bold" fill="#FFD700" text-anchor="middle">Gold GreenHat</text><text x="150" y="265" font-size="12" fill="#4CAF50" text-anchor="middle">🌿 GREEN</text></svg>'
B64_SVG3=$(SvgEncode "$SVG3")
URI3=$(JsonEncode "Gold GreenHat" "A glorious gold hat for elite GREEN supporters." "$B64_SVG3")
echo "  Setting Gold..."
cast send "$NFT" "setTierURI(uint8,string)" 3 "data:application/json;base64,$URI3" --rpc-url "$RPC" --private-key "$PK" > /dev/null

# ── Tier 4: Diamond ──
SVG4='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300"><defs><linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stop-color="#B9F2FF"/><stop offset="100%" stop-color="#00CED1"/></linearGradient></defs><rect width="300" height="300" fill="#1a1a2e" rx="20"/><ellipse cx="150" cy="180" rx="90" ry="30" fill="url(#g)"/><ellipse cx="150" cy="100" rx="70" ry="50" fill="url(#g)"/><rect x="60" y="175" width="180" height="12" rx="6" fill="url(#g)"/><rect x="80" y="130" width="140" height="10" rx="3" fill="#00CED1" opacity="0.8"/><text x="105" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="135" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="165" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="195" y="70" font-size="20" fill="#FFD700" text-anchor="middle">★</text><text x="150" y="240" font-size="22" font-weight="bold" fill="#B9F2FF" text-anchor="middle">Diamond GreenHat</text><text x="150" y="265" font-size="12" fill="#4CAF50" text-anchor="middle">🌿 GREEN</text></svg>'
B64_SVG4=$(SvgEncode "$SVG4")
URI4=$(JsonEncode "Diamond GreenHat" "The legendary diamond hat. Only the truest GREEN believers." "$B64_SVG4")
echo "  Setting Diamond..."
cast send "$NFT" "setTierURI(uint8,string)" 4 "data:application/json;base64,$URI4" --rpc-url "$RPC" --private-key "$PK" > /dev/null

echo ""
echo "✅ All tier URIS set! Users can now mint via:"
echo "  cast send $NFT 'mint()' --rpc-url $RPC --private-key <USER_KEY>"
