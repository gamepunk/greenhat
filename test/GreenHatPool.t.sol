// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { GreenHat } from "../src/GreenHat.sol";
import { GreenHatPool } from "../src/GreenHatPool.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract GreenHatPoolTest is Test {
    GreenHat public token;
    GreenHatPool public pool;

    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant ONE_GREEN = 10 ** 4;
    uint256 public constant LIQ_GREEN = 210_000 * ONE_GREEN; // 1% of 21M
    uint256 public constant LIQ_POL = 0.01 ether;

    function setUp() public {
        vm.prank(deployer);
        token = new GreenHat();

        vm.prank(deployer);
        pool = new GreenHatPool(address(token));

        // Fund deployer with POL and approve pool
        vm.deal(deployer, LIQ_POL);
        vm.prank(deployer);
        token.approve(address(pool), LIQ_GREEN);
        vm.prank(deployer);
        pool.addLiquidity{ value: LIQ_POL }(LIQ_GREEN);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Deployment
    // ═══════════════════════════════════════════════════════════════

    function test_Constructor() public view {
        assertEq(address(pool.green()), address(token));
        assertEq(pool.owner(), deployer);
    }

    function test_InitialReserves() public view {
        assertEq(pool.greenReserve(), LIQ_GREEN);
        assertEq(pool.polReserve(), LIQ_POL);
    }

    function test_InitialPrice() public view {
        // 1 POL = 21M GREEN (0.01 POL for 210k GREEN)
        assertEq(pool.price(), (LIQ_POL * 1e18) / LIQ_GREEN);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Add Liquidity
    // ═══════════════════════════════════════════════════════════════

    function test_RevertWhen_NonOwnerAddsLiquidity() public {
        vm.deal(alice, 0.01 ether);
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        pool.addLiquidity{ value: 0.01 ether }(1000 * ONE_GREEN);
    }

    function test_RevertWhen_ZeroAmount() public {
        vm.prank(deployer);
        vm.expectRevert(GreenHatPool.ZeroAmount.selector);
        pool.addLiquidity{ value: 0 }(0);
    }

    function test_RevertWhen_InvalidRatio() public {
        // Approve enough for a second liquidity addition
        vm.prank(deployer);
        token.approve(address(pool), 1000 * ONE_GREEN);

        vm.deal(deployer, 0.1 ether);
        vm.prank(deployer);
        vm.expectRevert(GreenHatPool.InvalidRatio.selector);
        pool.addLiquidity{ value: 0.1 ether }(1000 * ONE_GREEN);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Buy GREEN
    // ═══════════════════════════════════════════════════════════════

    function test_BuyGreen() public {
        uint256 polIn = 0.001 ether;
        uint256 expected = (polIn * LIQ_GREEN) / (LIQ_POL + polIn);

        uint256 greenBefore = token.balanceOf(alice);

        vm.deal(alice, polIn);
        vm.prank(alice);
        pool.buyGreen{ value: polIn }(0);

        uint256 greenOut = token.balanceOf(alice) - greenBefore;
        assertEq(greenOut, expected);
    }

    function test_BuyGreenWithMinOut() public {
        uint256 polIn = 0.001 ether;
        uint256 expected = (polIn * LIQ_GREEN) / (LIQ_POL + polIn);

        vm.deal(alice, polIn);
        vm.prank(alice);
        pool.buyGreen{ value: polIn }(expected);
        assertTrue(expected > 0);
    }

    function test_RevertWhen_BuyGreenZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(GreenHatPool.ZeroAmount.selector);
        pool.buyGreen{ value: 0 }(100);
    }

    function test_RevertWhen_BuyGreenInsufficientOutput() public {
        vm.deal(alice, 0.001 ether);
        vm.prank(alice);
        vm.expectRevert(GreenHatPool.InsufficientOutput.selector);
        pool.buyGreen{ value: 0.001 ether }(type(uint256).max);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Sell GREEN
    // ═══════════════════════════════════════════════════════════════

    function test_SellGreen() public {
        // First alice buys GREEN
        vm.deal(alice, 0.001 ether);
        vm.prank(alice);
        pool.buyGreen{ value: 0.001 ether }(0);
        uint256 greenBalance = token.balanceOf(alice);

        // Then sells a portion — use current reserves for expected value
        uint256 sellAmount = greenBalance / 2;
        uint256 expectedPol = (sellAmount * pool.polReserve()) / (pool.greenReserve() + sellAmount);

        vm.prank(alice);
        token.approve(address(pool), sellAmount);

        uint256 polBefore = alice.balance;

        vm.prank(alice);
        pool.sellGreen(sellAmount, 0);

        uint256 polOut = alice.balance - polBefore;
        assertEq(polOut, expectedPol);
    }

    function test_SellGreenWithMinOut() public {
        vm.deal(alice, 0.001 ether);
        vm.prank(alice);
        pool.buyGreen{ value: 0.001 ether }(0);
        uint256 greenBalance = token.balanceOf(alice);

        uint256 sellAmount = greenBalance / 2;
        uint256 expectedPol = (sellAmount * pool.polReserve()) / (pool.greenReserve() + sellAmount);

        vm.prank(alice);
        token.approve(address(pool), sellAmount);

        vm.prank(alice);
        pool.sellGreen(sellAmount, expectedPol);
    }

    function test_RevertWhen_SellGreenZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(GreenHatPool.ZeroAmount.selector);
        pool.sellGreen(0, 0);
    }

    function test_RevertWhen_SellGreenInsufficientOutput() public {
        vm.deal(alice, 0.001 ether);
        vm.prank(alice);
        pool.buyGreen{ value: 0.001 ether }(0);
        uint256 greenBalance = token.balanceOf(alice);

        vm.prank(alice);
        token.approve(address(pool), greenBalance);

        vm.prank(alice);
        vm.expectRevert(GreenHatPool.InsufficientOutput.selector);
        pool.sellGreen(greenBalance, type(uint256).max);
    }

    function test_RevertWhen_SellGreenWithoutApproval() public {
        vm.deal(alice, 0.001 ether);
        vm.prank(alice);
        pool.buyGreen{ value: 0.001 ether }(0);
        uint256 greenBalance = token.balanceOf(alice);

        // No approval
        vm.prank(alice);
        vm.expectRevert();
        pool.sellGreen(greenBalance, 0);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Remove Liquidity
    // ═══════════════════════════════════════════════════════════════

    function test_RemoveLiquidity() public {
        uint256 greenBefore = token.balanceOf(deployer);
        uint256 polBefore = deployer.balance;

        vm.prank(deployer);
        pool.removeLiquidity();

        assertEq(token.balanceOf(deployer), greenBefore + LIQ_GREEN);
        assertEq(deployer.balance, polBefore + LIQ_POL);
        assertEq(pool.greenReserve(), 0);
        assertEq(pool.polReserve(), 0);
    }

    function test_RevertWhen_NonOwnerRemovesLiquidity() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice)
        );
        pool.removeLiquidity();
    }

    // ═══════════════════════════════════════════════════════════════
    //  Price
    // ═══════════════════════════════════════════════════════════════

    function test_PriceAfterBuy() public {
        uint256 polIn = 0.001 ether;
        uint256 greenOut = (polIn * LIQ_GREEN) / (LIQ_POL + polIn);

        vm.deal(alice, polIn);
        vm.prank(alice);
        pool.buyGreen{ value: polIn }(0);

        // After buy: greenReserve ↓, polReserve ↑ → price ↑ (GREEN more valuable)
        uint256 newGreenReserve = LIQ_GREEN - greenOut;
        uint256 newPolReserve = LIQ_POL + polIn;
        uint256 expectedPrice = (newPolReserve * 1e18) / newGreenReserve;

        assertGt(pool.price(), 0);
        assertEq(pool.price(), expectedPrice);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Receive POL
    // ═══════════════════════════════════════════════════════════════

    function test_ReceivePol() public {
        uint256 balanceBefore = address(pool).balance;
        vm.prank(alice);
        vm.deal(alice, 1 ether);
        (bool ok,) = address(pool).call{ value: 0.1 ether }("");
        assertTrue(ok);
        assertEq(address(pool).balance, balanceBefore + 0.1 ether);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Fuzz Tests
    // ═══════════════════════════════════════════════════════════════

    function testFuzz_BuyGreen(uint256 polIn) public {
        vm.assume(polIn > 0 && polIn <= LIQ_POL);
        uint256 expected = (polIn * LIQ_GREEN) / (LIQ_POL + polIn);

        vm.deal(alice, polIn);
        vm.prank(alice);
        pool.buyGreen{ value: polIn }(expected > 0 ? expected - 1 : 0);
    }

    function testFuzz_SellGreen(uint256 polIn, uint256 sellPct) public {
        vm.assume(polIn > 0 && polIn <= LIQ_POL);
        vm.assume(sellPct > 0 && sellPct <= 100);

        // Buy first
        vm.deal(alice, polIn);
        vm.prank(alice);
        pool.buyGreen{ value: polIn }(0);
        uint256 greenBalance = token.balanceOf(alice);

        uint256 sellAmount = (greenBalance * sellPct) / 100;
        vm.assume(sellAmount > 0);

        vm.prank(alice);
        token.approve(address(pool), sellAmount);

        uint256 expectedPol = (sellAmount * pool.polReserve()) / (pool.greenReserve() + sellAmount);

        vm.prank(alice);
        pool.sellGreen(sellAmount, expectedPol > 0 ? expectedPol - 1 : 0);
    }
}
