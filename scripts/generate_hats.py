#!/usr/bin/env python3
"""
GreenHat 🧢 — NFT Hat SVG Generator

Generates 4 tier-based hat SVG images and metadata JSON files.
Uses the official GreenHat hat design with tier-specific colors.

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
        "shadow": "#8B5E3C",
        "stars": 1,
    },
    "silver": {
        "name": "Silver GreenHat",
        "description": "A shiny silver hat for dedicated GREEN holders.",
        "color": "#C0C0C0",
        "shadow": "#707070",
        "stars": 2,
    },
    "gold": {
        "name": "Gold GreenHat",
        "description": "A glorious gold hat for elite GREEN supporters.",
        "color": "#FFD700",
        "shadow": "#B8860B",
        "stars": 3,
    },
    "diamond": {
        "name": "Diamond GreenHat",
        "description": "The legendary diamond hat. Only the truest GREEN believers.",
        "color": "#B9F2FF",
        "shadow": "#008B8B",
        "stars": 4,
    },
}


# Base SVG template — the official GreenHat hat design
# Two paths: main body (color) + shadow layer (darker)
SVG_TEMPLATE = """<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" fill="none" version="1.1" width="1942" height="1474" viewBox="0 0 1942 1474">
  <defs>
    <clipPath id="master_svg0_10_08">
      <rect x="0" y="0" width="1942" height="1474" rx="0"/>
    </clipPath>
  </defs>
  <g clip-path="url(#master_svg0_10_08)">
    <!-- Main hat body -->
    <path d="M1292.6468006591797,848.0546862304687C1418.8818006591796,848.0546862304687,1601.6701006591798,821.8053562304688,1601.6701006591798,671.3765862304688C1601.6642006591796,659.8681662304688,1600.6504006591797,648.3822662304688,1598.6404006591797,637.0505362304688L1523.9093006591797,309.94381623046877C1506.7415006591798,238.26298623046875,1491.5932006591797,204.94656623046876,1365.3582006591796,142.35203623046874C1267.3997006591796,91.87258923046875,1054.3150006591798,10.09588623046875,990.6926106591796,10.09588623046875C931.1096606591797,10.09588623046875,913.9416306591797,85.81506323046875,844.2599306591796,85.81506323046875C776.5979506591797,85.81506323046875,727.1138806591797,29.27807623046875,663.4913806591796,29.27807623046875C602.8985406591797,29.27807623046875,563.5131706591797,70.67122623046875,533.2167806591797,155.47668623046874C533.2167806591797,155.47668623046874,448.3868206591797,394.7492662304688,437.2781506591797,430.08489623046876C435.60948065917967,436.33474623046874,434.92799065917967,442.80688623046876,435.2583806591797,449.26708623046875C434.2485206591797,542.1492262304688,800.8350706591797,847.0451062304687,1292.6468006591797,848.0546862304687Z" fill="{COLOR}" fill-opacity="1"/>
    <!-- Shadow / depth layer -->
    <path d="M1620.85796015625,732.9617014550781C1638.02576015625,815.7479514550781,1638.02576015625,824.8342914550781,1638.02576015625,834.9301714550782C1638.02576015625,976.2726114550782,1479.47456015625,1055.0206014550781,1270.4294401562502,1055.0206014550781C797.80548015625,1055.0205414550783,384.76446834728,778.3931914550781,384.76446834728,595.6575614550782C384.71804707525,570.3136614550781,389.87377455625,545.2297614550781,399.91267415625,521.9575724550781L437.27825515625,430.0849914550781C435.60955415625,436.33484265507815,434.92806615625,442.8069894550781,435.25848815625,449.26719845507813C435.25848815625,542.1493914550781,801.8450001562501,847.0452014550781,1292.64685015625,847.0452014550781C1418.88186015625,847.0452014550781,1601.67016015625,820.7959014550781,1601.67016015625,670.3671314550782C1601.66416015625,658.8586714550781,1600.65056015625,647.3727714550781,1598.64046015625,636.0411214550782L1620.85796015625,732.9617014550781Z" fill="{SHADOW}" fill-opacity="1"/>
  </g>
</svg>"""


def generate_svg(tier: str, info: dict) -> str:
    """Replace colors in the base SVG template with tier-specific ones."""
    return (SVG_TEMPLATE
        .replace("{COLOR}", info["color"])
        .replace("{SHADOW}", info["shadow"])
    )


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
