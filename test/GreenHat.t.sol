// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GreenHat} from "../src/GreenHat.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract GreenHatTest is Test {
    GreenHat public token;
    address public deployer = makeAddr("deployer");
    address public alice   = makeAddr("alice");
    address public bob     = makeAddr("bob");
    address public dex     = makeAddr("dexPair");
    address public burn    = address(0xdead);

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant ONE_TOKEN  = 10 ** 18;
    uint256 public constant DEFAULT_MAX_WALLET = MAX_SUPPLY * 2 / 100; // 2%
    uint256 public constant DEFAULT_MAX_TX    = MAX_SUPPLY * 1 / 100; // 1%

    // DEX initial funding
    uint256 public constant DEX_FUND = 100_000 * ONE_TOKEN;

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
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), MAX_SUPPLY);
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
        assertEq(token.owner(), deployer);
        assertEq(token.balanceOf(deployer), MAX_SUPPLY);
        assertEq(token.pendingOwner(), address(0));
    }

    function test_DefaultTaxRates() public view {
        assertEq(token.buyTaxRate(), 500);  // 5%
        assertEq(token.sellTaxRate(), 700); // 7%
        assertEq(token.marketingShare(), 6000); // 60%
        assertEq(token.liquidityShare(), 3000); // 30%
        assertEq(token.burnShare(), 1000);      // 10%
    }

    function test_DefaultLimits() public view {
        assertEq(token.maxWallet(), DEFAULT_MAX_WALLET);
        assertEq(token.maxTx(), DEFAULT_MAX_TX);
    }

    function test_DefaultExclusions() public view {
        assertTrue(token.isExcludedFromTax(deployer));
        assertTrue(token.isExcludedFromTax(address(0)));
        assertTrue(token.isExcludedFromTax(burn));
        assertTrue(token.isExcludedFromTax(address(token)));
        assertTrue(token.isExcludedFromLimits(deployer));
        assertTrue(token.isExcludedFromLimits(address(0)));
        assertTrue(token.isExcludedFromLimits(burn));
        assertTrue(token.isExcludedFromLimits(address(token)));
    }

    function test_DexPairNotSet() public view {
        assertEq(token.dexPair(), address(0));
    }

    function test_ReservesStartAtZero() public view {
        assertEq(token.marketingReserve(), 0);
        assertEq(token.liquidityReserve(), 0);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Basic Transfers (no DEX → no tax)
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
    //  Tax: Buy
    // ═══════════════════════════════════════════════════════════════

    function test_BuyTax() public {
        _setupDex();

        uint256 buyAmount = 1000 * ONE_TOKEN;
        uint256 expectedTax = (buyAmount * 500) / 10_000; // 5% buy tax
        uint256 expectedAfterTax = buyAmount - expectedTax;

        // Tax distribution
        uint256 expectedBurn = (expectedTax * 1000) / 10_000;
        uint256 expectedMarketing = (expectedTax * 6000) / 10_000;
        uint256 expectedLiquidity = expectedTax - expectedBurn - expectedMarketing;

        vm.prank(dex);
        token.transfer(bob, buyAmount);

        assertEq(token.balanceOf(bob), expectedAfterTax);
        // DEX: DEX_FUND - buyAmount
        assertEq(token.balanceOf(dex), DEX_FUND - buyAmount);
        assertEq(token.marketingReserve(), expectedMarketing);
        assertEq(token.liquidityReserve(), expectedLiquidity);
        assertEq(token.totalSupply(), MAX_SUPPLY - expectedBurn);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Tax: Sell
    // ═══════════════════════════════════════════════════════════════

    function test_SellTax() public {
        _setupDex();
        _fundAlice();

        // Alice sells 50 tokens to DEX (she has 100)
        uint256 sellAmount = 50 * ONE_TOKEN;
        uint256 expectedTax = (sellAmount * 700) / 10_000; // 7% sell tax
        uint256 expectedAfterTax = sellAmount - expectedTax;

        uint256 expectedBurn = (expectedTax * 1000) / 10_000;
        uint256 expectedMarketing = (expectedTax * 6000) / 10_000;
        uint256 expectedLiquidity = expectedTax - expectedBurn - expectedMarketing;

        vm.prank(alice);
        token.transfer(dex, sellAmount);

        assertEq(token.balanceOf(alice), (100 * ONE_TOKEN) - sellAmount);
        // DEX gets sellAmount - tax added on top of DEX_FUND
        assertEq(token.balanceOf(dex), DEX_FUND + expectedAfterTax);
        assertEq(token.marketingReserve(), expectedMarketing);
        assertEq(token.liquidityReserve(), expectedLiquidity);
        assertEq(token.totalSupply(), MAX_SUPPLY - expectedBurn);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Tax: No tax on regular transfers
    // ═══════════════════════════════════════════════════════════════

    function test_NoTaxOnRegularTransfer() public {
        _setupDex();
        _fundAlice();

        uint256 amount = 50 * ONE_TOKEN;
        vm.prank(alice);
        token.transfer(bob, amount);

        assertEq(token.balanceOf(alice), (100 * ONE_TOKEN) - amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.marketingReserve(), 0);
        assertEq(token.liquidityReserve(), 0);
        assertEq(token.totalSupply(), MAX_SUPPLY);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Tax: Excluded addresses don't pay tax
    // ═══════════════════════════════════════════════════════════════

    function test_ExcludedFromTax() public {
        _setupDex();

        // Deployer is excluded from tax
        uint256 amount = 1000 * ONE_TOKEN;
        uint256 dexBefore = token.balanceOf(dex);

        vm.prank(deployer);
        token.transfer(dex, amount);

        // No tax taken, DEX gets full amount
        assertEq(token.balanceOf(dex), dexBefore + amount);
        assertEq(token.marketingReserve(), 0);
        assertEq(token.liquidityReserve(), 0);
        assertEq(token.totalSupply(), MAX_SUPPLY);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Tax Collection
    // ═══════════════════════════════════════════════════════════════

    function test_CollectMarketing() public {
        _setupDexAndGenerateTax();

        uint256 reserveBefore = token.marketingReserve();
        assertGt(reserveBefore, 0);

        uint256 marketingBalBefore = token.balanceOf(deployer);

        vm.prank(deployer);
        token.collectMarketing();

        assertEq(token.marketingReserve(), 0);
        assertEq(token.balanceOf(deployer), marketingBalBefore + reserveBefore);
    }

    function test_CollectLiquidity() public {
        _setupDexAndGenerateTax();

        uint256 reserveBefore = token.liquidityReserve();
        assertGt(reserveBefore, 0);

        uint256 liqBalBefore = token.balanceOf(deployer);

        vm.prank(deployer);
        token.collectLiquidity();

        assertEq(token.liquidityReserve(), 0);
        assertEq(token.balanceOf(deployer), liqBalBefore + reserveBefore);
    }

    function test_RevertWhen_NoTaxToCollectMarketing() public {
        vm.prank(deployer);
        vm.expectRevert(GreenHat.NoTaxToCollect.selector);
        token.collectMarketing();
    }

    function test_RevertWhen_NoTaxToCollectLiquidity() public {
        vm.prank(deployer);
        vm.expectRevert(GreenHat.NoTaxToCollect.selector);
        token.collectLiquidity();
    }

    // ═══════════════════════════════════════════════════════════════
    //  Limits: Max Wallet
    // ═══════════════════════════════════════════════════════════════

    function test_RevertWhen_ExceedMaxWallet() public {
        _setupDex();

        // Give bob almost maxWallet, and alice some tokens
        _fundAddress(bob, DEFAULT_MAX_WALLET);
        _fundAddress(alice, 100 * ONE_TOKEN);
        vm.prank(deployer);
        token.excludeFromLimits(alice, false);

        // Alice sends 1 token to bob → bob would exceed maxWallet
        vm.prank(alice);
        vm.expectRevert(GreenHat.MaxWalletExceeded.selector);
        token.transfer(bob, 1);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Limits: Max Transaction
    // ═══════════════════════════════════════════════════════════════

    function test_RevertWhen_ExceedMaxTx() public {
        _setupDex();
        // Give alice enough tokens but remove from limits exclusion
        _fundAddress(alice, DEFAULT_MAX_TX + 1);
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

        _fundAlice();

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
    //  Ownership (2-step)
    // ═══════════════════════════════════════════════════════════════

    function test_TransferOwnership() public {
        vm.prank(deployer);
        token.transferOwnership(alice);

        assertEq(token.pendingOwner(), alice);
    }

    function test_AcceptOwnership() public {
        vm.prank(deployer);
        token.transferOwnership(alice);

        vm.prank(alice);
        token.acceptOwnership();

        assertEq(token.owner(), alice);
        assertEq(token.pendingOwner(), address(0));
    }

    function test_RevertWhen_NonPendingOwnerAccepts() public {
        vm.prank(deployer);
        token.transferOwnership(alice);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, bob));
        token.acceptOwnership();
    }

    function test_RevertWhen_NonOwnerTransfersOwnership() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        token.transferOwnership(bob);
    }

    function test_TransferOwnershipToZeroCancelsPending() public {
        // Start a transfer to alice
        vm.prank(deployer);
        token.transferOwnership(alice);
        assertEq(token.pendingOwner(), alice);

        // Cancel by transferring to zero
        vm.prank(deployer);
        token.transferOwnership(address(0));
        assertEq(token.pendingOwner(), address(0));
        assertEq(token.owner(), deployer);
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
    //  Admin: Tax Rates
    // ═══════════════════════════════════════════════════════════════

    function test_SetTaxRates() public {
        vm.prank(deployer);
        token.setTaxRates(300, 500);

        assertEq(token.buyTaxRate(), 300);
        assertEq(token.sellTaxRate(), 500);
    }

    function test_RevertWhen_TaxRateTooHigh() public {
        vm.prank(deployer);
        vm.expectRevert(GreenHat.InvalidRate.selector);
        token.setTaxRates(1001, 500);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Tax Shares
    // ═══════════════════════════════════════════════════════════════

    function test_SetTaxShares() public {
        vm.prank(deployer);
        token.setTaxShares(5000, 3000, 2000);

        assertEq(token.marketingShare(), 5000);
        assertEq(token.liquidityShare(), 3000);
        assertEq(token.burnShare(), 2000);
    }

    function test_RevertWhen_InvalidTaxShares() public {
        vm.prank(deployer);
        vm.expectRevert(GreenHat.InvalidShares.selector);
        token.setTaxShares(5000, 3000, 1000); // sums to 9000
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
    //  Admin: Wallets
    // ═══════════════════════════════════════════════════════════════

    function test_SetMarketingWallet() public {
        vm.prank(deployer);
        token.setMarketingWallet(alice);

        assertEq(token.marketingWallet(), alice);
    }

    function test_SetLiquidityWallet() public {
        vm.prank(deployer);
        token.setLiquidityWallet(alice);

        assertEq(token.liquidityWallet(), alice);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Exclusions
    // ═══════════════════════════════════════════════════════════════

    function test_ExcludeFromTax() public {
        vm.prank(deployer);
        token.excludeFromTax(alice, true);

        assertTrue(token.isExcludedFromTax(alice));
    }

    function test_ExcludeFromLimits() public {
        vm.prank(deployer);
        token.excludeFromLimits(alice, true);

        assertTrue(token.isExcludedFromLimits(alice));
    }

    // ═══════════════════════════════════════════════════════════════
    //  Fuzz Tests
    // ═══════════════════════════════════════════════════════════════

    function testFuzz_Transfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);

        vm.prank(deployer);
        assertTrue(token.transfer(alice, amount));

        assertEq(token.balanceOf(deployer), MAX_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function testFuzz_TransferFrom(uint256 approval, uint256 amount) public {
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
    //  Helpers
    // ═══════════════════════════════════════════════════════════════

    function _setupDex() internal {
        vm.prank(deployer);
        token.setDexPair(dex);

        vm.prank(deployer);
        token.transfer(dex, DEX_FUND);
    }

    function _fundAlice() internal {
        vm.prank(deployer);
        token.transfer(alice, 100 * ONE_TOKEN);
    }

    function _fundAddress(address to, uint256 amount) internal {
        vm.prank(deployer);
        token.transfer(to, amount);
    }

    function _setupDexAndGenerateTax() internal {
        _setupDex();
        _fundAlice();

        // Alice sells to DEX → generates tax reserves
        vm.prank(alice);
        token.transfer(dex, 50 * ONE_TOKEN);
    }
}
