// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title GreenHat - The Meme Coin
/// @notice A simple, secure meme token with anti-whale and safety features
/// @dev No tax, single-step ownership
contract GreenHat is ERC20, Ownable {
    // ═══════════════════════════════════════════════════════════════
    //  Constants
    // ═══════════════════════════════════════════════════════════════

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion

    // ═══════════════════════════════════════════════════════════════
    //  Limits (Anti-Whale)
    // ═══════════════════════════════════════════════════════════════

    uint256 public maxWallet;      // max tokens per wallet
    uint256 public maxTx;          // max tokens per transaction

    // ═══════════════════════════════════════════════════════════════
    //  DEX Pair (excluded from limits)
    // ═══════════════════════════════════════════════════════════════

    address public dexPair;

    // ═══════════════════════════════════════════════════════════════
    //  Exclusions
    // ═══════════════════════════════════════════════════════════════

    mapping(address => bool) public isExcludedFromLimits;

    // ═══════════════════════════════════════════════════════════════
    //  Security
    // ═══════════════════════════════════════════════════════════════

    mapping(address => bool) public isBlacklisted;
    bool public tradingPaused;

    // ═══════════════════════════════════════════════════════════════
    //  Events
    // ═══════════════════════════════════════════════════════════════

    event DexPairUpdated(address indexed pair);
    event LimitsUpdated(uint256 maxWallet, uint256 maxTx);
    event Blacklisted(address indexed account, bool indexed status);
    event TradingPaused(bool indexed paused);
    event ExcludedFromLimits(address indexed account, bool indexed excluded);

    // ═══════════════════════════════════════════════════════════════
    //  Errors
    // ═══════════════════════════════════════════════════════════════

    error ZeroAddress();
    error MaxWalletExceeded();
    error MaxTxExceeded();
    error BlacklistedAddress();
    error TradingPausedError();

    // ═══════════════════════════════════════════════════════════════
    //  Constructor
    // ═══════════════════════════════════════════════════════════════

    constructor() ERC20("GreenHat", "GREEN") Ownable(msg.sender) {
        // ── Mint entire supply to deployer ──
        _mint(msg.sender, MAX_SUPPLY);

        // ── Limits: 2% max wallet, 1% max tx ──
        maxWallet = (MAX_SUPPLY * 2) / 100;
        maxTx = (MAX_SUPPLY * 1) / 100;

        // ── Exclude core addresses from limits ──
        isExcludedFromLimits[msg.sender] = true;
        isExcludedFromLimits[address(0)] = true;
        isExcludedFromLimits[address(0xdead)] = true;
        isExcludedFromLimits[address(this)] = true;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Core Transfer Hook
    // ═══════════════════════════════════════════════════════════════

    function _update(address from, address to, uint256 value) internal override {
        // ── Security checks ──
        if (isBlacklisted[from] || isBlacklisted[to]) revert BlacklistedAddress();
        if (tradingPaused) revert TradingPausedError();

        // ── Anti-whale limits ──
        if (
            !isExcludedFromLimits[from]
                && !isExcludedFromLimits[to]
                && from != address(0)
                && to != address(0)
        ) {
            if (value > maxTx) revert MaxTxExceeded();
            if (to != dexPair) {
                if (balanceOf(to) + value > maxWallet) revert MaxWalletExceeded();
            }
        }

        super._update(from, to, value);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: DEX
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set the DEX pair address (excluded from limits)
    function setDexPair(address pair) external onlyOwner {
        if (pair == address(0)) revert ZeroAddress();
        dexPair = pair;
        isExcludedFromLimits[pair] = true;
        emit DexPairUpdated(pair);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Limits
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set max wallet and max transaction limits (in raw units)
    function setLimits(uint256 _maxWallet, uint256 _maxTx) external onlyOwner {
        maxWallet = _maxWallet;
        maxTx = _maxTx;
        emit LimitsUpdated(_maxWallet, _maxTx);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Security
    // ═══════════════════════════════════════════════════════════════

    function setBlacklist(address account, bool status) external onlyOwner {
        isBlacklisted[account] = status;
        emit Blacklisted(account, status);
    }

    function setTradingPaused(bool paused) external onlyOwner {
        tradingPaused = paused;
        emit TradingPaused(paused);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Exclusions
    // ═══════════════════════════════════════════════════════════════

    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
        emit ExcludedFromLimits(account, excluded);
    }
}
