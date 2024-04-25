// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PositionManager is ERC721URIStorage, Ownable {
    using SafeMath for uint256;

    struct Position {
        uint256 liquidity;
        uint256 lastYieldDistribution;
        uint256 accumulatedYield;
    }

    IUniswapV3Pool public uniswapPool;
    uint256 public nextTokenId;
    mapping(uint256 => Position) public positions;

    function getPosition(uint256 tokenId) external view returns (uint256 liquidity, uint256 lastYieldDistribution, uint256 accumulatedYield) {
        Position storage position = positions[tokenId];
        return (position.liquidity, position.lastYieldDistribution, position.accumulatedYield);
    }

    // Constants for yield calculations
    uint256 public constant yieldRate = 7; // Represents the 7% APR
    uint256 public constant yearInSeconds = 31536000; // Number of seconds in a year for APR calculation

    constructor(address _uniswapPool, address initialOwner) ERC721("Liquidity Position NFT", "LPN") Ownable(initialOwner) {
        uniswapPool = IUniswapV3Pool(_uniswapPool);
    }

    // Function to add liquidity and create a new position
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, createTokenURI(tokenId));

        positions[tokenId] = Position({
            liquidity: amountA + amountB,
            lastYieldDistribution: block.timestamp,
            accumulatedYield: 0
        });

        return tokenId;
    }

    // Function to update liquidity in an existing position
    function adjustLiquidity(uint256 tokenId, uint256 newAmountA, uint256 newAmountB) external onlyOwner {
        require(ownerOf(tokenId) != address(0),"Token does not exist");
        distributeYield(tokenId); // Distribute yield before adjusting liquidity to ensure correct calculations
        positions[tokenId].liquidity = newAmountA + newAmountB;
    }

    // Function to remove liquidity
    function removeLiquidity(uint256 tokenId) external onlyOwner {
        require(ownerOf(tokenId) != address(0),"Token does not exist");
        distributeYield(tokenId); // Distribute final yield before burning the token
        _burn(tokenId);
        delete positions[tokenId];
    }

    // Function to distribute yield to a specific position
    function distributeYield(uint256 tokenId) public onlyOwner {
        Position storage position = positions[tokenId];
        uint256 timeElapsed = block.timestamp.sub(position.lastYieldDistribution);
        if (timeElapsed > 0) {
            uint256 yield = position.liquidity.mul(yieldRate).mul(timeElapsed).div(yearInSeconds).div(100);
            position.accumulatedYield = position.accumulatedYield.add(yield);
            position.lastYieldDistribution = block.timestamp;
        }
    }

    // Helper function to generate a token URI
    function createTokenURI(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked("https://api.cherrybyte.com/metadata/", Strings.toString(tokenId)));
    }
}
