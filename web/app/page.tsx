"use client";

import { useEffect, useState, useCallback } from "react";
import {
  createPublicClient,
  createWalletClient,
  custom,
  http,
  parseUnits,
  formatUnits,
  type Chain,
} from "viem";
import { GREENHAT_ADDRESS, GREENHAT_ABI, CHAIN } from "./config";
import type { TransferEvent } from "./types";

// ── Styles ──────────────────────────────────────────────────────
const styles = {
  container: { maxWidth: 640, margin: "0 auto", padding: "32px 16px", display: "flex", flexDirection: "column" as const, gap: 20 },
  header: { display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 },
  title: { fontSize: 28, fontWeight: 700, color: "#00ff88" as const },
  badge: (connected: boolean) => ({
    padding: "6px 14px", borderRadius: 20, fontSize: 13, fontWeight: 600,
    background: connected ? "#00ff8822" : "#ff446622",
    color: connected ? "#00ff88" : "#ff4466",
    border: `1px solid ${connected ? "#00ff88" : "#ff4466"}`,
  }),
  grid: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 },
  label: { fontSize: 12, color: "#8888aa", marginBottom: 4, textTransform: "uppercase" as const, letterSpacing: 1 },
  value: { fontSize: 18, fontWeight: 600 },
  btn: (color: string) => ({
    background: color, color: "#000", padding: "12px 24px",
    fontSize: 16, fontWeight: 700, borderRadius: 10,
  }),
  feedItem: {
    padding: "10px 0", borderBottom: "1px solid #2a2a5a",
    fontSize: 14, display: "flex", justifyContent: "space-between" as const,
  },
  eventLink: { color: "#00ff88", textDecoration: "none" as const },
};

// ── Chain config for viem ───────────────────────────────────────
const viemChain: Chain = {
  id: CHAIN.id,
  name: CHAIN.name,
  nativeCurrency: CHAIN.currency,
  rpcUrls: { default: { http: [CHAIN.rpc] } },
  blockExplorers: { default: { name: "Etherscan", url: CHAIN.explorer } },
};

// ── Client cache ────────────────────────────────────────────────
function getPublicClient() {
  return createPublicClient({ chain: viemChain, transport: http() });
}

