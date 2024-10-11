// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

// import "@openzeppelin/contracts/access/Ownable.sol";
import "../../AsyncOracleUpgradeable.sol";
import "../base/ModelFeeUpgradeable.sol";
import "../base/NodeFeeUpgradeable.sol";
import "../base/ProtocolFeeUpgradeable.sol";
import "../base/CallbackFee.sol";
import "../../interface/IFeeModel.sol";

abstract contract FeeModel_PMC_OwnerableUpgradeable is
    IFeeModel,
    ProtocolFeeUpgradeable,
    ModelFeeUpgradeable,
    CallbackFee,
    OwnableUpgradeable,
    AsyncOracleUpgradeable
{
    // constructor(address _feeToken, uint256 _protocolFee)
    //     ModelFee(_feeToken, owner())
    //     ProtocolFee(_feeToken, _protocolFee, owner())
    // {}

    // **************** Setup Functions  ****************
    function initialize(address _feeToken, uint256 _protocolFee) 
        external
        initializer
    {
       _initializeModelFee(_feeToken, owner());
       _initializeProtocolFee(_feeToken, _protocolFee, owner());
    }

    // ********** Overrides **********

    function _estimateFee(Request storage _request)
        internal
        view
        override(ProtocolFeeUpgradeable, ModelFeeUpgradeable, CallbackFee)
        returns (uint256)
    {
        return ProtocolFeeUpgradeable._estimateFee(_request) + ModelFeeUpgradeable._estimateFee(_request)
            + CallbackFee._estimateFee(_request);
    }

    function _estimateFeeMemory(Request memory _request)
        internal
        view
        override(ProtocolFeeUpgradeable, ModelFeeUpgradeable, CallbackFee)
        returns (uint256)
    {
        return ProtocolFeeUpgradeable._estimateFeeMemory(_request) + ModelFeeUpgradeable._estimateFeeMemory(_request) + CallbackFee._estimateFeeMemory(_request);
        // return super.estimateFee(modelId, gasLimit);
    }

    function _recordRevenue(Request storage _request, uint256 _remaining)
        internal
        override(ProtocolFeeUpgradeable, ModelFeeUpgradeable, CallbackFee)
        returns (uint256)
    {
        // record model fee (both receiver fee & commission fee)
        _remaining = ModelFeeUpgradeable._recordRevenue(_request, _remaining);
        _remaining = ProtocolFeeUpgradeable._recordRevenue(_request, _remaining);

        // when user paid more, add all remaining as protocol revenue
        // or can refund by updating the following
        ProtocolFeeUpgradeable._addProtocolRevenue(_remaining);
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
        Request memory requestMemory = _newRequestMemory(
            msg.sender, _peekNextRequestID(), modelId, input, callbackAddr, gasLimit, callbackData, inputDA, outputDA
        );
        return _estimateFeeMemory(requestMemory);
        // return super.estimateFee(modelId, gasLimit);
    }

    /**
     * include model commission revenue (i.e. the 1-receiverPercentage part) in protocol revenue
     */
    function getProtocolRevenue() public view virtual override returns (uint256) {
        uint256 balance = _tokenBalanceOf(_protocolFeeToken, address(this));
        // other revenue: _protocolRevenue + _commissionRevenue + not recorded transfer
        uint256 nonprotocol =
            _totalModelReceiverRevenue() + _getCallbackReimbursement();
        // return _getProtocolRevenue() + _getModelTotalCommissionRevenue();
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
