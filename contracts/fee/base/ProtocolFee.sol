// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "../FeeUtils.sol";

/**
 * Protocol Fee Structure:
 *   - all Protocol revenue = _getProtocolRevenue()
 */
abstract contract ProtocolFee is FeeUtils, Initializable {
    // fee setup
    address internal _protocolFeeToken;
    uint256 internal _protocolFeeAmount;
    address internal _protocolRevenueReceiver;
    // fee accumulated
    uint256 internal _protocolRevenue;

    // **************** Setup Functions  ****************
    function _initializeProtocolFee(address _feeToken, uint256 _feeAmount, address _revenueReceiver) 
        internal 
        onlyInitializing
    {
        _setProtocolFee(_feeToken, _feeAmount);
        _setProtocolRevenueReceiver(_revenueReceiver);
    }

    // *********** Overrides ***********

    function _estimateFee(Request storage) internal view virtual override returns (uint256) {
        return _protocolFeeAmount;
    }

    function _estimateFeeMemory(Request memory) internal view virtual override returns (uint256) {
        return _protocolFeeAmount;
    }

    function _recordRevenue(Request storage, uint256 _remaining)
        internal
        virtual
        override
        returns (uint256 remaining)
    {
        if (_remaining < _protocolFeeAmount) revert InsufficientFee(FeeType.ProtocolFee);
        _addProtocolRevenue(_protocolFeeAmount);
        remaining = _remaining - _protocolFeeAmount;
    }

    // *********** Externals ***********
    //   - exist because it's mandatory, and may merge with other fees;

    function getProtocolRevenue() external virtual returns (uint256);
    function claimProtocolRevenue() external virtual;

    // *********** Internals - Protocol Fee ***********

    function _getProtocolFeeToken() internal view returns (address) {
        return _protocolFeeToken;
    }

    function _getProtocolFeeAmount() internal view returns (uint256) {
        return _protocolFeeAmount;
    }

    function _setProtocolFee(address _feeToken, uint256 _feeAmount) internal {
        _protocolFeeToken = _feeToken;
        _protocolFeeAmount = _feeAmount;
    }

    // *********** Internals - Protocol Revenue ***********

    function _getProtocolRevenue() internal view returns (uint256) {
        return _protocolRevenue;
    }

    function _addProtocolRevenue(uint256 _amount) internal {
        _protocolRevenue += _amount;
    }

    function _resetProtocolRevenue() internal {
        _protocolRevenue = 0;
    }

    function _claimProtocolRevenue() internal virtual {
        uint256 amountOut = _protocolRevenue;
        _resetProtocolRevenue();
        _tokenTransferOut(_protocolFeeToken, _getProtocolRevenueReceiver(), amountOut);
    }

    function _getProtocolRevenueReceiver() internal virtual returns (address) {
        return _protocolRevenueReceiver;
    }

    function _setProtocolRevenueReceiver(address _revenueReceiver) internal virtual {
        _protocolRevenueReceiver = _revenueReceiver;
    }
}
