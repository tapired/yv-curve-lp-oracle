pragma solidity ^0.8.13;

interface IYearnVault {
    function pricePerShare() external view returns (uint256);
    function token() external view returns (address);
}