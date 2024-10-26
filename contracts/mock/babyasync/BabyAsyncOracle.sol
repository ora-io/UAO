// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@ora-io/uao/AsyncOracleValidity.sol";
import "@ora-io/uao/fee/model/FeeModel_Free.sol";

bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyAsyncOracle is AsyncOracleValidity, FeeModel_Free {
    function initializeBabyAsyncOracle()  
        external
        initializer
    {
        _initializeAsyncOracleValidity(callbackFunctionSelector);
    }
}
