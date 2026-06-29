// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GreenHat } from "../src/GreenHat.sol";
import { Script, console } from "forge-std/Script.sol";

/// @title GreenHat Deployment Script
/// @notice Deploy GreenHat to any EVM chain with one command
/// @dev Usage:
///   source .env
///   forge script script/GreenHat.s.sol:GreenHatScript \
///     --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY \
///     --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
///
///  Optional env vars:
///   DEPLOY_DEX_PAIR       — set DEX pair address after deploy
contract GreenHatScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);

        // ── Detect chain ──
        uint256 chainId = block.chainid;
        string memory chainName = _chainName(chainId);

        console.log("=== GreenHat Deployment ===");
        console.log("Chain:            ", chainName);
        console.log("Chain ID:         ", chainId);
        console.log("Deployer:         ", deployerAddr);

        vm.startBroadcast(deployerPrivateKey);

        // ── Deploy ──
        GreenHat token = new GreenHat();

        vm.stopBroadcast();

        // ── Post-deploy: DEX pair (optional) ──
        string memory dexPairStr = vm.envOr("DEPLOY_DEX_PAIR", string(""));
        if (bytes(dexPairStr).length > 0) {
            address dexPair = vm.parseAddress(dexPairStr);
            vm.startBroadcast(deployerPrivateKey);
            token.setDexPair(dexPair);
            vm.stopBroadcast();
            console.log("DEX pair set:     ", dexPair);
        }

        // ── Summary ──
        console.log("");
        console.log("=== Deployment Summary ===");
        console.log("Token:            ", address(token));
        console.log("Total supply:     ", token.totalSupply());
        console.log("Max wallet:       ", token.maxWallet());
        console.log("Max tx:           ", token.maxTx());
        console.log("Owner:            ", token.owner());
        console.log("");
        console.log("=== Explorer ===");
        console.log("Verify:           ", _explorerUrl(chainId, address(token)));
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. If no DEX pair set:");
        console.log("     token.setDexPair(<pair_address>)");
        console.log("2. Adjust limits (optional):");
        console.log("     token.setLimits(<max_wallet>, <max_tx>)");
        console.log("3. Transfer ownership to multi-sig:");
        console.log("     token.transferOwnership(<safe_address>)");
    }

    /// @notice Return human-readable chain name
    function _chainName(
        uint256 chainId
    ) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 56) return "BNB Smart Chain";
        if (chainId == 137) return "Polygon Mainnet";
        if (chainId == 8453) return "Base";
        if (chainId == 10) return "Optimism";
        if (chainId == 42161) return "Arbitrum One";
        if (chainId == 11155111) return "Sepolia Testnet";
        if (chainId == 84532) return "Base Sepolia Testnet";
        if (chainId == 80002) return "Polygon Amoy Testnet";
        return "Unknown";
    }

    /// @notice Return explorer link for verifying
    function _explorerUrl(
        uint256 chainId,
        address token
    ) internal pure returns (string memory) {
        string memory base;
        if (chainId == 1) base = "https://etherscan.io/address/";
        else if (chainId == 56) base = "https://bscscan.com/address/";
        else if (chainId == 137) base = "https://polygonscan.com/address/";
        else if (chainId == 8453) base = "https://basescan.org/address/";
        else if (chainId == 10) base = "https://optimistic.etherscan.io/address/";
        else if (chainId == 42161) base = "https://arbiscan.io/address/";
        else if (chainId == 11155111) base = "https://sepolia.etherscan.io/address/";
        else if (chainId == 84532) base = "https://sepolia.basescan.org/address/";
        else if (chainId == 80002) base = "https://amoy.polygonscan.com/address/";
        else return "https://explorer.unknown";
        return string.concat(base, vm.toString(token));
    }
}
