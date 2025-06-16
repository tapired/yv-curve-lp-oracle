pragma solidity ^0.8.13;

interface ICurveStableSwap {
    function coins(uint256 i) external view returns (address);
    function get_virtual_price() external view returns (uint256);
    function claim_admin_fees() external;
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
}