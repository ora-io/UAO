// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "../FeeUtils.sol";
import "../../manage/ModelManageBase.sol";

/**
 * Model Fee Structure:
 *   - all ModelFee revenue = _getModelTotalCommissionRevenue + _totalModelReceiverRevenue
 *   - receiverRevenue: += fee * receiverPercentage; claimable by _claimModelReceiverRevenue
 *   - commissionRevenue: += fee * (1-receiverPercentage); claimable by _claimModelTotalCommissionRevenue
 */
struct ModelFeeData {
    uint256 fee;
    address receiver;
    uint256 receiverPercentage;
    uint256 receiverRevenue; //TODO: balance[] format?
}

error InvalidPercentage();

//TODO: test ownership transfer
abstract contract ModelFee is FeeUtils, ModelManageBase, Initializable {
    // fee setup
    address internal _modelFeeToken;
    address internal _modelCommissionRevenueReceiver;
    // accumulated commission fee, i.e. non-receiver fee
    uint256 internal _totalCommissionRevenue;

    mapping(uint256 => ModelFeeData) modelFeeMap;

    // **************** Setup Functions  ****************
    
    function _initializeModelFee(address _feeToken, address _commissionRevenueReceiver) 
        internal 
        onlyInitializing
    {
        _setModelToken(_feeToken);
        _setModelCommissionRevenueReceiver(_commissionRevenueReceiver);
    }

    // ********** Overrides **********

    function _estimateFee(Request storage _request) internal view virtual override returns (uint256) {
        return modelFeeMap[_request.modelId].fee;
    }

    function _estimateFeeMemory(Request memory _request) internal view virtual override returns (uint256) {
        return modelFeeMap[_request.modelId].fee;
    }

    function _recordRevenue(Request storage _request, uint256 remaining)
        internal
        virtual
        override
        returns (uint256 _remaining)
    {
        // check fees
        uint256 fee = _estimateFee(_request);
        if (remaining < fee) revert InsufficientFee(FeeType.ModelFee);
        // calc fee amounts
        uint256 receiverFeeAmount = fee * modelFeeMap[_request.modelId].receiverPercentage / 100;
        uint256 commissionFeeAmount = (fee - receiverFeeAmount);
        // add revenues
        _addModelReceiverRevenue(_request.modelId, receiverFeeAmount);
        _addModelTotalCommissionRevenue(commissionFeeAmount);
        // for returns
        _remaining = remaining - fee;
    }

    // *********** Externals ***********
    //   - remember to check modelId existance

    function getModelFeeData(uint256 modelId)
        external
        view
        virtual
        onlyModelExists(modelId)
        returns (ModelFeeData memory)
    {
        return _getModelFeeData(modelId);
    }

    function claimModelReceiverRevenue(uint256 modelId) external virtual onlyModelExists(modelId) {
        _claimModelReceiverRevenue(modelId);
    }

    // ********** Internals - Model Fee **********

    function _getModelFeeData(uint256 _modelId) internal view returns (ModelFeeData memory) {
        ModelFeeData memory model = modelFeeMap[_modelId];
        return model;
    }

    function _setModelFeeData(uint256 _modelId, uint256 _fee, address _receiver, uint256 _receiverPercentage)
        internal
    {
        if (_receiverPercentage > 100) revert InvalidPercentage(); // percentage should be <= 100
        ModelFeeData storage model = modelFeeMap[_modelId];
        model.fee = _fee;
        model.receiver = _receiver;
        model.receiverPercentage = _receiverPercentage;
    }

    function _setModelFee(uint256 _modelId, uint256 _fee) internal onlyModelExists(_modelId) {
        ModelFeeData storage model = modelFeeMap[_modelId];
        model.fee = _fee;
    }

    function _setModelReceiver(uint256 _modelId, address _receiver) internal onlyModelExists(_modelId) {
        ModelFeeData storage model = modelFeeMap[_modelId];
        model.receiver = _receiver;
    }

    function _setModelReceiverPercentage(uint256 _modelId, uint256 _receiverPercentage)
        internal
        onlyModelExists(_modelId)
    {
        if (_receiverPercentage > 100) revert InvalidPercentage(); // percentage should be <= 100
        ModelFeeData storage model = modelFeeMap[_modelId];
        model.receiverPercentage = _receiverPercentage;
    }

    function _getModelToken() internal view returns (address) {
        return _modelFeeToken;
    }

    // separate setters of token and fee amount: because token is universal while fee amount is model-specific
    function _setModelToken(address _feeToken) internal {
        _modelFeeToken = _feeToken;
    }

    /**
     * exist as an remainter to claim model fee to _receiver when remove model fee
     */
    function _removeModelFee(uint256 _modelId) internal {
        _claimModelReceiverRevenue(_modelId);
    }

    // ********** Internals - Model Receiver Revenue **********

    function _getModelReceiverRevenue(uint256 _modelId) internal view returns (uint256) {
        return modelFeeMap[_modelId].receiverRevenue;
    }

    function _addModelReceiverRevenue(uint256 _modelId, uint256 _amount) internal {
        modelFeeMap[_modelId].receiverRevenue += _amount;
    }

    function _resetModelReceiverRevenue(uint256 _modelId) internal {
        modelFeeMap[_modelId].receiverRevenue = 0;
    }

    // use storage since usually called when
    function _totalModelReceiverRevenue() internal view returns (uint256) {
        uint256 totalReceiverRevenue;
        for (uint256 i = 0; i < modelIDs.length; i++) {
            totalReceiverRevenue += _getModelReceiverRevenue(modelIDs[i]);
        }
        return totalReceiverRevenue;
    }

    function _claimModelReceiverRevenue(uint256 _modelId) internal {
        ModelFeeData storage modelFee = modelFeeMap[_modelId];

        // user friendly check
        if (modelFee.receiverRevenue == 0) revert ZeroRevenue();

        // CEI Princeple
        uint256 amountOut = modelFee.receiverRevenue;

        // reset model _receiver revenue then transfer
        _resetModelReceiverRevenue(_modelId);
        _tokenTransferOut(_modelFeeToken, modelFee.receiver, amountOut);
    }

    // ********** Internals - Commission Revenue **********

    function _getModelTotalCommissionRevenue() internal view returns (uint256) {
        return _totalCommissionRevenue;
    }

    function _addModelTotalCommissionRevenue(uint256 _amount) internal {
        _totalCommissionRevenue += _amount;
    }

    function _resetModelTotalCommissionRevenue() internal {
        _totalCommissionRevenue = 0;
    }

    // ********** Internals - Claim Commission Revenue **********
    //    - can ignore this and claim in the high level (e.g. merge with other fee)
    //    - no external claimModelTotalCommissionRevenue() because it's optional.

    function _claimModelTotalCommissionRevenue() internal {
        // CEI Princeple
        uint256 amountOut = _totalCommissionRevenue;

        // reset model commision revenue then transfer
        _resetModelTotalCommissionRevenue();
        _tokenTransferOut(_modelFeeToken, _getModelCommissionRevenueReceiver(), amountOut);
    }

    function _getModelCommissionRevenueReceiver() internal virtual returns (address) {
        return _modelCommissionRevenueReceiver;
    }

    function _setModelCommissionRevenueReceiver(address _commissionRevenueReceiver) internal virtual {
        _modelCommissionRevenueReceiver = _commissionRevenueReceiver;
    }
}
