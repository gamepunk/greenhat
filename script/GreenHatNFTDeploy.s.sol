// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { GreenHatNFT } from "../src/GreenHatNFT.sol";
import { Script, console } from "forge-std/Script.sol";

/// @title GreenHatNFT Deploy Script
/// @notice Deploys the NFT contract
/// @dev After deploy, set tier URIs via:
///   cast send <NFT> "setTierURI(uint8,string)" 1 "ipfs://..."
///   or use the scripts/set_uris.sh helper
///
/// Usage:
///   source .env
///   forge script script/GreenHatNFTDeploy.s.sol:GreenHatNFTDeployScript \
///     --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY \
///     --broadcast --verify
contract GreenHatNFTDeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddr = vm.addr(deployerPrivateKey);
        address tokenAddr = vm.envAddress("GREENHAT_TOKEN_ADDRESS");

        console.log("=== GreenHat NFT Deployment ===");
        console.log("Chain:            ", block.chainid);
        console.log("Deployer:         ", deployerAddr);
        console.log("Token address:    ", tokenAddr);

        vm.startBroadcast(deployerPrivateKey);

        GreenHatNFT nft = new GreenHatNFT(tokenAddr);

        vm.stopBroadcast();

        console.log("NFT deployed at:  ", address(nft));
        console.log("");
        console.log("=== Set Metadata URIs ===");
        console.log("Option A - IPFS:");
        console.log("  ./scripts/set_uris.sh", address(nft), "$RPC_URL $DEPLOYER_PRIVATE_KEY");
        console.log("");
        console.log("Option B - Data URI (no IPFS):");
        console.log("  ./scripts/set_data_uris.sh", address(nft), "$RPC_URL $DEPLOYER_PRIVATE_KEY");
        console.log("");
        console.log("Then users can mint:");
        console.log("  cast send <NFT> 'mint()' --rpc-url <rpc> --private-key <pk>");
    }
}
