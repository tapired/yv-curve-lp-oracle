// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {YearnCurveLPOracleStableSwap} from "../src/YearnCurveLPOracleStableSwap.sol";
import {OracleRouter} from "../src/OracleRouter.sol";
import {ChainlinkPriceFeed} from "../src/ChainlinkPriceFeed.sol";
import {IYearnOracle} from "../src/interfaces/IYearnOracle.sol";
import {ETHPlusFeed} from "../src/ETHPlusFeed.sol";
import {MainnetAddresses} from "./utils/Addresses.sol";

import {IMorpho, MarketParams, Id, Position, Market} from "../src/interfaces/IMorphoBlue.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICurveStableSwap} from "../src/interfaces/ICurveStableSwap.sol";

interface IUSDT {
    function approve(address spender, uint256 amount) external;
}

interface IYearnCurveLPOracleStableSwap {
    function price() external view returns (uint256);
    function baseToken() external view returns (address);
    function baseTokenDecimals() external view returns (uint8);
    function baseTokenPoolIndex() external view returns (uint88); // if the base token is in the pool this will be the index of the base token in coins[] array
    function yVault() external view returns (address);
    function curvePool() external view returns (address);
    function coins(uint256 v) external view returns (address);
    function ORACLE_ROUTER() external view returns (address);
}

