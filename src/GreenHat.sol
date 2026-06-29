// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title GreenHat - The Meme Coin
/// @notice A simple, secure meme token with anti-whale and safety features
/// @dev No tax, single-step ownership via OpenZeppelin Ownable
/// @author GreenHat Team
contract GreenHat is ERC20, Ownable {
    // ═══════════════════════════════════════════════════════════════
    //  Constants
    // ═══════════════════════════════════════════════════════════════

    /// @notice Maximum token supply (1 billion)
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18;

    // ═══════════════════════════════════════════════════════════════
    //  Anti-Whale Limits
    // ═══════════════════════════════════════════════════════════════

    /// @notice Max tokens a single wallet can hold
    uint256 public maxWallet;

    /// @notice Max tokens per single transaction
    uint256 public maxTx;

    /// @notice DEX pair address (excluded from limits)
    address public dexPair;

    // ═══════════════════════════════════════════════════════════════
    //  Exclusions
    // ═══════════════════════════════════════════════════════════════

    /// @notice Whether an address is excluded from anti-whale limits
    mapping(address => bool) public isExcludedFromLimits;

    // ═══════════════════════════════════════════════════════════════
    //  Security
    // ═══════════════════════════════════════════════════════════════

    /// @notice Whether an address is blacklisted (cannot send/receive)
    mapping(address => bool) public isBlacklisted;

    /// @notice Whether trading is paused globally
    bool public tradingPaused;

    // ═══════════════════════════════════════════════════════════════
    //  Events
    // ═══════════════════════════════════════════════════════════════

    /// @notice Emitted when the DEX pair address is updated
    /// @param pair The new DEX pair address
    event DexPairUpdated(address indexed pair);

    /// @notice Emitted when anti-whale limits are updated
    /// @param maxWallet New max wallet limit
    /// @param maxTx New max transaction limit
    event LimitsUpdated(uint256 maxWallet, uint256 maxTx);

    /// @notice Emitted when an address is blacklisted or unblacklisted
    /// @param account The affected address
    /// @param status Whether it's blacklisted (true) or not (false)
    event Blacklisted(address indexed account, bool indexed status);

    /// @notice Emitted when trading is paused or unpaused
    /// @param paused Whether trading is paused (true) or not (false)
    event TradingPaused(bool indexed paused);

    /// @notice Emitted when an address is excluded or re-included from limits
    /// @param account The affected address
    /// @param excluded Whether it's excluded (true) or not (false)
    event ExcludedFromLimits(address indexed account, bool indexed excluded);

    // ═══════════════════════════════════════════════════════════════
    //  Errors
    // ═══════════════════════════════════════════════════════════════

    /// @notice Thrown when a zero address is provided where not allowed
    error ZeroAddress();

    /// @notice Thrown when a transfer would exceed the max wallet limit
    error MaxWalletExceeded();

    /// @notice Thrown when a transfer would exceed the max transaction limit
    error MaxTxExceeded();

    /// @notice Thrown when a blacklisted address attempts a transfer
    error BlacklistedAddress();

    /// @notice Thrown when trading is paused
    error TradingPausedError();

    // ═══════════════════════════════════════════════════════════════
    //  Constructor
    // ═══════════════════════════════════════════════════════════════

    /// @notice Deploy GreenHat and mint all tokens to the deployer
    /// @dev Sets default limits (2% wallet, 1% tx) and excludes core addresses
    constructor() ERC20("GreenHat", "GREEN") Ownable(msg.sender) {
        // Mint entire supply to deployer
        _mint(msg.sender, MAX_SUPPLY);

        // Limits: 2% max wallet, 1% max tx
        maxWallet = (MAX_SUPPLY * 2) / 100;
        maxTx = (MAX_SUPPLY * 1) / 100;

        // Exclude core addresses from limits
        isExcludedFromLimits[msg.sender] = true;
        isExcludedFromLimits[address(0)] = true;
        isExcludedFromLimits[address(0xdead)] = true;
        isExcludedFromLimits[address(this)] = true;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: DEX
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set the DEX pair address (also excludes it from limits)
    /// @param pair The DEX pair contract address
    function setDexPair(address pair) external onlyOwner {
        if (pair == address(0)) revert ZeroAddress();
        dexPair = pair;
        isExcludedFromLimits[pair] = true;
        emit DexPairUpdated(pair);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Limits
    // ═══════════════════════════════════════════════════════════════

    /// @notice Update max wallet and max transaction limits
    /// @param _maxWallet New max wallet amount (raw units)
    /// @param _maxTx New max transaction amount (raw units)
    function setLimits(uint256 _maxWallet, uint256 _maxTx) external onlyOwner {
        maxWallet = _maxWallet;
        maxTx = _maxTx;
        emit LimitsUpdated(_maxWallet, _maxTx);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Security
    // ═══════════════════════════════════════════════════════════════

    /// @notice Blacklist or unblacklist an address
    /// @param account The address to manage
    /// @param status True to blacklist, false to unblacklist
    function setBlacklist(address account, bool status) external onlyOwner {
        isBlacklisted[account] = status;
        emit Blacklisted(account, status);
    }

    /// @notice Pause or unpause all trading
    /// @param paused True to pause, false to unpause
    function setTradingPaused(bool paused) external onlyOwner {
        tradingPaused = paused;
        emit TradingPaused(paused);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Exclusions
    // ═══════════════════════════════════════════════════════════════

    /// @notice Exclude or re-include an address from anti-whale limits
    /// @param account The address to manage
    /// @param excluded True to exclude from limits, false to include
    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
        emit ExcludedFromLimits(account, excluded);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Burn
    // ═══════════════════════════════════════════════════════════════

    /// @notice Burn tokens from caller's balance (creates scarcity)
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /// @notice Burn tokens from another address (with allowance)
    /// @param account Address to burn from
    /// @param amount Amount of tokens to burn
    function burnFrom(address account, uint256 amount) external {
        uint256 allowed = allowance(account, msg.sender);
        if (allowed != type(uint256).max) {
            if (allowed < amount) revert InsufficientAllowance();
            unchecked { _approve(account, msg.sender, allowed - amount); }
        }
        _burn(account, amount);
        emit TokensBurned(account, amount);
    }

    /// @notice Thrown when allowance is insufficient for burnFrom
    error InsufficientAllowance();

    // ═══════════════════════════════════════════════════════════════
    //  Batch Transfer (Airdrop)
    // ═══════════════════════════════════════════════════════════════

    /// @notice Send tokens to multiple addresses in one transaction
    /// @param recipients Array of recipient addresses
    /// @param amounts Array of amounts (must match recipients length)
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint256 len = recipients.length;
        if (len != amounts.length) revert BatchLengthMismatch();
        for (uint256 i; i < len; ++i) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    /// @notice Thrown when recipients and amounts arrays have different lengths
    error BatchLengthMismatch();

    // ═══════════════════════════════════════════════════════════════
    //  Events
    // ═══════════════════════════════════════════════════════════════

    /// @notice Emitted when tokens are burned
    /// @param account The address that burned tokens
    /// @param amount The amount burned
    event TokensBurned(address indexed account, uint256 amount);

    // ═══════════════════════════════════════════════════════════════
    //  Core Transfer Hook
    // ═══════════════════════════════════════════════════════════════

    /// @notice ERC-20 transfer hook — applies security checks and limits
    /// @param from Sender address
    /// @param to Recipient address
    /// @param value Amount of tokens
    function _update(address from, address to, uint256 value) internal override {
        // Security checks
        if (isBlacklisted[from] || isBlacklisted[to]) revert BlacklistedAddress();
        if (tradingPaused) revert TradingPausedError();

        // Anti-whale limits
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
}
