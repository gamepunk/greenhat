// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {GreenHat} from "../src/GreenHat.sol";

/// @title GreenHat Deployment Script
/// @notice Deploys GreenHat and optionally configures initial parameters
/// @dev Usage:
///   forge script script/GreenHat.s.sol:GreenHatScript \
///     --rpc-url <rpc> --private-key <pk> --broadcast --verify
contract GreenHatScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // ── Deploy ──
        GreenHat token = new GreenHat();

        // ── Log deployment info ──
        console.log("=== GreenHat Deployment ===");
        console.log("Token address:    ", address(token));
        console.log("Deployer:         ", deployerAddr);
        console.log("Total supply:     ", token.totalSupply());
        console.log("Buy tax rate:     ", token.buyTaxRate());
        console.log("Sell tax rate:    ", token.sellTaxRate());
        console.log("Max wallet:       ", token.maxWallet());
        console.log("Max tx:           ", token.maxTx());
        console.log("Owner:            ", token.owner());

        vm.stopBroadcast();

        // ── Post-deployment instructions ──
        console.log("");
        console.log("=== Next Steps ===");
        console.log("1. Set DEX pair:    token.setDexPair(<pair_address>)");
        console.log("2. Set marketing:   token.setMarketingWallet(<wallet>)");
        console.log("3. Configure tax:   token.setTaxRates(buy, sell)");
        console.log("4. Collect tax:     token.collectMarketing() / collectLiquidity()");
        console.log("5. Renounce:        token.transferOwnership(<new_owner>)");
    }
}
