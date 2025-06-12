// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IOracle} from "./interfaces/IOracle.sol";
import {IYearnVault} from "./interfaces/IYearnVault.sol";
import {ICurveStableSwap} from "./interfaces/ICurveStableSwap.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOracleRouter} from "./interfaces/IOracleRouter.sol";

contract YearnCurveLPOracleStableSwap is IOracle {
    address public baseToken;
    uint96 public baseTokenPoolIndex; // if the base token is in the pool this will be the index of the base token in coins[] array
    address public yVault;
    address public curvePool;
    address[] public coins;
    
    address immutable public ORACLE_ROUTER;
    
    constructor(address _oracleRouter) {
        ORACLE_ROUTER = _oracleRouter;
    }

    function initialize(address _yVault, address _curvePool, uint256 numCoins, bool isTokenPool, address _baseToken) {
        require(yVault == address(0), "already initialized");

        baseToken = _baseToken;
        baseTokenPoolIndex = type(uint96).max;

        yVault = _yVault;
        curvePool = _curvePool;

        if (isTokenPool) {
            require(curvePool == IYearnVault(_yVault).token(), "!want");
        }

        for (uint256 i = 0; i < numCoins;) {
            address coin = ICurveStableSwap(_curvePool).coins(i);
            if (coin == _baseToken) {
                baseTokenPoolIndex = i;
            }
            coins.push(coin);
            unchecked {
                i++;
            }
        }
    }

    function price() external view returns (uint256) {
        uint len = coins.length;
        uint minPrice = 0;
        uint256[] memory prices = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            prices[i] = IOracleRouter(ORACLE_ROUTER).price(coins[i]);
            if (prices[i] < minPrice || i == 0) {
                minPrice = prices[i];
            }
        }

        // this is always in 18 decimals
        uint256 lpPrice = ICurveStableSwap(curvePool).get_virtual_price();
        lpPrice = lpPrice * minPrice / 1e18;
        
        // all curve lP tokens are in 18 decimals.
        uint256 pps = IYearnVault(yVault).pricePerShare();
        lpPrice = lpPrice * pps / 1e18;
        
        // now we need to convert to baseToken
        uint256 baseTokenPrice;
        if (baseTokenPoolIndex != type(uint96).max) {
            baseTokenPrice = prices[baseTokenPoolIndex];
        } else {
            baseTokenPrice = IOracleRouter(ORACLE_ROUTER).price(baseToken);
        }

        lpPrice = lpPrice * 1e18 / baseTokenPrice;

        return lpPrice;
    }
}
