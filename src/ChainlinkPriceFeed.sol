pragma solidity ^0.8.13;

import {IYearnOracle} from "./interfaces/IYearnOracle.sol";
import {IChainlinkPriceFeed} from "./interfaces/IChainlinkPriceFeed.sol";


contract ChainlinkPriceFeed is IYearnOracle {

    function price(TokenInfo calldata _tokenInfo) external view returns (uint256) {  
        (, int256 p, , , ) = IChainlinkPriceFeed(_tokenInfo.priceFeed).latestRoundData();
        if (p <= 0) {
            revert("Invalid price");
        }

        return uint256(p) * 10 ** (18 - _tokenInfo.oraclePriceDecimals);
    }
}