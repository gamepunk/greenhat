// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title GreenHatNFT - Hat Collection
/// @notice Hold GREEN tokens to unlock exclusive NFT hats
/// @dev Balance-based tier system: more GREEN → rarer hat
/// @author GreenHat Team
contract GreenHatNFT is ERC721, ERC721URIStorage, Ownable {
    // ═══════════════════════════════════════════════════════════════
    //  Tiers
    // ═══════════════════════════════════════════════════════════════

    /// @notice NFT rarity tiers
    enum Tier {
        None,
        Bronze,   // 🥉  1,000+ GREEN
        Silver,   // 🥈  10,000+ GREEN
        Gold,     // 🥇  100,000+ GREEN
        Diamond   // 💎  1,000,000+ GREEN
    }

    /// @notice Minimum GREEN holdings required for each tier
    uint256 public constant BRONZE_THRESHOLD  = 1_000 * 10 ** 18;
    uint256 public constant SILVER_THRESHOLD  = 10_000 * 10 ** 18;
    uint256 public constant GOLD_THRESHOLD    = 100_000 * 10 ** 18;
    uint256 public constant DIAMOND_THRESHOLD = 1_000_000 * 10 ** 18;

    // ═══════════════════════════════════════════════════════════════
    //  State
    // ═══════════════════════════════════════════════════════════════

    /// @notice The GREEN token contract
    IERC20 public immutable greenHatToken;

    /// @notice Next token ID (auto-increment)
    uint256 private _nextTokenId;

    /// @notice Token ID → tier
    mapping(uint256 => Tier) public tokenTier;

    /// @notice Address → token ID (max 1 hat per wallet)
    mapping(address => uint256) public walletToken;

    /// @notice Whether an address has minted
    mapping(address => bool) public hasMinted;

    /// @notice Base metadata URI for each tier
    mapping(Tier => string) public tierURI;

    // ═══════════════════════════════════════════════════════════════
    //  Events
    // ═══════════════════════════════════════════════════════════════

    /// @notice Emitted when a hat is minted
    /// @param to Recipient
    /// @param tokenId Minted token ID
    /// @param tier NFT tier
    event HatMinted(address indexed to, uint256 indexed tokenId, Tier tier);

    /// @notice Emitted when a hat is upgraded to a higher tier
    /// @param tokenId Token ID
    /// @param oldTier Previous tier
    /// @param newTier New tier
    event HatUpgraded(uint256 indexed tokenId, Tier oldTier, Tier newTier);

    /// @notice Emitted when tier metadata URI is updated by owner
    event TierURIUpdated(Tier indexed tier, string uri);

    // ═══════════════════════════════════════════════════════════════
    //  Errors
    // ═══════════════════════════════════════════════════════════════

    error AlreadyMinted();
    error InsufficientBalance(Tier required);
    error NoHatToUpgrade();
    error NoUpgradeAvailable();
    error InvalidTier();

    // ═══════════════════════════════════════════════════════════════
    //  Constructor
    // ═══════════════════════════════════════════════════════════════

    /// @notice Create the NFT collection linked to a GREEN token
    /// @param _token The GreenHat ERC-20 token address
    constructor(address _token) ERC721("GreenHat Hat", "GHAT") Ownable(msg.sender) {
        greenHatToken = IERC20(_token);
        _nextTokenId = 1;

        // Set default tier URIs (owner can change after deploy)
        tierURI[Tier.Bronze]  = "ipfs://Qm.../bronze.json";
        tierURI[Tier.Silver]  = "ipfs://Qm.../silver.json";
        tierURI[Tier.Gold]    = "ipfs://Qm.../gold.json";
        tierURI[Tier.Diamond] = "ipfs://Qm.../diamond.json";
    }

    // ═══════════════════════════════════════════════════════════════
    //  Mint
    // ═══════════════════════════════════════════════════════════════

    /// @notice Mint your GREEN-hat based on current token holdings
    /// @dev Requires GREEN balance ≥ 1,000
    function mint() external {
        if (hasMinted[msg.sender]) revert AlreadyMinted();

        Tier tier = _currentTier(msg.sender);
        if (tier == Tier.None) revert InsufficientBalance(tier);

        uint256 tokenId = _nextTokenId++;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tierURI[tier]);

        tokenTier[tokenId] = tier;
        walletToken[msg.sender] = tokenId;
        hasMinted[msg.sender] = true;

        emit HatMinted(msg.sender, tokenId, tier);
    }

    /// @notice Upgrade your hat if your GREEN holdings increased
    function upgrade() external {
        if (!hasMinted[msg.sender]) revert NoHatToUpgrade();

        uint256 tokenId = walletToken[msg.sender];
        Tier oldTier = tokenTier[tokenId];
        Tier newTier = _currentTier(msg.sender);

        if (newTier == oldTier || newTier == Tier.None) revert NoUpgradeAvailable();
        if (newTier <= oldTier) revert NoUpgradeAvailable();

        tokenTier[tokenId] = newTier;
        _setTokenURI(tokenId, tierURI[newTier]);

        emit HatUpgraded(tokenId, oldTier, newTier);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Admin
    // ═══════════════════════════════════════════════════════════════

    /// @notice Set metadata URI for a tier (e.g., after uploading to IPFS)
    /// @param tier The tier to update
    /// @param uri New metadata URI
    function setTierURI(Tier tier, string calldata uri) external onlyOwner {
        if (tier == Tier.None) revert InvalidTier();
        tierURI[tier] = uri;
        emit TierURIUpdated(tier, uri);
    }

    // ═══════════════════════════════════════════════════════════════
    //  Views
    // ═══════════════════════════════════════════════════════════════

    /// @notice Check which tier an address qualifies for
    /// @param account The wallet address
    /// @return tier The tier they qualify for (None if below minimum)
    function currentTier(address account) external view returns (Tier) {
        return _currentTier(account);
    }

    function _currentTier(address account) internal view returns (Tier) {
        uint256 balance = greenHatToken.balanceOf(account);
        if (balance >= DIAMOND_THRESHOLD) return Tier.Diamond;
        if (balance >= GOLD_THRESHOLD) return Tier.Gold;
        if (balance >= SILVER_THRESHOLD) return Tier.Silver;
        if (balance >= BRONZE_THRESHOLD) return Tier.Bronze;
        return Tier.None;
    }

    // ═══════════════════════════════════════════════════════════════
    //  Required overrides
    // ═══════════════════════════════════════════════════════════════

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
