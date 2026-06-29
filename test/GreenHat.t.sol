// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GreenHat} from "../src/GreenHat.sol";

contract GreenHatTest is Test {
    GreenHat public token;
    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    function setUp() public {
        vm.prank(deployer);
        token = new GreenHat();
    }

    // ─── Deployment ───────────────────────────────────────────────

    function test_Deployment() public view {
        assertEq(token.name(), "GreenHat");
        assertEq(token.symbol(), "GHAT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), MAX_SUPPLY);
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
        assertEq(token.owner(), deployer);
        assertEq(token.balanceOf(deployer), MAX_SUPPLY);
    }

    // ─── Transfer ─────────────────────────────────────────────────

    function test_Transfer() public {
        uint256 amount = 100 * 10 ** 18;
        vm.prank(deployer);
        assertTrue(token.transfer(alice, amount));

        assertEq(token.balanceOf(deployer), MAX_SUPPLY - amount);
        assertEq(token.balanceOf(alice), amount);
    }

    function test_RevertWhen_TransferInsufficientBalance() public {
        uint256 amount = 1;
        vm.prank(alice);
        vm.expectRevert(GreenHat.InsufficientBalance.selector);
        token.transfer(bob, amount);
    }

    function test_RevertWhen_TransferToZeroAddress() public {
        vm.prank(deployer);
        vm.expectRevert(GreenHat.ZeroAddress.selector);
        token.transfer(address(0), 100);
    }

    // ─── Approve & TransferFrom ───────────────────────────────────

    function test_Approve() public {
        vm.prank(deployer);
        token.approve(alice, 1000);

        assertEq(token.allowance(deployer, alice), 1000);
    }

    function test_TransferFrom() public {
        uint256 amount = 50 * 10 ** 18;
        vm.prank(deployer);
        token.approve(alice, amount);

        vm.prank(alice);
        assertTrue(token.transferFrom(deployer, bob, amount));

        assertEq(token.balanceOf(deployer), MAX_SUPPLY - amount);
        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(deployer, alice), 0);
    }

    function test_TransferFromWithInfiniteApproval() public {
        uint256 amount = 50 * 10 ** 18;
        vm.prank(deployer);
        token.approve(alice, type(uint256).max);

        vm.prank(alice);
        assertTrue(token.transferFrom(deployer, bob, amount));

        // Infinite approval should remain unchanged
        assertEq(token.allowance(deployer, alice), type(uint256).max);
    }

    function test_RevertWhen_InsufficientAllowance() public {
        vm.prank(deployer);
        token.approve(alice, 100);

        vm.prank(alice);
        vm.expectRevert(GreenHat.InsufficientAllowance.selector);
        token.transferFrom(deployer, bob, 101);
    }

    // ─── Ownership ────────────────────────────────────────────────

    function test_RenounceOwnership() public {
        vm.prank(deployer);
        token.renounceOwnership();

        assertEq(token.owner(), address(0));
    }

    function test_RevertWhen_NonOwnerRenounces() public {
        vm.prank(alice);
        vm.expectRevert(GreenHat.Unauthorized.selector);
        token.renounceOwnership();
    }

    // ─── Fuzz Tests ───────────────────────────────────────────────

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
}
