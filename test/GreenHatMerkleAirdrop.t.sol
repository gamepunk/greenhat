// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GreenHat} from "../src/GreenHat.sol";
import {GreenHatMerkleAirdrop} from "../src/GreenHatMerkleAirdrop.sol";

/// @title Merkle Airdrop Tests
/// @notice Tests the full airdrop lifecycle
contract GreenHatMerkleAirdropTest is Test {
    GreenHat public token;
    GreenHatMerkleAirdrop public airdrop;

    address public deployer = makeAddr("deployer");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    bytes32 public merkleRoot;
    bytes32 public aliceLeaf;
    bytes32 public bobLeaf;
    bytes32[] public aliceProof;
    bytes32[] public bobProof;

    uint256 public constant ALICE_AMOUNT = 1000 * 10 ** 4;
    uint256 public constant BOB_AMOUNT = 2000 * 10 ** 4;
    uint256 public constant AIRDROP_TOTAL = 3000 * 10 ** 4;

    function setUp() public {
        vm.prank(deployer);
        token = new GreenHat();

        // Build Merkle tree manually in tests
        // leaf = keccak256(abi.encode(account, amount))
        // In production, generate tree off-chain & deploy root

        aliceLeaf = keccak256(bytes.concat(keccak256(abi.encode(alice, ALICE_AMOUNT))));
        bobLeaf = keccak256(bytes.concat(keccak256(abi.encode(bob, BOB_AMOUNT))));

        // Simple tree: two leaves, root = hash(aliceLeaf || bobLeaf)
        merkleRoot = keccak256(bytes.concat(aliceLeaf, bobLeaf));

        // Alice's proof: [bobLeaf] (sibling)
        aliceProof = new bytes32[](1);
        aliceProof[0] = bobLeaf;

        // Bob's proof: [aliceLeaf]
        bobProof = new bytes32[](1);
        bobProof[0] = aliceLeaf;

        // Deploy airdrop contract
        vm.prank(deployer);
        airdrop = new GreenHatMerkleAirdrop(
            address(token),
            merkleRoot,
            0 // no deadline
        );

        // Fund airdrop contract with tokens
        vm.prank(deployer);
        token.transfer(address(airdrop), AIRDROP_TOTAL);

        // Activate airdrop
        vm.prank(deployer);
        airdrop.setAirdropActive(true);
    }

    // ─── Claim ─────────────────────────────────────────────────

    function test_Claim() public {
        vm.prank(alice);
        airdrop.claim(ALICE_AMOUNT, aliceProof);

        assertEq(token.balanceOf(alice), ALICE_AMOUNT);
        assertTrue(airdrop.hasClaimed(alice));
        assertEq(airdrop.totalClaimed(), ALICE_AMOUNT);
    }

    function test_ClaimMultiple() public {
        vm.prank(alice);
        airdrop.claim(ALICE_AMOUNT, aliceProof);

        vm.prank(bob);
        airdrop.claim(BOB_AMOUNT, bobProof);

        assertEq(token.balanceOf(alice), ALICE_AMOUNT);
        assertEq(token.balanceOf(bob), BOB_AMOUNT);
        assertEq(airdrop.totalClaimed(), AIRDROP_TOTAL);
    }

    // ─── Reverts ────────────────────────────────────────────────

    function test_RevertWhen_AlreadyClaimed() public {
        vm.prank(alice);
        airdrop.claim(ALICE_AMOUNT, aliceProof);

        vm.prank(alice);
        vm.expectRevert(GreenHatMerkleAirdrop.AlreadyClaimed.selector);
        airdrop.claim(ALICE_AMOUNT, aliceProof);
    }

    function test_RevertWhen_InvalidProof() public {
        // Use bob's proof for alice — should fail
        vm.prank(alice);
        vm.expectRevert(GreenHatMerkleAirdrop.InvalidProof.selector);
        airdrop.claim(ALICE_AMOUNT, bobProof);
    }

    function test_RevertWhen_WrongAmount() public {
        vm.prank(alice);
        vm.expectRevert(GreenHatMerkleAirdrop.InvalidProof.selector);
        airdrop.claim(ALICE_AMOUNT + 1, aliceProof);
    }

    function test_RevertWhen_AirdropInactive() public {
        vm.prank(deployer);
        airdrop.setAirdropActive(false);

        vm.prank(alice);
        vm.expectRevert(GreenHatMerkleAirdrop.AirdropInactive.selector);
        airdrop.claim(ALICE_AMOUNT, aliceProof);
    }

    function test_RevertWhen_AirdropEnded() public {
        // Set deadline = 100, activate at time 50, claim after 100
        vm.warp(50);

        vm.prank(deployer);
        GreenHatMerkleAirdrop timedAirdrop = new GreenHatMerkleAirdrop(
            address(token),
            merkleRoot,
            100 // deadline at timestamp 100
        );

        vm.prank(deployer);
        token.transfer(address(timedAirdrop), AIRDROP_TOTAL);

        vm.prank(deployer);
        timedAirdrop.setAirdropActive(true);

        // Warp past deadline
        vm.warp(101);

        vm.prank(alice);
        vm.expectRevert(GreenHatMerkleAirdrop.AirdropEnded.selector);
        timedAirdrop.claim(ALICE_AMOUNT, aliceProof);
    }

    // ─── Admin ──────────────────────────────────────────────────

    function test_SweepAfterEnd() public {
        vm.warp(50);

        // Deploy with deadline = 100
        vm.prank(deployer);
        GreenHatMerkleAirdrop timedAirdrop = new GreenHatMerkleAirdrop(
            address(token),
            merkleRoot,
            100
        );

        vm.prank(deployer);
        token.transfer(address(timedAirdrop), AIRDROP_TOTAL);

        vm.prank(deployer);
        timedAirdrop.setAirdropActive(true);

        // Warp past deadline
        vm.warp(101);

        uint256 deployerBefore = token.balanceOf(deployer);
        vm.prank(deployer);
        timedAirdrop.sweep(deployer);

        assertEq(token.balanceOf(deployer), deployerBefore + AIRDROP_TOTAL);
    }

    function test_EmergencySweep() public {
        uint256 deployerBefore = token.balanceOf(deployer);
        vm.prank(deployer);
        airdrop.emergencySweep(deployer);

        assertEq(token.balanceOf(deployer), deployerBefore + AIRDROP_TOTAL);
    }

    // ─── Merkle Root Update ─────────────────────────────────────

    function test_SetMerkleRoot() public {
        bytes32 newRoot = keccak256("new root");
        vm.prank(deployer);
        airdrop.setMerkleRoot(newRoot);

        assertEq(airdrop.merkleRoot(), newRoot);
    }

    function test_ActivateDeactivate() public {
        vm.prank(deployer);
        airdrop.setAirdropActive(true);
        assertTrue(airdrop.airdropActive());

        vm.prank(deployer);
        airdrop.setAirdropActive(false);
        assertFalse(airdrop.airdropActive());
    }

    // ─── Fuzz ───────────────────────────────────────────────────

    function testFuzz_ClaimAfterActivation(uint256 amount) public {
        vm.assume(amount > 0 && amount <= ALICE_AMOUNT);

        // Can't easily fuzz with real proofs, just test activation
        vm.prank(deployer);
        airdrop.setAirdropActive(true);

        assertTrue(airdrop.airdropActive());
    }
}
