// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { GreenHat } from "../src/GreenHat.sol";
import { Test } from "forge-std/Test.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract GreenHatTest is Test {
    GreenHat public token;
    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public dex = makeAddr("dexPair");

    uint256 public constant MAX_SUPPLY = 21_000_000 * 10 ** 4;
    uint256 public constant ONE_TOKEN = 10 ** 4;
    uint256 public constant DEFAULT_MAX_WALLET = MAX_SUPPLY * 2 / 100; // 2%
    uint256 public constant DEFAULT_MAX_TX = MAX_SUPPLY * 1 / 100; // 1%

    function setUp() public {
        vm.prank(deployer);
        token = new GreenHat();
    }

    // ═══════════════════════════════════════════════════════════════
    //  Deployment
    // ═══════════════════════════════════════════════════════════════

    function test_Deployment() public view {
        assertEq(token.name(), "GreenHat");
        assertEq(token.symbol(), "GREEN");
        assertEq(token.decimals(), 4);
        assertEq(token.totalSupply(), MAX_SUPPLY);
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
        assertEq(token.owner(), deployer);
        assertEq(token.balanceOf(deployer), MAX_SUPPLY);
    }

    function test_DefaultLimits() public view {
        assertEq(token.maxWallet(), DEFAULT_MAX_WALLET);
        assertEq(token.maxTx(), DEFAULT_MAX_TX);
    }

    function test_DefaultExclusions() public view {
        assertTrue(token.isExcludedFromLimits(deployer));
        assertTrue(token.isExcludedFromLimits(address(0)));
        assertTrue(token.isExcludedFromLimits(address(0xdead)));
        assertTrue(token.isExcludedFromLimits(address(token)));
    }

    function test_DexPairNotSet() public view {
        assertEq(token.dexPair(), address(0));
    }

    // ═══════════════════════════════════════════════════════════════
    //  Transfers
    // ═══════════════════════════════════════════════════════════════

    function test_Transfer() public {
        uint256 amount = 100 * ONE_TOKEN;
        vm.prank(deployer);
        assertTrue(token.transfer(alice, amount));

        assertEq(token.balanceOf(deployer), MAX_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 50 * ONE_TOKEN;
        vm.prank(deployer);
        token.approve(alice, amount);

        vm.prank(alice);
        assertTrue(token.transferFrom(deployer, bob, amount));

        assertEq(token.balanceOf(deployer), MAX_SUPPLY - amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(deployer, alice), 0);
    }

    function test_TransferFromInfiniteApproval() public {
        uint256 amount = 50 * ONE_TOKEN;
        vm.prank(deployer);
        token.approve(alice, type(uint256).max);

        vm.prank(alice);
        assertTrue(token.transferFrom(deployer, bob, amount));

        assertEq(token.allowance(deployer, alice), type(uint256).max);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert();
        token.transfer(address(0), 100);
    }

    function test_RevertWhen_InsufficientAllowance() public {
        vm.prank(deployer);
        token.approve(alice, 100);

        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(deployer, bob, 101);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Limits: Max Wallet
    // ═══════════════════════════════════════════════════════════════

    function test_RevertWhen_ExceedMaxWallet() public {
        // Give bob almost maxWallet
        _fund(bob, DEFAULT_MAX_WALLET);
        // Give alice enough to send
        _fund(alice, 100 * ONE_TOKEN);

        // Alice sends 1 token → bob would exceed maxWallet
        vm.prank(alice);
        vm.expectRevert(GreenHat.MaxWalletExceeded.selector);
        token.transfer(bob, 1);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Limits: Max Transaction
    // ═══════════════════════════════════════════════════════════════

    function test_RevertWhen_ExceedMaxTx() public {
        _fund(alice, DEFAULT_MAX_TX + 1);
        vm.prank(deployer);
        token.excludeFromLimits(alice, false);

        vm.prank(alice);
        vm.expectRevert(GreenHat.MaxTxExceeded.selector);
        token.transfer(bob, DEFAULT_MAX_TX + 1);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Blacklist
    // ═══════════════════════════════════════════════════════════════

    function test_BlacklistPreventsTransfers() public {
        vm.prank(deployer);
        token.setBlacklist(alice, true);

        vm.prank(alice);
        vm.expectRevert(GreenHat.BlacklistedAddress.selector);
        token.transfer(bob, 100);
    }

    function test_BlacklistPreventsReceiving() public {
        vm.prank(deployer);
        token.setBlacklist(bob, true);

        vm.prank(deployer);
        vm.expectRevert(GreenHat.BlacklistedAddress.selector);
        token.transfer(bob, 100);
    }

    function test_Unblacklist() public {
        vm.prank(deployer);
        token.setBlacklist(alice, true);
        vm.prank(deployer);
        token.setBlacklist(alice, false);

        _fund(alice);

        vm.prank(alice);
        token.transfer(bob, 10 * ONE_TOKEN);

        assertEq(token.balanceOf(bob), 10 * ONE_TOKEN);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Trading Pause
    // ═══════════════════════════════════════════════════════════════

    function test_TradingPausePreventsTransfers() public {
        vm.prank(deployer);
        token.setTradingPaused(true);

        vm.prank(deployer);
        vm.expectRevert(GreenHat.TradingPausedError.selector);
        token.transfer(alice, 100);
    }

    function test_TradingPauseUnpause() public {
        vm.prank(deployer);
        token.setTradingPaused(true);
        vm.prank(deployer);
        token.setTradingPaused(false);

        vm.prank(deployer);
        token.transfer(alice, 100);

        assertEq(token.balanceOf(alice), 100);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Ownership (single-step via Ownable)
    // ═══════════════════════════════════════════════════════════════

    function test_TransferOwnership() public {
        vm.prank(deployer);
        token.transferOwnership(alice);

        assertEq(token.owner(), alice);
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.transferOwnership(bob);
    }

    function test_RevertWhen_TransferOwnershipToZero() public {
        vm.prank(deployer);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableInvalidOwner.selector, address(0)));
        token.transferOwnership(address(0));
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: DEX Pair
    // ═══════════════════════════════════════════════════════════════

    function test_SetDexPair() public {
        vm.prank(deployer);
        token.setDexPair(dex);

        assertEq(token.dexPair(), dex);
        assertTrue(token.isExcludedFromLimits(dex));
    }

    function test_RevertWhen_NonOwnerSetsDexPair() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.setDexPair(dex);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Limits
    // ═══════════════════════════════════════════════════════════════

    function test_SetLimits() public {
        uint256 newMaxWallet = MAX_SUPPLY * 3 / 100;
        uint256 newMaxTx = MAX_SUPPLY * 2 / 100;

        vm.prank(deployer);
        token.setLimits(newMaxWallet, newMaxTx);

        assertEq(token.maxWallet(), newMaxWallet);
        assertEq(token.maxTx(), newMaxTx);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Exclusions
    // ═══════════════════════════════════════════════════════════════

    function test_ExcludeFromLimits() public {
        vm.prank(deployer);
        token.excludeFromLimits(alice, true);

        assertTrue(token.isExcludedFromLimits(alice));
    }

    // ═══════════════════════════════════════════════════════════════
    //  Fuzz Tests
    // ═══════════════════════════════════════════════════════════════

    function testFuzz_Transfer(
        uint256 amount
    ) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);

        vm.prank(deployer);
        assertTrue(token.transfer(alice, amount));

        assertEq(token.balanceOf(deployer), MAX_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function testFuzz_TransferFrom(
        uint256 approval,
        uint256 amount
    ) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);
        vm.assume(approval >= amount);

        vm.prank(deployer);
        token.approve(alice, approval);

        vm.prank(alice);
        assertTrue(token.transferFrom(deployer, bob, amount));

        if (approval == type(uint256).max) {
            assertEq(token.allowance(deployer, alice), type(uint256).max);
        } else {
            assertEq(token.allowance(deployer, alice), approval - amount);
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Burn
    // ═══════════════════════════════════════════════════════════════

    function test_Burn() public {
        _fund(alice);

        uint256 before = token.balanceOf(alice);
        uint256 amount = 10 * ONE_TOKEN;

        vm.prank(alice);
        token.burn(amount);

        assertEq(token.balanceOf(alice), before - amount);
        assertEq(token.totalSupply(), MAX_SUPPLY - amount);
    }

    function test_BurnFrom() public {
        _fund(alice);

        uint256 amount = 10 * ONE_TOKEN;
        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        token.burnFrom(alice, amount);

        assertEq(token.balanceOf(alice), (100 * ONE_TOKEN) - amount);
        assertEq(token.totalSupply(), MAX_SUPPLY - amount);
        assertEq(token.allowance(alice, bob), 0);
    }

    function test_BurnFromInfiniteApproval() public {
        _fund(alice);

        uint256 amount = 10 * ONE_TOKEN;
        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.burnFrom(alice, amount);

        assertEq(token.totalSupply(), MAX_SUPPLY - amount);
        assertEq(token.allowance(alice, bob), type(uint256).max);
    }

    function test_RevertWhen_BurnInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        token.burn(1);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Batch Transfer
    // ═══════════════════════════════════════════════════════════════

    function test_BatchTransfer() public {
        address[] memory recipients = new address[](3);
        recipients[0] = alice;
        recipients[1] = bob;
        recipients[2] = makeAddr("charlie");

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 10 * ONE_TOKEN;
        amounts[1] = 20 * ONE_TOKEN;
        amounts[2] = 30 * ONE_TOKEN;

        uint256 total = 60 * ONE_TOKEN;
        uint256 deployerBefore = token.balanceOf(deployer);

        vm.prank(deployer);
        token.batchTransfer(recipients, amounts);

        assertEq(token.balanceOf(alice), 10 * ONE_TOKEN);
        assertEq(token.balanceOf(bob), 20 * ONE_TOKEN);
        assertEq(token.balanceOf(makeAddr("charlie")), 30 * ONE_TOKEN);
        assertEq(token.balanceOf(deployer), deployerBefore - total);
    }

    function test_RevertWhen_BatchTransferLengthMismatch() public {
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;

        uint256[] memory amounts = new uint256[](3);

        vm.prank(deployer);
        vm.expectRevert(GreenHat.BatchLengthMismatch.selector);
        token.batchTransfer(recipients, amounts);
    }

    function test_RevertWhen_NonOwnerBatchTransfer() public {
        address[] memory recipients = new address[](1);
        recipients[0] = alice;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.batchTransfer(recipients, amounts);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Helpers
    // ═══════════════════════════════════════════════════════════════

    function _fund(
        address to
    ) internal {
        _fund(to, 100 * ONE_TOKEN);
    }

    function _fund(
        address to,
        uint256 amount
    ) internal {
        vm.prank(deployer);
        token.transfer(to, amount);
    }
}
