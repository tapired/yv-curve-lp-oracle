pragma solidity ^0.8.13;
import {IYearnOracle} from "./interfaces/IYearnOracle.sol";

interface IEthPlusOracle {
    function price() external view returns (uint256, uint256);
}

contract ETHPlusFeed {

    IEthPlusOracle public constant ETH_PLUS_ORACLE =
        IEthPlusOracle(0x3f11C47E7ed54b24D7EFC222FD406d8E1F49Fb69);

    // returns in terms of USD in 18 decimals.
    function price(IYearnOracle.TokenInfo calldata _tokenInfo) external view returns (uint256) {  
        (uint256 low, uint256 high) = ETH_PLUS_ORACLE.price();
        uint256 price = (low + high) / 2;
        return price;
    }
}