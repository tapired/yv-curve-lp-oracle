pragma solidity ^0.8.13;

interface IYearnOracle {
    struct TokenInfo {
        OracleType oracleType;
        uint44 decimals; // token decimals
        uint44 oraclePriceDecimals;
        address priceFeed;
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