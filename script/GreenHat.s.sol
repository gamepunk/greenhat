// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {GreenHat} from "../src/GreenHat.sol";

/// @title GreenHat Deployment Script
/// @notice Deploys the GreenHat meme coin
/// @dev Usage: forge script script/GreenHat.s.sol:GreenHatScript --rpc-url <rpc> --private-key <pk>
contract GreenHatScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        GreenHat token = new GreenHat();

        vm.stopBroadcast();

        console.log("GreenHat deployed at:", address(token));
        console.log("Total supply:", token.totalSupply());
        console.log("Owner:", token.owner());
    }
}
