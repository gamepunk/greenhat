/// Configuration for GreenHat token on-chain interaction

// ── Replace with your deployed contract address ──
export const GREENHAT_ADDRESS = "0x..." as `0x${string}`;

// ── Default chain (Sepolia testnet) ──
// Change to your target chain
export const CHAIN = {
  id: 11_155_111,
  name: "Sepolia",
  rpc: "https://sepolia.gateway.tenderly.co",
  explorer: "https://sepolia.etherscan.io",
  currency: { name: "SepoliaETH", symbol: "SEP", decimals: 18 },
} as const;

// ── Import ABI ──
import GREENHAT_ABI from "../abi.json";
export { GREENHAT_ABI };
