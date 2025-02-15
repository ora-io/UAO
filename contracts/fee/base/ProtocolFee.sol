// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "../FeeUtils.sol";

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
/**
 * Protocol Fee Structure:
 *   - all Protocol revenue = _getProtocolRevenue()
 */
abstract contract ProtocolFee is FeeUtils, OwnableUpgradeable {
    // fee setup
    uint256 internal _protocolFeeAmount;
    // fee accumulated
    uint256 internal _protocolRevenue;

    // **************** Setup Functions  ****************
    
    function _initializeProtocolFee(uint256 _feeAmount) 
        internal 
        onlyInitializing
    {
        _setProtocolFeeAmount(_feeAmount);
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

    // *********** Externals - Fee ***********

    function getProtocolFeeAmount() external virtual returns (uint256) {
        return _getProtocolFeeAmount();
    }
    function setProtocolFeeAmount(uint256 _feeAmount) external virtual onlyOwner {
        _setProtocolFeeAmount(_feeAmount);
    }

    // *********** Externals - Revenue ***********

    // - exist because it's mandatory, and may merge with other fees;
    function getProtocolRevenue() external virtual returns (uint256);
    function claimProtocolRevenue() external virtual;

    // *********** Internals - Fee ***********

    function _getProtocolFeeAmount() internal view returns (uint256) {
        return _protocolFeeAmount;
    }

    function _setProtocolFeeAmount(uint256 _feeAmount) internal {
        _protocolFeeAmount = _feeAmount;
    }

    // *********** Internals - Revenue ***********

    function _getProtocolRevenue() internal view returns (uint256) {
        return _protocolRevenue;
    }

    function _addProtocolRevenue(uint256 _amount) internal {
        _protocolRevenue += _amount;
    }

    function _resetProtocolRevenue() internal {
        _protocolRevenue = 0;
    }

    function _claimProtocolRevenue(address _receiver) internal virtual {
        uint256 amountOut = _protocolRevenue;
        _resetProtocolRevenue();
        _tokenTransferOut(feeToken, _receiver, amountOut);
    }
}
