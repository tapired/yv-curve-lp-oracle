pragma solidity ^0.8.13;

interface IYearnOracle {
    struct TokenInfo {
        uint8 oracleType; // 0 = NONE, 1 = CHAINLINK, 2 = API3, 3 = UNISWAP_V3, 4 = REDSTONE
        bytes data;
    }

    enum OracleType {
        NONE,
        CHAINLINK,
        API3,
        UNISWAP_V3,
        REDSTONE
    }

    // ALWAYS RETURN IN 18 DECIMALS!
    function price(TokenInfo calldata _tokenInfo) external view returns (uint256);
}