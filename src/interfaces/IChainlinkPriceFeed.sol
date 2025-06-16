pragma solidity ^0.8.13;

interface IChainlinkPriceFeed {
    function latestAnswer() external view returns (uint256);
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}