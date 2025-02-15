// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "@ora-io/uao/AsyncOracle.sol";
import "@ora-io/uao/fee/model/FeeModel_PMC_Ownerable.sol";
import "@ora-io/uao/manage/InvokeOperator.sol";

bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyOraclePMC is 
    AsyncOracle, 
    FeeModel_PMC_Ownerable,
    InvokeOperator {
    function initialize(address owner, address financialOperator, address invokeOperator, address feeToken, uint256 protocolFee)  
        external
        initializer
    {
        _initializeAsyncOracle(callbackFunctionSelector);
        _initializeFeeModel_PMC_Ownerable(owner, financialOperator, feeToken, protocolFee);
        _setInvokeOperator(invokeOperator);
    }

    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external payable override onlyModelExists(modelId) returns (uint256 requestId) {
        requestId = _nextRequestID();
        _async(requestId, modelId, input, callbackAddr, gasLimit, callbackData);
    }
    
    function invoke(uint256 requestId, bytes calldata output, bytes calldata) external override onlyInvokeOperator {
        // invoke callback
        _invoke(requestId, output);
        _updateGasPrice();
    }
}
