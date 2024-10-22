// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AsyncOracle.sol";
import {IFraudAsync} from "./interface/IAsyncOracle.sol";

abstract contract AsyncOracleFraud is AsyncOracle, IFraudAsync {
    // **************** Setup Functions  ****************

    function _initializeAsyncOracleFraud(bytes4 _callbackFunctionSelector) 
        internal
        onlyInitializing
    {
       _initializeAsyncOracle(_callbackFunctionSelector);
    }

    function invoke(uint256 requestId, bytes memory output) external virtual {
        _invoke(requestId, output);
    }
}