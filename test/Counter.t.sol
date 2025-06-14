// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {YearnCurveLPOracleStableSwap} from "../src/YearnCurveLPOracleStableSwap.sol";
import {OracleRouter} from "../src/OracleRouter.sol";
import {ChainlinkPriceFeed} from "../src/ChainlinkPriceFeed.sol";
import {IYearnOracle} from "../src/interfaces/IYearnOracle.sol";
import {ETHPlusFeed} from "../src/ETHPlusFeed.sol";
import {MainnetAddresses} from "./utils/Addresses.sol";

contract YearnCurveLPOracleStableSwapTest is Test {
    YearnCurveLPOracleStableSwap public curveLPOracleStableSwap;
    OracleRouter public oracleRouter;
    ChainlinkPriceFeed public chainlinkPriceFeed;
    
    address public management;

    function setUp() public {
        IYearnOracle.TokenInfo[] memory tokenInfos = new IYearnOracle.TokenInfo[](5);
        bytes memory data = abi.encode(MainnetAddresses.ETH_USD_CHAINLINK, 8);
        tokenInfos[0] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            data: data
        });

        data = abi.encode(MainnetAddresses.USDC_USD_CHAINLINK, 8);
        tokenInfos[1] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            data: data
        });

        data = abi.encode(MainnetAddresses.BTC_USD_CHAINLINK, 8);
        tokenInfos[2] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            data: data
        });

        data = abi.encode(MainnetAddresses.USDT_USD_CHAINLINK, 8);
        tokenInfos[3] = IYearnOracle.TokenInfo({
            oracleType: 1, // chainlink
            data: data
        });

        data = abi.encode(MainnetAddresses.CRV_USD_CHAINLINK, 8);
        tokenInfos[4] = IYearnOracle.TokenInfo({    
            oracleType: 1, // chainlink
            data: data
        });

        address[] memory tokens = new address[](5);
        tokens[0] = MainnetAddresses.WETH;
        tokens[1] = MainnetAddresses.USDC;
        tokens[2] = MainnetAddresses.WBTC;
        tokens[3] = MainnetAddresses.USDT;
        tokens[4] = MainnetAddresses.CRV_USD;
        
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

        vm.prank(management);
        curveLPOracleStableSwap.initialize(
            MainnetAddresses.YV_CRVUSD_USDT,
            MainnetAddresses.CRVUSD_USDT,
            2,
            true,
            MainnetAddresses.USDC
        );
    }
    
    function test_OracleRouter_Price() public {
        uint256 price = oracleRouter.price(MainnetAddresses.WETH);
        uint256 price2 = oracleRouter.price(MainnetAddresses.USDC);
        uint256 price3 = oracleRouter.price(MainnetAddresses.WBTC);
        console.log("Oracle router direct price WETH", price);
        console.log("Oracle router direct price USDC", price2);
        console.log("Oracle router direct price WBTC", price3);
    }

    function test_CurveLPOracleStableSwap_Price_crvUSD_USDT() public {
        uint256 price = curveLPOracleStableSwap.price();
        console.log("Curve LP Oracle Stable Swap price crvUSD_USDT", price);

        // this math below is the morpho math so the borrowAmount must need to be in borrow token decimals!
        uint256 loanTokenAmount = 100e6;
        uint256 collateralTokenAmount = 100e18;
        uint256 borrowAmount = collateralTokenAmount * price / 1e36;
        console.log("Borrow amount in USDC for crvUSD_USDT", borrowAmount);
    }

    function test_CurveLPOracleStableSwap_Price_ETHPlus_ETH() public {
        IYearnOracle.TokenInfo[] memory tokenInfos = new IYearnOracle.TokenInfo[](2);

        vm.startPrank(management);
        ETHPlusFeed ethPlusFeed = new ETHPlusFeed();
        oracleRouter.addOracleType(5, address(ethPlusFeed));
        oracleRouter.addToken(MainnetAddresses.ETH_PLUS, IYearnOracle.TokenInfo({
            oracleType: 5, // ethplus
            data: ""
        }));

        YearnCurveLPOracleStableSwap newStableSwapOracle = new YearnCurveLPOracleStableSwap(
            address(oracleRouter)
        );
        newStableSwapOracle.initialize(MainnetAddresses.YV_ETHPLUS_ETH, MainnetAddresses.ETHPLUS_ETH, 2, false, MainnetAddresses.WETH);

        vm.stopPrank();

        uint256 price = newStableSwapOracle.price();
        console.log("Curve LP Oracle Stable Swap price ETH+_ETH", price);

        // this math below is the morpho math so the borrowAmount must need to be in borrow token decimals!
        uint256 loanTokenAmount = 100e18;
        uint256 collateralTokenAmount = 100e18;
        uint256 borrowAmount = collateralTokenAmount * price / 1e36;
        console.log("Borrow amount in ETH for ETH+_ETH", borrowAmount);
    }


}
