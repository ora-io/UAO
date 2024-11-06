// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AsyncOracle.sol";
import {IFraudAsync} from "./interfaces/IAsyncOracle.sol";

contract AsyncOracleFraud is AsyncOracle, IFraudAsync {
    // **************** Setup Functions  ****************

    function _initializeAsyncOracleFraud(bytes4 _callbackFunctionSelector) 
        internal
        onlyInitializing
    {
       _initializeAsyncOracle(_callbackFunctionSelector);
    }

    function invoke(uint256 requestId, bytes calldata output, bytes calldata) external override virtual {
        _invoke(requestId, output);
    }

    function update(uint256 requestId) external virtual {
        _invoke(requestId, _getOutput(requestId));
    }

    function _getOutput(uint256 requestId) internal pure returns (bytes memory) {
        return new bytes(0);
    }
}