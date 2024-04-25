// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./PositionManager.sol";

contract WithdrawalRouter is ReentrancyGuard {
    PositionManager public positionManager;
    IUniswapV3Pool public uniswapPool;
    address public tokenA;

    constructor(address _positionManager, address _uniswapPool, address _tokenA) {
        positionManager = PositionManager(_positionManager);
        uniswapPool = IUniswapV3Pool(_uniswapPool);
        tokenA = _tokenA;
    }

    // Event for withdrawal logging
    event Withdrawal(address indexed user, uint256 tokenId, uint256 amountA);

    // Withdraw function
    function withdraw(uint256 tokenId) external nonReentrant {
        require(positionManager.ownerOf(tokenId) == msg.sender, "You do not own this token");

        // Calculate current value based on NFT and Uniswap positions
        uint256 amountA = calculateWithdrawAmount(tokenId);

        // Transfer Token A to the user
        require(IERC20(tokenA).transfer(msg.sender, amountA), "Transfer failed");

        // Remove liquidity and burn the NFT
        positionManager.removeLiquidity(tokenId);

        emit Withdrawal(msg.sender, tokenId, amountA);
    }

    // Helper function to calculate the withdrawal amount
     function calculateWithdrawAmount(uint256 tokenId) internal view returns (uint256) {
        (uint256 liquidityAmount,,) = positionManager.getPosition(tokenId); // Only fetch the liquidity
        // Logic to calculate based on pool state and impermanent loss
        return liquidityAmount;
    }
}
