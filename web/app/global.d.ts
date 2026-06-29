/// Type declarations for injected wallet providers

interface Window {
  ethereum?: import("viem").EIP1193Provider & {
    isMetaMask?: boolean;
    request<T>(args: { method: string; params?: unknown[] }): Promise<T>;
  };
}
