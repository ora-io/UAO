// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "@ora-io/uao/AsyncOracle.sol";
import "@ora-io/uao/fee/model/FeeModel_PMC_Ownerable.sol";
import "@ora-io/uao/manage/ModelManageBase.sol";
import "@ora-io/uao/manage/NodeManageBase.sol";

bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyOraclePMC is 
    ModelManageBase,
    NodeManageBase,
    AsyncOracle, 
    FeeModel_PMC_Ownerable {
    function initializeBabyOracle(address _feeToken, uint256 _protocolFee, address _financialOperator)  
        external
        initializer
    {
        _initializeAsyncOracle(callbackFunctionSelector);
        _initializeFeeModel_PMC_Ownerable(msg.sender, _feeToken, _protocolFee, _financialOperator);
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

    function addModel(
        uint256 modelId,
        uint256 fee,
        address receiver,
        uint256 receiverPercentage
    ) external onlyOwner onlyModelNotExists(modelId) {
        _addModel(modelId);
        _setModelFeeData(modelId, fee, receiver, receiverPercentage);
    }
}