// ── Main Page ───────────────────────────────────────────────────
export default function Home() {
  // Wallet state
  const [account, setAccount] = useState<`0x${string}` | null>(null);
  const [balance, setBalance] = useState<bigint>(0n);
  const [symbol, setSymbol] = useState("");
  const [totalSupply, setTotalSupply] = useState<bigint>(0n);

  // Transfer form
  const [to, setTo] = useState("");
  const [amount, setAmount] = useState("");
  const [sending, setSending] = useState(false);
  const [txHash, setTxHash] = useState<`0x${string}` | null>(null);

  // Dashboard feed
  const [feed, setFeed] = useState<TransferEvent[]>([]);

  // ── Connect Wallet ──
  const connect = useCallback(async () => {
    if (!window.ethereum) return alert("Please install MetaMask");
    try {
      const [addr] = await window.ethereum.request<string[]>({ method: "eth_requestAccounts" });
      setAccount(addr as `0x${string}`);
    } catch { /* user rejected */ }
  }, []);

  const disconnect = () => { setAccount(null); setBalance(0n); setFeed([]); };

  // ── Fetch token info ──
  useEffect(() => {
    if (!account) return;
    const pc = getPublicClient();
    (async () => {
      const pcAny = pc as any;
      const [bal, sym, sup] = await Promise.all([
        pcAny.readContract({ address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "balanceOf", args: [account] }),
        pcAny.readContract({ address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "symbol" }),
        pcAny.readContract({ address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "totalSupply" }),
      ]);
      setBalance(bal as bigint);
      setSymbol(sym as string);
      setTotalSupply(sup as bigint);
    })();
  }, [account]);

  // Refresh balance
  const refreshBalance = useCallback(async () => {
    if (!account) return;
    const pc = getPublicClient() as any;
    const bal = await pc.readContract({
      address: GREENHAT_ADDRESS, abi: GREENHAT_ABI, functionName: "balanceOf", args: [account],
    });
    setBalance(bal as bigint);
  }, [account]);

  // ── Transfer ──
  const transfer = useCallback(async () => {
    if (!account || !to || !amount) return;
    setSending(true);
    setTxHash(null);
    try {
      const wc = createWalletClient({ chain: viemChain, transport: custom(window.ethereum!) }) as any;
      const hash = await wc.writeContract({
        address: GREENHAT_ADDRESS, abi: GREENHAT_ABI,
        functionName: "transfer",
        args: [to as `0x${string}`, parseUnits(amount, 4)],
        account,
      });
      setTxHash(hash);
      await getPublicClient().waitForTransactionReceipt({ hash });
      await refreshBalance();
      setAmount("");
    } catch (e: any) {
      alert(e?.shortMessage ?? e?.message ?? "Transfer failed");
    }
    setSending(false);
  }, [account, to, amount, refreshBalance]);

  // ── Dashboard: watch Transfer events ──
  useEffect(() => {
    if (!account) return;
    const pc = getPublicClient();
    const unwatch = pc.watchContractEvent({
      address: GREENHAT_ADDRESS,
      abi: GREENHAT_ABI,
      eventName: "Transfer",
      onLogs: (logs: any[]) => {
        for (const log of logs) {
          const ev: TransferEvent = {
            txHash: (log.transactionHash ?? "0x0") as `0x${string}`,
            from: (log.args?.from ?? "0x0") as `0x${string}`,
            to: (log.args?.to ?? "0x0") as `0x${string}`,
            value: (log.args?.value ?? 0n) as bigint,
            timestamp: Date.now(),
            blockNumber: log.blockNumber ?? 0n,
          };
          setFeed((prev) => [ev, ...prev].slice(0, 50));
        }
      },
    });
    return unwatch;
  }, [account]);

  // ── Format helpers ──
  const fmt = (v: bigint) => formatUnits(v, 4);
  const short = (addr: `0x${string}`) => `${addr.slice(0, 6)}...${addr.slice(-4)}`;

  return (
    <div style={styles.container}>
      {/* Header */}
      <div style={styles.header}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <img src="/token.svg" alt="GreenHat" style={{ width: 36, height: 36, borderRadius: 8 }} />
          <div style={styles.title}>GreenHat</div>
        </div>
        <button style={styles.badge(!!account)} onClick={account ? disconnect : connect}>
          {account ? short(account) : "Connect Wallet"}
        </button>
      </div>

      {!account ? (
        <div className="card" style={{ textAlign: "center", padding: 60 }}>
          <p style={{ fontSize: 48, marginBottom: 16 }}>🧢</p>
          <p style={{ color: "#8888aa", marginBottom: 24 }}>Connect your wallet to interact with GREEN tokens</p>
          <button style={styles.btn("#00ff88")} onClick={connect}>Connect MetaMask</button>
        </div>
      ) : (
        <>
          {/* Balance Card */}
          <div className="card" style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={styles.label}>Your Balance</div>
              <div style={{ fontSize: 32, fontWeight: 700 }}>{fmt(balance)} <span style={{ color: "#00ff88" }}>{symbol}</span></div>
            </div>
            <button style={{ background: "none", color: "#8888aa", fontSize: 12 }} onClick={refreshBalance}>↻</button>
          </div>

          {/* Stats Grid */}
          <div style={styles.grid}>
            <div className="card">
              <div style={styles.label}>Total Supply</div>
              <div style={styles.value}>{fmt(totalSupply)}</div>
            </div>
            <div className="card">
              <div style={styles.label}>Your Share</div>
              <div style={styles.value}>
                {totalSupply > 0n ? ((Number(balance) / Number(totalSupply)) * 100).toFixed(4) : "0"}%
              </div>
            </div>
          </div>

          {/* Transfer Form */}
          <div className="card">
            <div style={styles.label}>Send {symbol}</div>
            <div style={{ display: "flex", gap: 12, flexDirection: "column" }}>
              <input placeholder="Recipient address (0x...)" value={to} onChange={(e) => setTo(e.target.value)} />
              <input placeholder="Amount" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
              <button style={styles.btn("#00ff88")} onClick={transfer} disabled={sending || !to || !amount}>
                {sending ? "Sending..." : `Send ${symbol}`}
              </button>
              {txHash && (
                <p style={{ fontSize: 12, color: "#00ff88", textAlign: "center" }}>
                  ✅ Sent! <a style={styles.eventLink} href={`${CHAIN.explorer}/tx/${txHash}`} target="_blank">View on explorer ↗</a>
                </p>
              )}
            </div>
          </div>

          {/* Dashboard: Transfer Feed */}
          <div className="card">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <div style={styles.label}>Real-Time Transfer Feed</div>
              <span style={{ fontSize: 12, color: "#8888aa" }}>{feed.length} events</span>
            </div>
            {feed.length === 0 ? (
              <p style={{ color: "#8888aa", fontSize: 14, textAlign: "center", padding: 20 }}>
                Waiting for transfers... Make a transfer to see it here!
              </p>
            ) : (
              feed.map((ev, i) => (
                <div key={`${ev.txHash}-${i}`} style={styles.feedItem}>
                  <span>
                    {ev.from === "0x0000000000000000000000000000000000000000" ? "🪙 Mint" : `📤 ${short(ev.from)}`}
                    {" → "}
                    {ev.to === "0x0000000000000000000000000000000000000000" ? "🔥 Burn" : `📥 ${short(ev.to)}`}
                  </span>
                  <span>
                    <strong>{fmt(ev.value)}</strong> GREEN
                    <a style={{ ...styles.eventLink, marginLeft: 8, fontSize: 11 }} href={`${CHAIN.explorer}/tx/${ev.txHash}`} target="_blank">
                      ↗
                    </a>
                  </span>
                </div>
              ))
            )}
          </div>
        </>
      )}

      {/* Footer */}
      <p style={{ textAlign: "center", color: "#8888aa", fontSize: 12, marginTop: 20 }}>
        GreenHat 🧢 · {CHAIN.name} · Contract: {short(GREENHAT_ADDRESS)}
      </p>
    </div>
  );
}
