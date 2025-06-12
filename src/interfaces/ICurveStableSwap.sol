pragma solidity ^0.8.13;

interface ICurveStableSwap {
    function coins(uint256 i) external view returns (address);
    function get_virtual_price() external view returns (uint256);
}