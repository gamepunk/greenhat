/// Core types for the GreenHat web app

export interface TransferEvent {
  txHash: `0x${string}`;
  from: `0x${string}`;
  to: `0x${string}`;
  value: bigint;
  timestamp: number;
  blockNumber: bigint;
}
