/// Shared SQLite database for GreenHat operational scripts
/// Uses bun:sqlite — zero dependencies.

import { Database } from "bun:sqlite";
import { join } from "path";

const DB_PATH = join(import.meta.dir, "..", "greenhat.db");

export interface TransferRow {
  id: number;
  tx_hash: string;
  from_addr: string;
  to_addr: string;
  value: string; // stored as decimal string (bigint not supported by SQLite)
  block_number: number;
  timestamp: number;
  created_at: string;
}

export function openDb(): Database {
  const db = new Database(DB_PATH);

  // Enable WAL mode for concurrent reads
  db.run("PRAGMA journal_mode = WAL");

  // Create tables if not exist
  db.run(`
    CREATE TABLE IF NOT EXISTS transfers (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      tx_hash     TEXT NOT NULL UNIQUE,
      from_addr   TEXT NOT NULL,
      to_addr     TEXT NOT NULL,
      value       TEXT NOT NULL,
      block_number INTEGER NOT NULL,
      timestamp   INTEGER NOT NULL,
      created_at  TEXT DEFAULT (datetime('now'))
    )
  `);

  db.run(`
    CREATE INDEX IF NOT EXISTS idx_transfers_from ON transfers(from_addr)
  `);
  db.run(`
    CREATE INDEX IF NOT EXISTS idx_transfers_to ON transfers(to_addr)
  `);
  db.run(`
    CREATE INDEX IF NOT EXISTS idx_transfers_block ON transfers(block_number)
  `);

  return db;
}

export function insertTransfer(
  db: Database,
  tx: Omit<TransferRow, "id" | "created_at">
) {
  db.run(
    `INSERT OR IGNORE INTO transfers (tx_hash, from_addr, to_addr, value, block_number, timestamp)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [tx.tx_hash, tx.from_addr, tx.to_addr, tx.value, tx.block_number, tx.timestamp]
  );
}

export function getRecentTransfers(db: Database, limit = 20): TransferRow[] {
  return db
    .query("SELECT * FROM transfers ORDER BY block_number DESC LIMIT ?")
    .all(limit) as TransferRow[];
}

export function getStats(db: Database) {
  const row = db.query(`
    SELECT
      COUNT(*) as total_transfers,
      COUNT(DISTINCT from_addr) as unique_senders,
      COUNT(DISTINCT to_addr) as unique_receivers,
      COALESCE(SUM(CAST(value AS INTEGER)), 0) as total_volume
    FROM transfers
  `).get() as any;
  return row;
}
