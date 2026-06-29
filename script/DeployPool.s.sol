// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {GreenHat} from "../src/GreenHat.sol";
import {GreenHatPool} from "../src/GreenHatPool.sol";

/// @title DeployPool Script
/// @notice Deploys GREEN/POL pool with 10% supply as initial liquidity
/// @dev Price: 1 POL = 1,000,000,000 GREEN (0.000000001 POL per GREEN)
///
/// Usage:
///   source .env
///   forge script script/DeployPool.s.sol:DeployPoolScript \
///     --rpc-url https://rpc-amoy.polygon.technology \
///     --private-key $DEPLOYER_PRIVATE_KEY --broadcast
contract DeployPoolScript is Script {
    function run() public {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(pk);
        address tokenAddr = vm.envAddress("GREENHAT_TOKEN");

        uint256 liqGreen = 10_000_000 * 10 ** 18; // 1% of supply
        uint256 liqPol = 0.01 ether; // 0.01 POL

        console.log("=== GREEN/POL Liquidity Pool ===");
        console.log("Token:            ", tokenAddr);
        console.log("GREEN liquidity:  ", liqGreen);
        console.log("POL liquidity:    ", liqPol, "POL");
        console.log("Initial price:    1 POL = 1,000,000,000 GREEN");

        vm.startBroadcast(pk);

        // 1. Deploy pool
        GreenHatPool pool = new GreenHatPool(tokenAddr);
        console.log("Pool deployed:    ", address(pool));

        // 2. Approve pool
        GreenHat(tokenAddr).approve(address(pool), liqGreen);
        console.log(unicode"✅ GREEN approved");

        // 3. Add liquidity (POL sent as msg.value)
        pool.addLiquidity{value: liqPol}(liqGreen);
        console.log(unicode"✅ Liquidity added!");

        vm.stopBroadcast();

        console.log("");
        console.log("=== Done ===");
        console.log("Pool:     ", address(pool));
        console.log(unicode"Buy:      send POL to pool → receive GREEN");
        console.log(unicode"Sell:     approve GREEN → call sellGreen()");
        console.log("Explorer: https://amoy.polygonscan.com/address/", address(pool));
    }
}
