// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

/// @title GreenHat - The Meme Coin
/// @notice A mature, feature-rich meme token built on OpenZeppelin
/// @dev Features: tax, anti-whale, blacklist, pause, 2-step ownership
contract GreenHat is ERC20, Ownable2Step {
    // ═══════════════════════════════════════════════════════════════
    //  Constants
    // ═══════════════════════════════════════════════════════════════

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion
    uint256 public constant TAX_DENOMINATOR = 10_000;
    uint256 public constant MAX_TAX_RATE = 1_000; // max 10%

    // ═══════════════════════════════════════════════════════════════
    //  Tax Configuration
    // ═══════════════════════════════════════════════════════════════

    uint256 public buyTaxRate;     // e.g., 500 = 5.00%
    uint256 public sellTaxRate;    // e.g., 700 = 7.00%

    // Tax distribution shares (must sum to TAX_DENOMINATOR)
    uint256 public marketingShare;
    uint256 public liquidityShare;
    uint256 public burnShare;

    address public marketingWallet;
    address public liquidityWallet;

    // Accumulated tax tokens held by this contract
    uint256 public marketingReserve;
    uint256 public liquidityReserve;

    // ═══════════════════════════════════════════════════════════════
    //  Limits (Anti-Whale)
    // ═══════════════════════════════════════════════════════════════

    uint256 public maxWallet;      // max tokens per wallet
    uint256 public maxTx;          // max tokens per transaction

    // ═══════════════════════════════════════════════════════════════
    //  DEX Integration
    // ═══════════════════════════════════════════════════════════════

    address public dexPair;

    // ═══════════════════════════════════════════════════════════════
    //  Exclusions
    // ═══════════════════════════════════════════════════════════════

    mapping(address => bool) public isExcludedFromTax;
    mapping(address => bool) public isExcludedFromLimits;

    // ═══════════════════════════════════════════════════════════════
    //  Security
    // ═══════════════════════════════════════════════════════════════

    mapping(address => bool) public isBlacklisted;
    bool public tradingPaused;

    // ═══════════════════════════════════════════════════════════════
    //  Events
    // ═══════════════════════════════════════════════════════════════
    event MarketingWalletUpdated(address indexed wallet);
    event LiquidityWalletUpdated(address indexed wallet);
    event DexPairUpdated(address indexed pair);
    event TaxRatesUpdated(uint256 buyRate, uint256 sellRate);
    event TaxSharesUpdated(uint256 marketing, uint256 liquidity, uint256 burn);
    event LimitsUpdated(uint256 maxWallet, uint256 maxTx);
    event Blacklisted(address indexed account, bool indexed status);
    event TradingPaused(bool indexed paused);
    event TokensBurned(uint256 amount);
    event MarketingCollected(uint256 amount);
    event LiquidityCollected(uint256 amount);
    event ExcludedFromTax(address indexed account, bool indexed excluded);
    event ExcludedFromLimits(address indexed account, bool indexed excluded);

    // ═══════════════════════════════════════════════════════════════
    //  Errors
    // ═══════════════════════════════════════════════════════════════

    error ZeroAddress();
    error MaxWalletExceeded();
    error MaxTxExceeded();
    error BlacklistedAddress();
    error TradingPausedError();
    error InvalidRate();
    error InvalidShares();
    error NoTaxToCollect();

    // ═══════════════════════════════════════════════════════════════
    //  Constructor
    // ═══════════════════════════════════════════════════════════════

    constructor() ERC20("GreenHat", "GREEN") Ownable(msg.sender) {
        // ── Mint entire supply to deployer ──
        _mint(msg.sender, MAX_SUPPLY);

        // ── Tax rates: 5% buy, 7% sell ──
        buyTaxRate = 500;
        sellTaxRate = 700;

        // ── Tax shares: 60% marketing, 30% liquidity, 10% burn ──
        marketingShare = 6000;
        liquidityShare = 3000;
        burnShare = 1000;

        marketingWallet = msg.sender;
        liquidityWallet = msg.sender;

        // ── Limits: 2% max wallet, 1% max tx ──
        maxWallet = (MAX_SUPPLY * 2) / 100;
        maxTx = (MAX_SUPPLY * 1) / 100;

        // ── Exclude core addresses from tax and limits ──
        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[address(0)] = true;
        isExcludedFromTax[address(0xdead)] = true;
        isExcludedFromTax[address(this)] = true;

        isExcludedFromLimits[msg.sender] = true;
        isExcludedFromLimits[address(0)] = true;
        isExcludedFromLimits[address(0xdead)] = true;
        isExcludedFromLimits[address(this)] = true;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Core Transfer Hook
    // ═══════════════════════════════════════════════════════════════

    /// @notice Hook called on every transfer, mint, and burn
    /// @dev Override to apply tax, limits, blacklist, and pause
    function _update(address from, address to, uint256 value) internal override {
        // ── Security checks ──
        if (isBlacklisted[from] || isBlacklisted[to]) revert BlacklistedAddress();
        if (tradingPaused) revert TradingPausedError();

        // ── Determine if this is a taxed transfer (buy/sell on DEX) ──
        bool isBuy = from == dexPair;
        bool isSell = to == dexPair;
        bool shouldTax = !isExcludedFromTax[from]
            && !isExcludedFromTax[to]
            && (isBuy || isSell)
            && from != address(0)  // not a mint
            && to != address(0);   // not a burn

        if (shouldTax) {
            uint256 rate = isBuy ? buyTaxRate : sellTaxRate;
            uint256 tax = (value * rate) / TAX_DENOMINATOR;
            uint256 amountAfterTax = value - tax;

            // ── Limits check ──
            if (!isExcludedFromLimits[from] && !isExcludedFromLimits[to]) {
                if (value > maxTx) revert MaxTxExceeded();
                if (to != dexPair) {
                    if (balanceOf(to) + amountAfterTax > maxWallet) revert MaxWalletExceeded();
                }
            }

            // ── Distribute tax first ──
            _distributeTax(from, tax);

            // ── Send remaining to recipient ──
            super._update(from, to, amountAfterTax);
        } else {
            // ── No tax: normal transfer, still check limits ──
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

    /// @dev Distribute tax: burn, marketing reserve, liquidity reserve
    function _distributeTax(address from, uint256 tax) internal {
        uint256 burnAmount = (tax * burnShare) / TAX_DENOMINATOR;
        uint256 marketingAmount = (tax * marketingShare) / TAX_DENOMINATOR;
        uint256 liquidityAmount = tax - burnAmount - marketingAmount;

        // Burn tokens
        if (burnAmount > 0) {
            super._update(from, address(0), burnAmount);
            emit TokensBurned(burnAmount);
        }

        // Marketing reserve
        if (marketingAmount > 0) {
            super._update(from, address(this), marketingAmount);
            marketingReserve += marketingAmount;
        }

        // Liquidity reserve
        if (liquidityAmount > 0) {
            super._update(from, address(this), liquidityAmount);
            liquidityReserve += liquidityAmount;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  Tax Collection
    // ═══════════════════════════════════════════════════════════════

    /// @notice Forward accumulated marketing tokens to the marketing wallet
    function collectMarketing() external onlyOwner {
        uint256 amount = marketingReserve;
        if (amount == 0) revert NoTaxToCollect();
        marketingReserve = 0;
        super._update(address(this), marketingWallet, amount);
        emit MarketingCollected(amount);
    }

    /// @notice Forward accumulated liquidity tokens to the liquidity wallet
    function collectLiquidity() external onlyOwner {
        uint256 amount = liquidityReserve;
        if (amount == 0) revert NoTaxToCollect();
        liquidityReserve = 0;
        super._update(address(this), liquidityWallet, amount);
        emit LiquidityCollected(amount);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: DEX
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set the DEX pair address (enables buy/sell tax detection)
    function setDexPair(address pair) external onlyOwner {
        if (pair == address(0)) revert ZeroAddress();
        dexPair = pair;
        isExcludedFromLimits[pair] = true;
        emit DexPairUpdated(pair);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Wallets
    // ═══════════════════════════════════════════════════════════════

    function setMarketingWallet(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        marketingWallet = wallet;
        emit MarketingWalletUpdated(wallet);
    }

    function setLiquidityWallet(address wallet) external onlyOwner {
        if (wallet == address(0)) revert ZeroAddress();
        liquidityWallet = wallet;
        emit LiquidityWalletUpdated(wallet);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin: Tax Rates
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set buy and sell tax rates (in basis points, max 10%)
    function setTaxRates(uint256 _buyTaxRate, uint256 _sellTaxRate) external onlyOwner {
        if (_buyTaxRate > MAX_TAX_RATE || _sellTaxRate > MAX_TAX_RATE) revert InvalidRate();
        buyTaxRate = _buyTaxRate;
        sellTaxRate = _sellTaxRate;
        emit TaxRatesUpdated(_buyTaxRate, _sellTaxRate);
    }

    /// @notice Set tax distribution shares (must sum to 10000)
    function setTaxShares(uint256 _marketing, uint256 _liquidity, uint256 _burn) external onlyOwner {
        if (_marketing + _liquidity + _burn != TAX_DENOMINATOR) revert InvalidShares();
        marketingShare = _marketing;
        liquidityShare = _liquidity;
        burnShare = _burn;
        emit TaxSharesUpdated(_marketing, _liquidity, _burn);
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

    function excludeFromTax(address account, bool excluded) external onlyOwner {
        isExcludedFromTax[account] = excluded;
        emit ExcludedFromTax(account, excluded);
    }

    function excludeFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
        emit ExcludedFromLimits(account, excluded);
    }
}
