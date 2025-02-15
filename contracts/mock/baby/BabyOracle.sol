// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "@ora-io/uao/AsyncOracle.sol";
import "@ora-io/uao/fee/model/FeeModel_Free.sol";

bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyOracle is AsyncOracle, FeeModel_Free {
    function initializeBabyOracle()  
        external
        initializer
    {
        _initializeAsyncOracle(callbackFunctionSelector);
    }
}
