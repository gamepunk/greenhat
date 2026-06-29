/// Configuration for GreenHat token on-chain interaction

// ── Deployed GreenHat contract on Polygon Amoy ──
export const GREENHAT_ADDRESS = "0x8C5B79A3014009EFA8FB2de98b8474AfCefF082f" as `0x${string}`;

// ── Polygon Amoy testnet ──
export const CHAIN = {
  id: 80_002,
  name: "Polygon Amoy",
  rpc: "https://rpc-amoy.polygon.technology",
  explorer: "https://amoy.polygonscan.com",
  currency: { name: "POL", symbol: "POL", decimals: 18 },
} as const;

// ── Import ABI ──
import abi from "../abi.json";
export const GREENHAT_ABI = abi as any;
