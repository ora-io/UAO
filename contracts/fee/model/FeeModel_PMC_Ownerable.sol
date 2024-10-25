// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../AsyncOracle.sol";
import "../base/ModelFee.sol";
import "../base/NodeFee.sol";
import "../base/ProtocolFee.sol";
import "../base/CallbackFee.sol";
import "../../interface/IFeeModel.sol";

/**
 * Fee Model Structure:
 *   - fee = protocol fee + model fee + callback fee
 *   - contract balance = protocol revenue + model receiver revenue
 *   - protocol revenue = protocol fee + model total commission revenue + callback fee (+ non-recorded transfer)
 */
abstract contract FeeModel_PMC_Ownerable is IFeeModel, ProtocolFee, ModelFee, CallbackFee, Ownable, AsyncOracle {
    constructor(address _feeToken, uint256 _protocolFee)
        ModelFee(_feeToken, owner())
        ProtocolFee(_feeToken, _protocolFee, owner())
    {}

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

    // ********** Externals - Permissionless **********

    function estimateFee(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) external view virtual returns (uint256) {
        Request memory requestMemory = _newRequestCalldataToMemory(
            msg.sender, _peekNextRequestID(), modelId, input, callbackAddr, gasLimit, callbackData, inputDA, outputDA
        );
        return _estimateFeeMemory(requestMemory);
    }

    /**
     * include model commission revenue (i.e. the 1-receiverPercentage part) in protocol revenue
     */
    function getProtocolRevenue() public view virtual override returns (uint256) {
        uint256 balance = _tokenBalanceOf(_protocolFeeToken, address(this));
        // other revenue: _getCallbackReimbursement + _getProtocolRevenue + _getModelTotalCommissionRevenue + not recorded transfer
        uint256 nonprotocol = _totalModelReceiverRevenue();
        // assert(balance >= nonprotocol);
        return balance - nonprotocol;
    }

    // ********** Externals - Admin **********

    function claimProtocolRevenue() public virtual override onlyOwner {
        // CEI
        uint256 amountOut = getProtocolRevenue();
        _resetProtocolRevenue();
        _resetModelTotalCommissionRevenue();
        // transfer
        _tokenTransferOut(_protocolFeeToken, _getProtocolRevenueReceiver(), amountOut);
    }

    function setFee(address _feeToken, uint256 _protocolFeeAmount) external virtual onlyOwner {
        _setProtocolFee(_feeToken, _protocolFeeAmount);
        _setModelToken(_feeToken);
    }

    // ********** Internal **********

    /**
     * main entrance of receive and record reveune
     */
    function _receiveAndRecordRevenue(Request storage _request, uint256 _amount) internal {
        _recordRevenue(_request, _amount);
        _tokenTransferIn(_protocolFeeToken, msg.sender, _amount);
    }
}
