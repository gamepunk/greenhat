// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title GreenHatMerkleAirdrop
/// @notice Merkle-tree based airdrop — gas-efficient, scalable to millions
/// @dev Owner sets Merkle root, eligible users claim their tokens
/// @author GreenHat Team
contract GreenHatMerkleAirdrop is Ownable {
    // ═══════════════════════════════════════════════════════════════
    //  State
    // ═══════════════════════════════════════════════════════════════

    /// @notice The token being airdropped
    IERC20 public immutable token;

    /// @notice Merkle root of the airdrop tree
    bytes32 public merkleRoot;

    /// @notice Whether the airdrop is active
    bool public airdropActive;

    /// @notice When the airdrop ends (0 = no deadline)
    uint256 public endTime;

    /// @notice Track who has claimed
    mapping(address => bool) public hasClaimed;

    /// @notice Total tokens claimed so far
    uint256 public totalClaimed;

    // ═══════════════════════════════════════════════════════════════
    //  Events
    // ═══════════════════════════════════════════════════════════════

    /// @notice Emitted when a user claims their airdrop
    /// @param user The claimant
    /// @param amount Amount claimed
    event Claimed(address indexed user, uint256 amount);

    /// @notice Emitted when Merkle root is updated
    /// @param root New Merkle root
    event MerkleRootUpdated(bytes32 root);

    /// @notice Emitted when airdrop is activated or deactivated
    /// @param active New state
    event AirdropActive(bool indexed active);

    /// @notice Emitted when the end time is updated
    /// @param endTime New end timestamp
    event EndTimeUpdated(uint256 endTime);

    /// @notice Emitted when unclaimed tokens are swept
    /// @param to Recipient of swept tokens
    /// @param amount Amount swept
    event Swept(address indexed to, uint256 amount);

    // ═══════════════════════════════════════════════════════════════
    //  Errors
    // ═══════════════════════════════════════════════════════════════

    error AlreadyClaimed();
    error AirdropInactive();
    error AirdropEnded();
    error InvalidProof();
    error NoTokensToSweep();
    error TransferFailed();

    // ═══════════════════════════════════════════════════════════════
    //  Constructor
    // ═══════════════════════════════════════════════════════════════

    /// @notice Create a new airdrop campaign
    /// @param _token The ERC-20 token address to airdrop
    /// @param _merkleRoot Initial Merkle root
    /// @param _endTime End timestamp (0 = no deadline)
    constructor(
        address _token,
        bytes32 _merkleRoot,
        uint256 _endTime
    ) Ownable(msg.sender) {
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
        endTime = _endTime;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Claim
    // ═══════════════════════════════════════════════════════════════

    /// @notice Claim your airdrop tokens
    /// @param amount Amount of tokens you're entitled to
    /// @param proof Merkle proof (array of sibling hashes)
    function claim(uint256 amount, bytes32[] calldata proof) external {
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (!airdropActive) revert AirdropInactive();
        if (endTime != 0 && block.timestamp > endTime) revert AirdropEnded();

        // Verify proof: leaf = keccak256(abi.encodePacked(msg.sender, amount))
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, amount))));
        if (!MerkleProof.verifyCalldata(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }

        hasClaimed[msg.sender] = true;
        totalClaimed += amount;

        bool ok = token.transfer(msg.sender, amount);
        if (!ok) revert TransferFailed();

        emit Claimed(msg.sender, amount);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set a new Merkle root (e.g., after adding more recipients)
    /// @param _merkleRoot New Merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    /// @notice Activate or deactivate the airdrop
    /// @param active Desired state
    function setAirdropActive(bool active) external onlyOwner {
        airdropActive = active;
        emit AirdropActive(active);
    }

    /// @notice Extend or shorten the airdrop deadline
    /// @param _endTime New end timestamp
    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
        emit EndTimeUpdated(_endTime);
    }

    /// @notice Sweep unclaimed tokens after airdrop ends
    /// @param to Recipient of remaining tokens
    function sweep(address to) external onlyOwner {
        if (endTime == 0 || block.timestamp <= endTime) revert AirdropInactive();
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert NoTokensToSweep();
        bool ok = token.transfer(to, balance);
        if (!ok) revert TransferFailed();
        emit Swept(to, balance);
    }

    /// @notice Emergency sweep (owner can always recover tokens)
    /// @param to Recipient of tokens
    function emergencySweep(address to) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert NoTokensToSweep();
        bool ok = token.transfer(to, balance);
        if (!ok) revert TransferFailed();
        emit Swept(to, balance);
    }
}
