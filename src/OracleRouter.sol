pragma solidity ^0.8.13;

import {IOracle} from "./interfaces/IOracle.sol";
import {TokenInfo, OracleType, IYearnOracle} from "./interfaces/IYearnOracle.sol";

contract OracleRouter {

    mapping(address => TokenInfo) public tokenInfos;
    mapping(OracleType => address) public oracles;

    constructor(TokenInfo[] calldata _initialTokenInfos, address[] calldata _initialTokens) {
        require(_initialTokenInfos.length == _initialTokens.length, "!length");
        for (uint256 i = 0; i < _initialTokenInfos.length;) {
            tokenInfos[_initialTokens[i]] = _initialTokenInfos[i];
            unchecked {
                i++;
            }
        }
    }

    function price(address _token) external view returns (uint256) {
        TokenInfo memory tokenInfo = tokenInfos[_token];
        OracleType _oracleType = tokenInfo.oracleType;
        if (_oracleType == OracleType.NONE) {
            revert("Price feed is not registered");
        }

        address _oracle = oracles[_oracleType];
        if (_oracle == address(0)) {
            revert("Oracle is not registered");
        }

        return IYearnOracle(_oracle).price(tokenInfo);
    }

    function addToken(TokenInfo calldata _tokenInfo) external {
        tokens.push(_tokenInfo);
    }
}