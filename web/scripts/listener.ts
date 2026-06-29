#!/usr/bin/env bun
/// GreenHat Event Listener
///
/// Watches the GREEN token contract for Transfer events and stores them in SQLite.
/// Provides a real-time transaction history for your token.
///
/// Usage:
///   bun run scripts/listener.ts                 # listen from latest block
///   bun run scripts/listener.ts --from 1000000  # backfill from block 1,000,000
///   bun run scripts/listener.ts --once          # scan recent blocks and exit

import { createPublicClient, http, parseAbiItem } from "viem";
import { GREENHAT_ADDRESS, CHAIN } from "../app/config";
import { openDb, insertTransfer } from "./db";

// ── Args ─────────────────────────────────────────────────────────
const FROM_BLOCK = process.argv.includes("--from")
  ? BigInt(process.argv[process.argv.indexOf("--from") + 1])
  : undefined;
const ONCE = process.argv.includes("--once");

// ── Client ───────────────────────────────────────────────────────
const client = createPublicClient({
  chain: CHAIN as any,
  transport: http(),
});

// ── Main ─────────────────────────────────────────────────────────
async function main() {
  const db = openDb();
  console.log(`🧢 GreenHat Listener (${CHAIN.name})`);
  console.log(`   Contract: ${GREENHAT_ADDRESS}`);
  console.log(`   DB: greenhat.db`);
  console.log("");

  if (FROM_BLOCK !== undefined) {
    console.log(`⏮️  Backfilling from block ${FROM_BLOCK}...`);
    await backfill(db, FROM_BLOCK);
  }

  if (ONCE) {
    console.log(`🔍 Scanning recent blocks...`);
    await backfill(db, undefined);
    printStats(db);
    return;
  }

  console.log(`👂 Listening for Transfer events...`);
  await listen(db);
}

// ── Backfill historical events ──────────────────────────────────
async function backfill(db: any, fromBlock?: bigint) {
  const latest = await client.getBlockNumber();
  const from = fromBlock ?? latest - 1000n; // last ~1000 blocks

  console.log(`   Scanning blocks ${from} → ${latest}`);

  const logs = await client.getLogs({
    address: GREENHAT_ADDRESS,
    event: parseAbiItem("event Transfer(address indexed from, address indexed to, uint256 value)"),
    fromBlock: from,
    toBlock: latest,
  });

  let count = 0;
  for (const log of logs) {
    const block = await client.getBlock({ blockNumber: log.blockNumber });
    insertTransfer(db, {
      tx_hash: log.transactionHash!,
      from_addr: (log.args.from ?? "0x0") as string,
      to_addr: (log.args.to ?? "0x0") as string,
      value: (log.args.value ?? 0n).toString(),
      block_number: Number(log.blockNumber),
      timestamp: Number(block.timestamp),
    });
    count++;
  }

  console.log(`   ✅ ${count} events recorded`);
}

// ── Live listener ────────────────────────────────────────────────
async function listen(db: any) {
  const unwatch = client.watchContractEvent({
    address: GREENHAT_ADDRESS,
    abi: JSON.parse(await Bun.file(import.meta.dir + "/../abi.json").text()),
    eventName: "Transfer",
    onLogs: async (logs) => {
      for (const log of logs) {
        const block = await client.getBlock({ blockNumber: log.blockNumber });
        const row = {
          tx_hash: (log.transactionHash ?? "0x0") as string,
          from_addr: (log.args?.from ?? "0x0") as string,
          to_addr: (log.args?.to ?? "0x0") as string,
          value: (log.args?.value ?? 0n).toString(),
          block_number: Number(log.blockNumber),
          timestamp: Number(block.timestamp),
        };
        insertTransfer(db, row);

        const fromShort = row.from_addr.slice(0, 6) + "…" + row.from_addr.slice(-4);
        const toShort = row.to_addr.slice(0, 6) + "…" + row.to_addr.slice(-4);
        const val = (BigInt(row.value) / 10n ** 18n).toString();
        console.log(
          `  📦 #${row.block_number}  ${fromShort} → ${toShort}  ${val} GREEN`
        );
      }
    },
  });

  // Graceful shutdown
  process.on("SIGINT", () => {
    console.log("\n   👋 Shutting down...");
    unwatch();
    db.close();
    process.exit(0);
  });

  console.log(`   Press Ctrl+C to stop`);
}

function printStats(db: any) {
  const { total_transfers, unique_senders, unique_receivers, total_volume } =
    require("./db").getStats(db);
  console.log(`\n📊 Stats:`);
  console.log(`   Transfers: ${total_transfers}`);
  console.log(`   Unique senders: ${unique_senders}`);
  console.log(`   Unique receivers: ${unique_receivers}`);
  console.log(`   Total volume: ${(BigInt(total_volume) / 10n ** 18n).toString()} GREEN`);
}

main().catch(console.error);
