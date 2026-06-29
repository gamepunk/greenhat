#!/usr/bin/env python3
"""
GreenHat 🧢 — Token Logo Generator

Generates a simple placeholder logo for the GREEN token.
Edit this script to customize your logo design.

Usage:
    python3 scripts/generate_logo.py

Output:
    assets/coin/greenhat-logo.svg
"""

import os

OUTPUT = os.path.join(os.path.dirname(__file__), "..", "assets", "coin", "greenhat-logo.svg")


def generate_svg() -> str:
    """Generate the GREEN token logo SVG.
    
    Edit this function to create your own design!
    """
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <!-- Dark circle background -->
  <circle cx="256" cy="256" r="240" fill="#1a1a2e" />

  <!-- Neon green ring -->
  <circle cx="256" cy="256" r="230" fill="none" stroke="#00FF00" stroke-width="8" opacity="0.4"/>
  <circle cx="256" cy="256" r="200" fill="none" stroke="#00FF00" stroke-width="3" opacity="0.2"/>

  <!-- === YOUR DESIGN HERE === -->

  <!-- Emoji placeholder — replace with your own artwork -->
  <text x="256" y="220" font-size="100" text-anchor="middle">🧢</text>

  <!-- Token symbol -->
  <text x="256" y="310" font-size="48" font-weight="bold" font-family="Arial, sans-serif"
        fill="#00FF00" text-anchor="middle" letter-spacing="4">GREEN</text>

  <!-- === END DESIGN === -->

  <!-- Outer ring -->
  <circle cx="256" cy="256" r="240" fill="none" stroke="#00FF00" stroke-width="6" />
</svg>'''


def main():
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    with open(OUTPUT, "w") as f:
        f.write(generate_svg())
    print(f"✅  Logo generated: {OUTPUT}")
    print()
    print("Edit the SVG or scripts/generate_logo.py to customize!")


if __name__ == "__main__":
    main()