contract YearnCurveLPOracleStableSwapTest is Test {
    YearnCurveLPOracleStableSwap public curveLPOracleStableSwap;
    OracleRouter public oracleRouter;
    ChainlinkPriceFeed public chainlinkPriceFeed;

    uint256 private constant MARKET_PARAMS_BYTES_LENGTH = 32 * 5;
    
    address public management = address(69);

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

    function test_CreateAndBorrowMorphoMarket_ETHPlus_ETH() public { 
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

        MarketParams memory marketParams = MarketParams({
            loanToken: MainnetAddresses.WETH,
            collateralToken: MainnetAddresses.YV_ETHPLUS_ETH,
            oracle: address(newStableSwapOracle),
            irm: MainnetAddresses.MORPHO_IRM,
            lltv: 0.915e18
        });

        IMorpho MORPHO = IMorpho(MainnetAddresses.MORPHO);

        MORPHO.createMarket(marketParams);

        MarketParams memory marketParams2 = MORPHO.idToMarketParams(_toId(marketParams));
        assertEq(marketParams2.lltv, marketParams.lltv);
        assertEq(marketParams2.oracle, marketParams.oracle);
        assertEq(marketParams2.loanToken, marketParams.loanToken);
        assertEq(marketParams2.collateralToken, marketParams.collateralToken);
        assertEq(marketParams2.irm, marketParams.irm);

        deal(MainnetAddresses.YV_ETHPLUS_ETH, management, 500e18);
        deal(MainnetAddresses.WETH, management, 600e18);
        assertEq(IERC20(MainnetAddresses.YV_ETHPLUS_ETH).balanceOf(management), 500e18);
        assertEq(IERC20(MainnetAddresses.WETH).balanceOf(management), 600e18);

        IERC20(MainnetAddresses.WETH).approve(MainnetAddresses.MORPHO, type(uint256).max);
        IERC20(MainnetAddresses.YV_ETHPLUS_ETH).approve(MainnetAddresses.MORPHO, type(uint256).max);

        MORPHO.supply(marketParams, 500e18, 0, management, "");
        
        MORPHO.supplyCollateral(marketParams, 500e18, management, "");

        MORPHO.borrow(marketParams, 400e18, 0, management, management);

        Position memory positionState = MORPHO.position(_toId(marketParams), management);
        console.log("Borrow shares", positionState.borrowShares);
        console.log("Supply shares", positionState.supplyShares);
        console.log("Collateral", positionState.collateral);
    }

    function test_CreateAndBorrowMorphoMarket_crvUSD_USDT() public { 
        _createSupplyAndBorrowCRVUSD_USDT();
    }

    function test_DepeggedPool_crvUSD_USDT() public {
        _createSupplyAndBorrowCRVUSD_USDT();

        address manipulator = address(3);
        vm.startPrank(manipulator);
        deal(MainnetAddresses.USDT, manipulator, 10_000_000e6);
        deal(MainnetAddresses.CRV_USD, manipulator, 10_000_000e18);
        IUSDT(MainnetAddresses.USDT).approve(MainnetAddresses.CRVUSD_USDT, type(uint256).max);
        IERC20(MainnetAddresses.CRV_USD).approve(MainnetAddresses.CRVUSD_USDT, type(uint256).max);

        uint256 price = curveLPOracleStableSwap.price();
        console.log("Curve LP Oracle Stable Swap price crvUSD_USDT", price);

        ICurveStableSwap(MainnetAddresses.CRVUSD_USDT).exchange(0, 1, 1_000_000e6, 0);

        price = curveLPOracleStableSwap.price();
        console.log("Curve LP Oracle Stable Swap price after manipulationcrvUSD_USDT", price);
    }

    function test_CloneNewOracle() public {
        address newOracle = curveLPOracleStableSwap.cloneNewOracle(
            MainnetAddresses.YV_CRVUSD_USDT,
            MainnetAddresses.CRVUSD_USDT,
            2,
            true,
            MainnetAddresses.USDT
        );

        console.log("New oracle", newOracle);

        assertEq(IYearnCurveLPOracleStableSwap(newOracle).baseToken(), MainnetAddresses.USDT);
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).baseTokenDecimals(), 6);
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).baseTokenPoolIndex(), 0);
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).yVault(), MainnetAddresses.YV_CRVUSD_USDT);
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).curvePool(), MainnetAddresses.CRVUSD_USDT);
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).coins(0), MainnetAddresses.USDT);
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).coins(1), MainnetAddresses.CRV_USD);

        // immutable is set
        assertEq(IYearnCurveLPOracleStableSwap(newOracle).ORACLE_ROUTER(), address(oracleRouter));
    }

    function _toId(MarketParams memory marketParams) internal view returns (Id marketParamsId) {
        assembly ("memory-safe") {
            marketParamsId := keccak256(marketParams, MARKET_PARAMS_BYTES_LENGTH)
        }   
    }

    function _createSupplyAndBorrowCRVUSD_USDT() internal {
        vm.startPrank(management);

        MarketParams memory marketParams = MarketParams({
            loanToken: MainnetAddresses.USDC,
            collateralToken: MainnetAddresses.YV_CRVUSD_USDT,
            oracle: address(curveLPOracleStableSwap),
            irm: MainnetAddresses.MORPHO_IRM,
            lltv: 0.915e18
        });

        IMorpho MORPHO = IMorpho(MainnetAddresses.MORPHO);

        MORPHO.createMarket(marketParams);

        MarketParams memory marketParams2 = MORPHO.idToMarketParams(_toId(marketParams));
        assertEq(marketParams2.lltv, marketParams.lltv);
        assertEq(marketParams2.oracle, marketParams.oracle);
        assertEq(marketParams2.loanToken, marketParams.loanToken);
        assertEq(marketParams2.collateralToken, marketParams.collateralToken);
        assertEq(marketParams2.irm, marketParams.irm);

        deal(MainnetAddresses.YV_CRVUSD_USDT, management, 500e18);
        deal(MainnetAddresses.USDC, management, 600e6);
        assertEq(IERC20(MainnetAddresses.YV_CRVUSD_USDT).balanceOf(management), 500e18);
        assertEq(IERC20(MainnetAddresses.USDC).balanceOf(management), 600e6);

        IERC20(MainnetAddresses.USDC).approve(MainnetAddresses.MORPHO, type(uint256).max);
        IERC20(MainnetAddresses.YV_CRVUSD_USDT).approve(MainnetAddresses.MORPHO, type(uint256).max);

        MORPHO.supply(marketParams, 500e6, 0, management, "");
        
        MORPHO.supplyCollateral(marketParams, 500e18, management, "");

        MORPHO.borrow(marketParams, 400e6, 0, management, management);

        Position memory positionState = MORPHO.position(_toId(marketParams), management);
        console.log("Borrow shares", positionState.borrowShares);
        console.log("Supply shares", positionState.supplyShares);
        console.log("Collateral", positionState.collateral);
    }

}
