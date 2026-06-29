// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title GreenHat - The Meme Coin
/// @notice A simple, transparent, and community-driven meme token
/// @dev Total supply: 1,000,000,000 GHAT
contract GreenHat {
    string public constant name = "GreenHat";
    string public constant symbol = "GHAT";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion

    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);

    error Unauthorized();
    error InsufficientBalance();
    error InsufficientAllowance();
    error ZeroAddress();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply = MAX_SUPPLY;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (allowed < value) revert InsufficientAllowance();
            allowance[from][msg.sender] = allowed - value;
        }
        return _transfer(from, to, value);
    }

    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        if (to == address(0)) revert ZeroAddress();
        uint256 balance = balanceOf[from];
        if (balance < value) revert InsufficientBalance();
        balanceOf[from] = balance - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }

    /// @notice Renounce contract ownership (irreversible)
    function renounceOwnership() external onlyOwner {
        address previousOwner = owner;
        owner = address(0);
        emit OwnershipRenounced(previousOwner);
    }
}
