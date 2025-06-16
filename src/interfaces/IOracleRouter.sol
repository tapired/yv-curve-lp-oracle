pragma solidity ^0.8.13;

interface IOracleRouter {
    function price(address _token) external view returns (uint256);
}