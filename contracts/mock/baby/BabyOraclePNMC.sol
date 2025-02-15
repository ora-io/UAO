// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "@ora-io/uao/AsyncOracle.sol";
import "@ora-io/uao/fee/model/FeeModel_PNMC_Ownerable.sol";

bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyOraclePNMC is 
    AsyncOracle, 
    FeeModel_PNMC_Ownerable {
    function initialize(address owner, address financialOperator, address feeToken, uint256 protocolFee, uint256 nodeFee)  
        external
        initializer
    {
        _initializeAsyncOracle(callbackFunctionSelector);
        _initializeFeeModel_PNMC_Ownerable(owner, financialOperator, feeToken, protocolFee, nodeFee);
    }

    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external payable override onlyModelExists(modelId) returns (uint256 requestId) { // add onlyModelExists(modelId)
        requestId = _nextRequestID();
        _async(requestId, modelId, input, callbackAddr, gasLimit, callbackData);
    }
    
    function invoke(uint256 requestId, bytes calldata output, bytes calldata) external override onlyNode(msg.sender) {
        // invoke callback
        _invoke(requestId, output);
        _updateGasPrice();
    }
}
