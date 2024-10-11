// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AsyncOracleUpgradeable.sol";
import {IValidityAsync} from "./interface/IAsyncOracle.sol";

error AlreadyInvoked();
error VerifyFailed();

abstract contract AsyncOracleValidityUpgradeable is AsyncOracleUpgradeable, IValidityAsync {
    // constructor(bytes4 _callbackFunctionSelector) AsyncOracle(_callbackFunctionSelector) {}

    // **************** Setup Functions  ****************
    function initializeAsyncOracleValidity(bytes4 _callbackFunctionSelector) 
        external
        initializer
    {
       _initializeAsyncOracle(_callbackFunctionSelector);
    }

    mapping(uint256 => bool) invoked;

    function _verify(uint256, bytes memory, bytes memory) internal pure virtual returns (bool) {
        return true;
    }

    function invoke(uint256 requestId, bytes memory output, bytes memory proof) external virtual {
        // only invoke once in validity style async oracle
        if (invoked[requestId]) revert AlreadyInvoked();
        invoked[requestId] = true;
        // verify output
        if (!_verify(requestId, output, proof)) revert VerifyFailed();
        // invoke
        _invoke(requestId, output);
        // _updateGasPrice();
    }
}
