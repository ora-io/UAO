// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "../../AsyncOracle.sol";
import "../base/ModelFee.sol";
import "../base/NodeFee.sol";
import "../base/ProtocolFee.sol";
import "../base/CallbackFee.sol";
import "../../interfaces/IFeeModel.sol";
import "../../manage/FinancialOperator.sol";

/**
 * Fee Model Structure:
 *   - fee = protocol fee + model fee + callback fee
 *   - contract balance = protocol revenue + model receiver revenue
 *   - protocol revenue = protocol fee + model total commission revenue + callback fee (+ non-recorded transfer)
 */
abstract contract FeeModel_PMC_Ownerable is
    OwnableUpgradeable,
    IFeeModel,
    ProtocolFee,
    ModelFee,
    CallbackFee,
    AsyncOracle,
    FinancialOperator
{

    // **************** Setup Functions  ****************

    function _initializeFeeModel_PMC_Ownerable(address owner, address _feeToken, uint256 _protocolFee, address _financialOperator) 
        internal 
        onlyInitializing 
    {
        __Ownable_init(owner);
        _initializeProtocolFee(_protocolFee);
        _setFeeToken(_feeToken);
        _setFinancialOperator(_financialOperator);
    }

    // ********** Overrides **********

    function _estimateFee(Request storage _request)
        internal
        view
        override(ProtocolFee, ModelFee, CallbackFee)
        returns (uint256)
    {
        return ProtocolFee._estimateFee(_request) + ModelFee._estimateFee(_request) + CallbackFee._estimateFee(_request);
    }

    function _estimateFeeMemory(Request memory _request)
        internal
        view
        override(ProtocolFee, ModelFee, CallbackFee)
        returns (uint256)
    {
        return ProtocolFee._estimateFeeMemory(_request) + ModelFee._estimateFeeMemory(_request)
            + CallbackFee._estimateFeeMemory(_request);
    }

    function _recordRevenue(Request storage _request, uint256 _remaining)
        internal
        override(ProtocolFee, ModelFee, CallbackFee)
        returns (uint256)
    {
        // record model fee (both receiver fee & commission fee)
        _remaining = ModelFee._recordRevenue(_request, _remaining);
        _remaining = ProtocolFee._recordRevenue(_request, _remaining);

        // when user paid more, add all remaining as protocol revenue
        // or can refund by updating the following
        ProtocolFee._addProtocolRevenue(_remaining);
        _remaining = 0;

        return _remaining;
    }

    function setFinancialOperator(address _operator) external override onlyOwner {
        _setFinancialOperator(_operator);
    }

    function setModelFeeData(uint256 _modelId, uint256 _fee, address _receiver, uint256 _receiverPercentage) external override onlyOwner {
        _setModelFeeData(_modelId, _fee, _receiver, _receiverPercentage);
    }

    function claimModelReceiverRevenue(uint256 modelId) external override onlyModelExists(modelId) {
        _claimModelReceiverRevenue(modelId);
    }

    // ********** Externals - Permissionless **********

    function estimateFee(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external view virtual returns (uint256) {
        Request memory requestMemory = _newRequestCalldataToMemory(
            msg.sender, _peekNextRequestID(), modelId, input, callbackAddr, gasLimit, callbackData
        );
        return _estimateFeeMemory(requestMemory);
    }

    /**
     * include model commission revenue (i.e. the 1-receiverPercentage part) in protocol revenue
     */
    function getProtocolRevenue() public view virtual override returns (uint256) {
        uint256 balance = _tokenBalanceOf(feeToken, address(this));
        // other revenue: _getCallbackReimbursement + _getProtocolRevenue + _getModelTotalCommissionRevenue + not recorded transfer
        uint256 nonprotocol = _totalModelReceiverRevenue();
        // assert(balance >= nonprotocol);
        return balance - nonprotocol;
    }

    // ********** Externals - Admin **********

    function claimProtocolRevenue() public virtual override onlyFinancialOperator {
        // CEI
        uint256 amountOut = getProtocolRevenue();
        _resetProtocolRevenue();
        _resetModelTotalCommissionRevenue();
        // transfer
        _tokenTransferOut(feeToken, _financialOperator, amountOut);
    }

    /**
     * help function to set fee token and protocol fee amount
     */
    function setFee(address _feeToken, uint256 _protocolFeeAmount) external virtual onlyOwner {
        _setFeeToken(_feeToken);
        _setProtocolFeeAmount(_protocolFeeAmount);
    }

    // ********** Internal **********

    /**
     * main entrance of receive and record reveune
     */
    function _receiveAndRecordRevenue(Request storage _request, uint256 _amount) internal {
        _recordRevenue(_request, _amount);
        _tokenTransferIn(feeToken, msg.sender, _amount);
    }
    
}
