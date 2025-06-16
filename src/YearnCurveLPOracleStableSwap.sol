// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IOracle} from "./interfaces/IOracle.sol";
import {IYearnVault} from "./interfaces/IYearnVault.sol";
import {ICurveStableSwap} from "./interfaces/ICurveStableSwap.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IOracleRouter} from "./interfaces/IOracleRouter.sol";

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract YearnCurveLPOracleStableSwap is IOracle {
    address public baseToken;
    uint8 public baseTokenDecimals;
    uint88 public baseTokenPoolIndex; // if the base token is in the pool this will be the index of the base token in coins[] array
    address public yVault;
    address public curvePool;
    address[] public coins;
    
    address immutable public ORACLE_ROUTER;
    
    constructor(address _oracleRouter) {
        ORACLE_ROUTER = _oracleRouter;
    }

    function initialize(address _yVault, address _curvePool, uint256 numCoins, bool isTokenPool, address _baseToken) public {
        require(yVault == address(0), "already initialized");

        baseToken = _baseToken;
        baseTokenDecimals = IERC20Metadata(_baseToken).decimals();
        baseTokenPoolIndex = type(uint88).max;

        yVault = _yVault;
        curvePool = _curvePool;

        if (isTokenPool) {
            require(curvePool == IYearnVault(_yVault).token(), "!want");
        }

        for (uint256 i = 0; i < numCoins;) {
            address coin = ICurveStableSwap(_curvePool).coins(i);
            if (coin == _baseToken) {
                baseTokenPoolIndex = uint88(i);
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

        // something is very wrong
        require(minPrice > 0, "minPrice is 0");

        // this is a MUST since ETH+/ETH pool is using native ETH and
        // the get_virtual_price is not protected by the reentrancy guard.
        // NOTE: This will not work because the function "price()" needs to be a view function..
        // ICurveStableSwap(curvePool).claim_admin_fees();
        // this is always in 18 decimals
        uint256 lpPrice = ICurveStableSwap(curvePool).get_virtual_price();
        lpPrice = lpPrice * minPrice / 1e18;
        
        // all curve lP tokens are in 18 decimals.
        uint256 pps = IYearnVault(yVault).pricePerShare();
        lpPrice = lpPrice * pps / 1e18;

        // now we need to convert to baseToken
        uint256 baseTokenPrice;
        if (baseTokenPoolIndex != type(uint88).max) {
            baseTokenPrice = prices[baseTokenPoolIndex];
        } else {
            baseTokenPrice = IOracleRouter(ORACLE_ROUTER).price(baseToken);
        }
        
        // baseToken is the loan token. 
        // lpPrice is in baseToken units but in 18 decimals.
        lpPrice = lpPrice * 1e18 / baseTokenPrice;

        // by the definition in morpho:
        // final return precision must need to be = 36 + loan token decimals - collateral token decimals
        // loan token decimals is base token decimals.
        // collateral token decimals is the yVault decimals, which is 18 always.
        // so we need to return 36 + baseToken decimals - 18 
        // 18 + baseToken decimals.

        //  36 + loan token decimals - collateral token decimals === 18 + 18 + loan to

        return (lpPrice * 10**baseTokenDecimals);
    }

    function cloneNewOracle(address _yVault, address _curvePool, uint256 _numCoins, bool _isTokenPool, address _baseToken) external returns (address) {
        address newOracle = Clones.clone(address(this));
        YearnCurveLPOracleStableSwap(newOracle).initialize(_yVault, _curvePool, _numCoins, _isTokenPool, _baseToken);
        return newOracle;
    }
}
