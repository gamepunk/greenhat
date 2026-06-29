// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title GreenHatPool — Simple GREEN/POL Liquidity Pool
/// @notice Minimal constant product AMM for testnet use
/// @dev Holds GREEN (ERC20) + native POL. No WPOL needed.
contract GreenHatPool is Ownable {
    IERC20 public immutable green;

    uint256 public greenReserve;
    uint256 public polReserve;

    event Swapped(address indexed user, bool boughtGreen, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(uint256 greenAmount, uint256 polAmount);
    event LiquidityRemoved(uint256 greenAmount, uint256 polAmount);

    error InsufficientOutput();
    error InvalidRatio();
    error ZeroAmount();

    constructor(
        address _green
    ) Ownable(msg.sender) {
        green = IERC20(_green);
    }

    /// @notice Add initial liquidity (owner only)
    function addLiquidity(
        uint256 greenAmount
    ) external payable onlyOwner {
        if (greenAmount == 0 || msg.value == 0) revert ZeroAmount();
        if (greenReserve > 0 || polReserve > 0) {
            if (greenAmount * polReserve != msg.value * greenReserve) revert InvalidRatio();
        }

        bool ok = green.transferFrom(msg.sender, address(this), greenAmount);
        require(ok, "GREEN transfer failed");

        greenReserve += greenAmount;
        polReserve += msg.value;
        emit LiquidityAdded(greenAmount, msg.value);
    }

    /// @notice Buy GREEN with POL (send POL as msg.value)
    /// @param minGreenOut Minimum GREEN to receive
    function buyGreen(
        uint256 minGreenOut
    ) external payable {
        if (msg.value == 0) revert ZeroAmount();
        uint256 greenOut = (msg.value * greenReserve) / (polReserve + msg.value);
        if (greenOut < minGreenOut) revert InsufficientOutput();

        bool ok = green.transfer(msg.sender, greenOut);
        require(ok, "GREEN transfer failed");

        polReserve += msg.value;
        greenReserve -= greenOut;
        emit Swapped(msg.sender, true, msg.value, greenOut);
    }

    /// @notice Sell GREEN for POL
    /// @param greenIn Amount of GREEN to sell
    /// @param minPolOut Minimum POL to receive
    function sellGreen(
        uint256 greenIn,
        uint256 minPolOut
    ) external {
        if (greenIn == 0) revert ZeroAmount();
        uint256 polOut = (greenIn * polReserve) / (greenReserve + greenIn);
        if (polOut < minPolOut) revert InsufficientOutput();

        bool ok = green.transferFrom(msg.sender, address(this), greenIn);
        require(ok, "GREEN transfer failed");

        // CEI: Update reserves BEFORE external POL transfer to prevent reentrancy
        greenReserve += greenIn;
        polReserve -= polOut;

        (bool ok2,) = msg.sender.call{ value: polOut }("");
        require(ok2, "POL transfer failed");

        emit Swapped(msg.sender, false, greenIn, polOut);
    }

    /// @notice Owner removes all liquidity
    function removeLiquidity() external onlyOwner {
        uint256 g = greenReserve;
        uint256 p = polReserve;
        greenReserve = 0;
        polReserve = 0;

        bool ok = green.transfer(msg.sender, g);
        require(ok, "GREEN transfer failed");
        (bool ok2,) = msg.sender.call{ value: p }("");
        require(ok2, "POL transfer failed");
        emit LiquidityRemoved(g, p);
    }

    /// @notice 1 GREEN = ? POL (in wei)
    function price() external view returns (uint256) {
        if (greenReserve == 0) return 0;
        return (polReserve * 1e18) / greenReserve;
    }

    receive() external payable { }
}
