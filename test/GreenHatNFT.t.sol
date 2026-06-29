// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GreenHat } from "../src/GreenHat.sol";
import { GreenHatNFT } from "../src/GreenHatNFT.sol";
import { Test } from "forge-std/Test.sol";

contract GreenHatNFTTest is Test {
    GreenHat public token;
    GreenHatNFT public nft;

    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant ONE_TOKEN = 10 ** 4;

    // Tier thresholds
    uint256 public constant BRONZE = 1_000 * ONE_TOKEN;
    uint256 public constant SILVER = 10_000 * ONE_TOKEN;
    uint256 public constant GOLD = 100_000 * ONE_TOKEN;
    uint256 public constant DIAMOND = 1_000_000 * ONE_TOKEN;

    function setUp() public {
        vm.prank(deployer);
        token = new GreenHat();

        vm.prank(deployer);
        nft = new GreenHatNFT(address(token));
    }

    // ─── Mint: Bronze ───────────────────────────────────────────

    function test_MintBronze() public {
        _fund(alice, BRONZE);

        vm.prank(alice);
        nft.mint();

        assertEq(nft.ownerOf(1), alice);
        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Bronze));
        assertTrue(nft.hasMinted(alice));
        assertEq(nft.walletToken(alice), 1);
    }

    function test_MintSilver() public {
        _fund(alice, SILVER);

        vm.prank(alice);
        nft.mint();

        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Silver));
    }

    function test_MintGold() public {
        _fund(alice, GOLD);

        vm.prank(alice);
        nft.mint();

        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Gold));
    }

    function test_MintDiamond() public {
        _fund(alice, DIAMOND);

        vm.prank(alice);
        nft.mint();

        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Diamond));
    }

    // ─── Reverts ────────────────────────────────────────────────

    function test_RevertWhen_InsufficientBalance() public {
        _fund(alice, BRONZE - 1);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(GreenHatNFT.InsufficientBalance.selector, GreenHatNFT.Tier.None));
        nft.mint();
    }

    function test_RevertWhen_AlreadyMinted() public {
        _fund(alice, BRONZE);

        vm.prank(alice);
        nft.mint();

        vm.prank(alice);
        vm.expectRevert(GreenHatNFT.AlreadyMinted.selector);
        nft.mint();
    }

    function test_RevertWhen_ZeroBalance() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(GreenHatNFT.InsufficientBalance.selector, GreenHatNFT.Tier.None));
        nft.mint();
    }

    // ─── Upgrade ────────────────────────────────────────────────

    function test_UpgradeBronzeToSilver() public {
        _fund(alice, BRONZE);
        vm.prank(alice);
        nft.mint();
        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Bronze));

        // Give alice more tokens to reach Silver
        _fund(alice, SILVER - BRONZE);

        vm.prank(alice);
        nft.upgrade();

        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Silver));
    }

    function test_UpgradeBronzeToDiamond() public {
        _fund(alice, BRONZE);
        vm.prank(alice);
        nft.mint();

        // Give alice enough for Diamond
        _fund(alice, DIAMOND - BRONZE);

        vm.prank(alice);
        nft.upgrade();

        assertEq(uint256(nft.tokenTier(1)), uint256(GreenHatNFT.Tier.Diamond));
    }

    function test_RevertWhen_NoUpgradeAvailable() public {
        _fund(alice, BRONZE);
        vm.prank(alice);
        nft.mint();

        // No upgrade possible (same tier)
        vm.prank(alice);
        vm.expectRevert(GreenHatNFT.NoUpgradeAvailable.selector);
        nft.upgrade();
    }

    function test_RevertWhen_NoHatToUpgrade() public {
        vm.prank(alice);
        vm.expectRevert(GreenHatNFT.NoHatToUpgrade.selector);
        nft.upgrade();
    }

    // ─── Current Tier View ──────────────────────────────────────

    function test_CurrentTier() public {
        assertEq(uint256(nft.currentTier(alice)), uint256(GreenHatNFT.Tier.None));

        _fund(alice, BRONZE);
        assertEq(uint256(nft.currentTier(alice)), uint256(GreenHatNFT.Tier.Bronze));

        _fund(alice, SILVER - BRONZE);
        assertEq(uint256(nft.currentTier(alice)), uint256(GreenHatNFT.Tier.Silver));
    }

    // ─── Admin ──────────────────────────────────────────────────

    function test_SetTierURI() public {
        vm.prank(deployer);
        nft.setTierURI(GreenHatNFT.Tier.Bronze, "ipfs://QmNew/bronze.json");

        // Mint and check URI
        _fund(alice, BRONZE);
        vm.prank(alice);
        nft.mint();

        assertEq(nft.tokenURI(1), "ipfs://QmNew/bronze.json");
    }

    function test_RevertWhen_NonOwnerSetsTierURI() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.setTierURI(GreenHatNFT.Tier.Bronze, "ipfs://...");
    }

    // ─── Fuzz ───────────────────────────────────────────────────

    function testFuzz_MintWithSufficientBalance(
        uint256 amount
    ) public {
        vm.assume(amount >= BRONZE && amount <= 10_000_000 * ONE_TOKEN);

        _fund(alice, amount);
        vm.prank(alice);
        nft.mint();

        assertTrue(nft.hasMinted(alice));
        assertEq(nft.ownerOf(1), alice);
    }

    // ─── Helpers ────────────────────────────────────────────────

    function _fund(
        address to,
        uint256 amount
    ) internal {
        vm.prank(deployer);
        token.transfer(to, amount);
    }
}
