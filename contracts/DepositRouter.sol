// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DepositRouter is ReentrancyGuard {
    ISwapRouter public immutable swapRouter;
    address public positionManager;
    address public tokenA;
    address public tokenB;

    // Define the Uniswap pool fee
    uint24 public constant poolFee = 3000; // For example, 0.3% pool fee

    constructor(address _swapRouter, address _tokenA, address _tokenB, address _positionManager) {
        swapRouter = ISwapRouter(_swapRouter);
        tokenA = _tokenA;
        tokenB = _tokenB;
        positionManager = _positionManager;
    }

    // Event for deposit logging
    event Deposit(address indexed user, uint256 tokenAAmount, uint256 tokenBAmount);

    // Deposit function
    function deposit(uint256 amountA) external nonReentrant {
        require(amountA > 0, "Deposit amount must be greater than zero");

        // Transfer Token A from user to this contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);

        // Swap half of Token A to Token B
        uint256 amountAForSwap = amountA / 2;
        uint256 amountB = swapTokenAForTokenB(amountAForSwap);

        // Send tokens to the Position Manager
        IERC20(tokenA).transfer(positionManager, amountA - amountAForSwap);
        IERC20(tokenB).transfer(positionManager, amountB);

        emit Deposit(msg.sender, amountA - amountAForSwap, amountB);
    }

    // Token swap helper function
    function swapTokenAForTokenB(uint256 amountA) private returns (uint256 amountB) {
        // Approve the swapRouter to spend Token A
        IERC20(tokenA).approve(address(swapRouter), amountA);

        // Set up parameters for the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenA,
            tokenOut: tokenB,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountA,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Execute the swap
        amountB = swapRouter.exactInputSingle(params);
        return amountB;
    }
}
