pragma solidity ^0.8.13;

import {IOracle} from "./interfaces/IOracle.sol";
import {IYearnOracle} from "./interfaces/IYearnOracle.sol";

contract OracleRouter {

    mapping(address => IYearnOracle.TokenInfo) public tokenInfos;
    mapping(uint8 => address) public oracles;

    address public management;

    constructor(IYearnOracle.TokenInfo[] memory _initialTokenInfos, address[] memory _initialTokens) {
        require(_initialTokenInfos.length == _initialTokens.length, "!length");
        for (uint256 i = 0; i < _initialTokenInfos.length;) {
            tokenInfos[_initialTokens[i]] = _initialTokenInfos[i];
            unchecked {
                i++;
            }
        }

        management = msg.sender;
    }

    function price(address _token) external view returns (uint256) {
        IYearnOracle.TokenInfo memory tokenInfo = tokenInfos[_token];
        uint8 _oracleType = tokenInfo.oracleType;
        if (_oracleType == 0) {
            revert("Price feed is not registered");
        }

        address _oracle = oracles[_oracleType];
        if (_oracle == address(0)) {
            revert("Oracle is not registered");
        }

        return IYearnOracle(_oracle).price(tokenInfo);
    }

    function addOracleType(uint8 _oracleType, address _oracle) external {
        require(msg.sender == management, "!management");
        oracles[_oracleType] = _oracle;
    }

    // function addToken(IYearnOracle.TokenInfo calldata _tokenInfo) external {
    //     tokens.push(_tokenInfo);
    // }
}