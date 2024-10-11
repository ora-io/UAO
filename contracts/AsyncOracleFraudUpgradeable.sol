// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AsyncOracleUpgradeable.sol";
import {IFraudAsync} from "./interface/IAsyncOracle.sol";

abstract contract AsyncOracleFraudUpgradeable is AsyncOracleUpgradeable, IFraudAsync {
    // constructor(bytes4 _callbackFunctionSelector) AsyncOracle(_callbackFunctionSelector) {}
    
    // **************** Setup Functions  ****************
    function _initializeAsyncOracleFraud(bytes4 _callbackFunctionSelector) 
        internal
        onlyInitializing
    {
       _initializeAsyncOracle(_callbackFunctionSelector);
    }

    function invoke(uint256 requestId, bytes memory output) external virtual {
        _invoke(requestId, output);
        // _updateGasPrice();
    }

    // function update(uint256 requestId) external virtual {
    //     // bytes output = getUpdatedOutput()
    //     _invoke(requestId, output);
    // }
}