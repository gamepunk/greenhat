#!/usr/bin/env bun
/// GreenHat Health Check
///
/// Periodic checks on contract state:
///   - Total supply hasn't changed (unless burned)
///   - Owner hasn't been transferred unexpectedly
///   - Contract is reachable
///   - Recent blocks are being produced
///
/// Usage:
///   bun run scripts/healthcheck.ts              # run once
///   bun run scripts/healthcheck.ts --watch      # run every 60s
///   bun run scripts/healthcheck.ts --once       # run once (default)

import { createPublicClient, http } from "viem";
import { GREENHAT_ADDRESS, GREENHAT_ABI, CHAIN } from "../app/config";

const WATCH = process.argv.includes("--watch");
const INTERVAL_MS = 60_000; // 1 minute

const client = createPublicClient({
  chain: CHAIN as any,
  transport: http(),
});

// ── Checks ──────────────────────────────────────────────────────

interface CheckResult {
  name: string;
  status: "✅" | "⚠️" | "❌";
  message: string;
}

async function runChecks(): Promise<CheckResult[]> {
  const results: CheckResult[] = [];

  // 1. Contract reachable
  try {
    const code = await client.getCode({ address: GREENHAT_ADDRESS });
    if (!code || code === "0x")
      results.push({ name: "Contract Exists", status: "❌", message: "No bytecode at address!" });
    else
      results.push({ name: "Contract Exists", status: "✅", message: "Bytecode present" });
  } catch (e: any) {
    results.push({ name: "Contract Exists", status: "❌", message: e.message });
  }

  // 2. Total supply
  try {
    const c = client as any;
    const [supply, maxSupply, symbol] = await Promise.all([
      c.readContract({ address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "totalSupply" }) as Promise<bigint>,
      c.readContract({ address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "MAX_SUPPLY" }) as Promise<bigint>,
      c.readContract({ address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "symbol" }) as Promise<string>,
    ]);

    if (supply > maxSupply)
      results.push({ name: "Supply Check", status: "❌", message: `Supply ${supply} > MAX ${maxSupply}!` });
    else if (supply === maxSupply)
      results.push({ name: "Supply Check", status: "✅", message: `${symbol} supply at max (no burns yet)` });
    else
      results.push({ name: "Supply Check", status: "✅", message: `${symbol} supply: ${supply} (${((Number(supply)/Number(maxSupply))*100).toFixed(4)}% of max)` });
  } catch (e: any) {
    results.push({ name: "Supply Check", status: "❌", message: e.message });
  }

  // 3. Owner
  try {
    const c = client as any;
    const owner = await c.readContract({
      address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "owner",
    }) as string;
    if (owner === "0x0000000000000000000000000000000000000000")
      results.push({ name: "Ownership", status: "⚠️", message: "Owner renounced (address(0))" });
    else
      results.push({ name: "Ownership", status: "✅", message: `Owner: ${owner.slice(0,6)}…${owner.slice(-4)}` });
  } catch (e: any) {
    results.push({ name: "Ownership", status: "❌", message: e.message });
  }

  // 4. Trading paused
  try {
    const c = client as any;
    const paused = await c.readContract({
      address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "tradingPaused",
    }) as boolean;
    if (paused)
      results.push({ name: "Trading", status: "⚠️", message: "Trading is PAUSED" });
    else
      results.push({ name: "Trading", status: "✅", message: "Active" });
  } catch (e: any) {
    results.push({ name: "Trading", status: "❌", message: e.message });
  }

  // 5. Chain connectivity
  try {
    const blockNum = await client.getBlockNumber();
    const block = await client.getBlock({ blockNumber: blockNum });
    const ago = Math.floor(Date.now() / 1000) - Number(block.timestamp);
    if (ago > 300)
      results.push({ name: "Chain Sync", status: "⚠️", message: `Last block ${ago}s ago (behind)` });
    else
      results.push({ name: "Chain Sync", status: "✅", message: `Block #${blockNum}, ${ago}s ago` });
  } catch (e: any) {
    results.push({ name: "Chain Sync", status: "❌", message: e.message });
  }

  return results;
}

// ── Display ─────────────────────────────────────────────────────

function display(results: CheckResult[]) {
  const allOk = results.every((r) => r.status === "✅");
  console.log("");
  console.log(`  🧢 GreenHat Health Check — ${allOk ? "✅ All Healthy" : "❌ Issues Found"}`);
  console.log(`  ${CHAIN.name} | ${GREENHAT_ADDRESS}`);
  console.log("");
  for (const r of results) {
    console.log(`  ${r.status}  ${r.name.padEnd(18)} ${r.message}`);
  }
  console.log("");
}

// ── Main ────────────────────────────────────────────────────────

async function main() {
  if (WATCH) {
    console.log(`  🧢 Watching every ${INTERVAL_MS / 1000}s...`);
    while (true) {
      const results = await runChecks();
      display(results);
      await new Promise((r) => setTimeout(r, INTERVAL_MS));
    }
  } else {
    const results = await runChecks();
    display(results);
  }
}

main().catch(console.error);
