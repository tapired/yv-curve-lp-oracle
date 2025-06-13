// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {YearnCurveLPOracleStableSwap} from "../src/YearnCurveLPOracleStableSwap.sol";
import {OracleRouter} from "../src/OracleRouter.sol";
import {ChainlinkPriceFeed} from "../src/ChainlinkPriceFeed.sol";
import {IYearnOracle} from "../src/interfaces/IYearnOracle.sol";

import {MainnetAddresses} from "./utils/Addresses.sol";

contract YearnCurveLPOracleStableSwapTest is Test {
    YearnCurveLPOracleStableSwap public curveLPOracleStableSwap;
    OracleRouter public oracleRouter;
    ChainlinkPriceFeed public chainlinkPriceFeed;

    address public management;

    function setUp() public {
        IYearnOracle.TokenInfo[] memory tokenInfos = new IYearnOracle.TokenInfo[](3);
        tokenInfos[0] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            decimals: 18, // token decimals
            oraclePriceDecimals: 8,
            priceFeed: MainnetAddresses.ETH_USD_CHAINLINK
        });
        tokenInfos[1] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            decimals: 6, // token decimals
            oraclePriceDecimals: 8,
            priceFeed: MainnetAddresses.USDC_USD_CHAINLINK
        });
        tokenInfos[2] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            decimals: 8, // token decimals
            oraclePriceDecimals: 8,
            priceFeed: MainnetAddresses.BTC_USD_CHAINLINK
        });

        address[] memory tokens = new address[](3);
        tokens[0] = MainnetAddresses.WETH;
        tokens[1] = MainnetAddresses.USDC;
        tokens[2] = MainnetAddresses.WBTC;
        
        vm.prank(management);
        oracleRouter = new OracleRouter(
            tokenInfos,
            tokens
        );

        vm.prank(management);
        curveLPOracleStableSwap = new YearnCurveLPOracleStableSwap(
            address(oracleRouter)
        );

        vm.prank(management);
        chainlinkPriceFeed = new ChainlinkPriceFeed();

        vm.prank(management);
        oracleRouter.addOracleType(1, address(chainlinkPriceFeed));
    }
    
    function test_OracleRouter_Price() public {
        uint256 price = oracleRouter.price(MainnetAddresses.WETH);
        uint256 price2 = oracleRouter.price(MainnetAddresses.USDC);
        uint256 price3 = oracleRouter.price(MainnetAddresses.WBTC);
        console.log("price", price);
        console.log("price2", price2);
        console.log("price3", price3);
    }


}
