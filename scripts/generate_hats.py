#!/usr/bin/env python3
"""
GreenHat 🧢 — NFT Hat SVG Generator

Generates 4 tier-based hat SVG images and metadata JSON files.
No artist needed, just code.

Usage:
    python3 scripts/generate_hats.py

Output:
    assets/hats/{bronze,silver,gold,diamond}.svg
    assets/metadata/{bronze,silver,gold,diamond}.json
"""

import os

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "..", "assets")
SVG_DIR = os.path.join(ASSETS_DIR, "hats")
META_DIR = os.path.join(ASSETS_DIR, "metadata")

TIERS = {
    "bronze": {
        "name": "Bronze GreenHat",
        "description": "A humble bronze hat for GREEN believers.",
        "color": "#CD7F32",
        "accent": "#8B5E3C",
        "stars": 1,
    },
    "silver": {
        "name": "Silver GreenHat",
        "description": "A shiny silver hat for dedicated GREEN holders.",
        "color": "#C0C0C0",
        "accent": "#8C8C8C",
        "stars": 2,
    },
    "gold": {
        "name": "Gold GreenHat",
        "description": "A glorious gold hat for elite GREEN supporters.",
        "color": "#FFD700",
        "accent": "#DAA520",
        "stars": 3,
    },
    "diamond": {
        "name": "Diamond GreenHat",
        "description": "The legendary diamond hat. Only the truest GREEN believers.",
        "color": "#B9F2FF",
        "accent": "#00CED1",
        "stars": 4,
    },
}


def generate_svg(tier: str, info: dict) -> str:
    """Generate an SVG hat image for the given tier."""
    c = info["color"]
    a = info["accent"]
    stars = "".join(
        f'<text x="{120 + i * 30}" y="70" font-size="20" text-anchor="middle">★</text>'
        for i in range(info["stars"])
    )

    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300" width="300" height="300">
  <defs>
    <linearGradient id="grad_{tier}" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:{c};stop-opacity:1" />
      <stop offset="100%" style="stop-color:{a};stop-opacity:1" />
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="300" height="300" fill="#1a1a2e" rx="20"/>

  <!-- Hat Body (bucket hat shape) -->
  <ellipse cx="150" cy="180" rx="90" ry="30" fill="url(#grad_{tier})" />

  <!-- Hat Top -->
  <ellipse cx="150" cy="100" rx="70" ry="50" fill="url(#grad_{tier})" />

  <!-- Hat Brim -->
  <rect x="60" y="175" width="180" height="12" rx="6" fill="url(#grad_{tier})" />

  <!-- Hat Band -->
  <rect x="80" y="130" width="140" height="10" rx="3" fill="{a}" opacity="0.8" />

  <!-- Stars (rarity indicator) -->
  {stars}

  <!-- Tier Label -->
  <text x="150" y="240" font-size="22" font-family="Arial, sans-serif"
        font-weight="bold" fill="{c}" text-anchor="middle">
    {info["name"]}
  </text>

  <!-- GREEN Badge -->
  <text x="150" y="265" font-size="12" font-family="Arial, sans-serif"
        fill="#4CAF50" text-anchor="middle">
    🌿 GREEN
  </text>
</svg>"""


def generate_metadata(tier: str, info: dict) -> dict:
    """Generate metadata JSON for OpenSea / standard NFT marketplace."""
    return {
        "name": info["name"],
        "description": info["description"],
        "image": f"ipfs://__CID__/hats/{tier}.svg",
        "attributes": [
            {"trait_type": "Tier", "value": tier.capitalize()},
            {"trait_type": "Rarity", "value": str(info["stars"]) + "/4"},
            {"trait_type": "Color", "value": info["color"]},
            {"trait_type": "Collection", "value": "GreenHat Hats"},
        ],
    }


def main():
    os.makedirs(SVG_DIR, exist_ok=True)
    os.makedirs(META_DIR, exist_ok=True)

    for tier, info in TIERS.items():
        # SVG
        svg_path = os.path.join(SVG_DIR, f"{tier}.svg")
        with open(svg_path, "w") as f:
            f.write(generate_svg(tier, info))
        print(f"✅  Generated: {svg_path}")

        # Metadata
        meta_path = os.path.join(META_DIR, f"{tier}.json")
        import json
        with open(meta_path, "w") as f:
            json.dump(generate_metadata(tier, info), f, indent=2)
        print(f"✅  Generated: {meta_path}")

    print()
    print("🎉 All hats generated!")
    print()
    print("📤 Next steps:")
    print("   1. Upload assets/ to IPFS (e.g. via Pinata, web3.storage, or local CLI)")
    print("   2. Get the CID (e.g. QmXyZ...)")
    print("   3. Call contract:")
    print('      nft.setTierURI(Tier.Bronze, "ipfs://CID/metadata/bronze.json")')
    print('      nft.setTierURI(Tier.Silver, "ipfs://CID/metadata/silver.json")')
    print('      nft.setTierURI(Tier.Gold,   "ipfs://CID/metadata/gold.json")')
    print('      nft.setTierURI(Tier.Diamond,"ipfs://CID/metadata/diamond.json")')
    print()
    print("⚡ Quick test (no IPFS needed):")
    print("   Set URIs to 'data:application/json;base64,...' with base64-encoded metadata")
    print("   See scripts/deploy_with_data_uri.py for details")


if __name__ == "__main__":
    main()
