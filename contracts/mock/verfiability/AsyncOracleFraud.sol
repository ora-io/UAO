// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

// import "./AsyncOracle.sol";
// import {IAsyncFraud} from "./interfaces/IAsyncOracle.sol";

import "@ora-io/uao/AsyncOracle.sol";
import {IAsyncFraud} from "@ora-io/uao/interfaces/IAsyncOracle.sol";

contract AsyncOracleFraud is AsyncOracle, IAsyncFraud {
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

    function update(uint256 requestId, bytes calldata output) external virtual {
        _invoke(requestId, output);
    }
}