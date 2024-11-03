// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./AsyncOracle.sol";

error AlreadyInvoked();
error VerifyFailed();

abstract contract AsyncOracleValidity is AsyncOracle {
    // **************** Setup Functions  ****************
    
    function _initializeAsyncOracleValidity(bytes4 _callbackFunctionSelector) 
        internal
        onlyInitializing
    {
       _initializeAsyncOracle(_callbackFunctionSelector);
    }

    mapping(uint256 => bool) invoked;

    function _verify(uint256, bytes calldata, bytes calldata) internal pure virtual returns (bool) {
        return true;
    }

    function invoke(uint256 requestId, bytes calldata output, bytes calldata proof) external override virtual {
        // only invoke once in validity style async oracle
        if (invoked[requestId]) revert AlreadyInvoked();
        invoked[requestId] = true;
        // verify output
        if (!_verify(requestId, output, proof)) revert VerifyFailed();
        // invoke
        _invoke(requestId, output);
    }
}
