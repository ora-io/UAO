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
 *   - fee = protocol fee + node fee + model fee + callback fee
 *   - contract balance = protocol revenue + node revenue + model receiver revenue
 *   - protocol revenue = protocol fee + model total commission revenue (+ non-recorded transfer)
 *   - node revenue = node fee + callback fee
 */
abstract contract FeeModel_PNMC_Ownerable is
    OwnableUpgradeable,
    IFeeModel,
    ProtocolFee,
    NodeFee,
    ModelFee,
    CallbackFee,
    AsyncOracle,
    FinancialOperator
{
    // **************** Setup Functions  ****************
    
    function _initializeFeeModel_PNMC_Ownerable(address owner, address _financialOperator, address _feeToken, uint256 _protocolFee, uint256 _nodeFee) 
        internal
        onlyInitializing
    {
        __Ownable_init(owner);
        _setFinancialOperator(_financialOperator);
        _setFeeToken(_feeToken);
        _setProtocolFeeAmount(_protocolFee);
        _setNodeFeeAmount(_nodeFee);
    }

    // ********** Overrides **********

    function _estimateFee(Request storage _request)
        internal
        view
        override(ProtocolFee, NodeFee, ModelFee, CallbackFee)
        returns (uint256)
    {
        return ProtocolFee._estimateFee(_request) + ModelFee._estimateFee(_request) + NodeFee._estimateFee(_request)
            + CallbackFee._estimateFee(_request);
    }

    function _estimateFeeMemory(Request memory _request)
        internal
        view
        override(ProtocolFee, NodeFee, ModelFee, CallbackFee)
        returns (uint256)
    {
        return ProtocolFee._estimateFeeMemory(_request) + ModelFee._estimateFeeMemory(_request)
            + NodeFee._estimateFeeMemory(_request) + CallbackFee._estimateFeeMemory(_request);
    }

    function _recordRevenue(Request storage _request, uint256 _remaining)
        internal
        override(ProtocolFee, NodeFee, ModelFee, CallbackFee)
        returns (uint256)
    {
        // record model fee (both receiver fee & commission fee)
        _remaining = ModelFee._recordRevenue(_request, _remaining);
        _remaining = NodeFee._recordRevenue(_request, _remaining);
        // add callback fee to node fee request cache
        _remaining = _recordCallbackFeeToNodeFee(_request, _remaining);
        _remaining = ProtocolFee._recordRevenue(_request, _remaining);

        // when user paid more, add all remaining as protocol revenue
        // or can refund by updating the following
        ProtocolFee._addProtocolRevenue(_remaining);
        _remaining = 0;

        return _remaining;
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
        // other revenue: _getProtocolRevenue + _getModelTotalCommissionRevenue + not recorded transfer
        uint256 nonprotocol =
            _totalModelReceiverRevenue() + _totalNodeRevenue + _totalRequestNodeFeeCache + _getCallbackReimbursement();
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
    function setFee(address _feeToken, uint256 _protocolFeeAmount, uint256 _nodeFeeAmount) external virtual onlyOwner {
        _setFeeToken(_feeToken);
        _setProtocolFeeAmount(_protocolFeeAmount);
        _setNodeFeeAmount(_nodeFeeAmount);
    }

    // use default NodeFee externals

    // use default ModelFee externals, keep claimModelRevenue impl to child contract considering the modelId existance check (user-friendly)

    // ********** Internal **********

    /**
     * main entrance of receive and record reveune
     */
    function _receiveAndRecordRevenue(Request storage _request, uint256 _amount) internal {
        _recordRevenue(_request, _amount);
        _tokenTransferIn(feeToken, msg.sender, _amount);
    }

    /**
     * add callback fee to node fee request cache
     */
    function _recordCallbackFeeToNodeFee(Request storage _request, uint256 _remaining) internal returns (uint256) {
        uint256 cbfee = CallbackFee._estimateFee(_request);
        if (_remaining < cbfee) revert InsufficientFee(FeeType.CallbackFee);
        NodeFee._addRequestNodeFeeCache(_request.requestId, cbfee);
        return _remaining - cbfee;
    }
}
