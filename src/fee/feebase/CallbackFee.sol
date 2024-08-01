// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../FeeUtils.sol";

/**
 * Callback Fee Structure:
 *   - all Callback revenue = _getCallbackReimbursement()
 */
contract CallbackFee is FeeUtils {
    uint256 public gasPrice;
    // can ignore, record callback fee from requests in the same place
    uint256 internal _callbackReimbursement;

    // ********** Overrides **********

    function _estimateFee(Request storage _request) internal view virtual override returns (uint256) {
        return gasPrice * _request.gasLimit;
    }

    function _estimateFeeMemory(Request memory _request) internal view virtual override returns (uint256) {
        return gasPrice * _request.gasLimit;
    }

    function _recordRevenue(Request storage _request, uint256 _remaining)
        internal
        virtual
        override
        returns (uint256 remaining)
    {
        uint256 fee = _estimateFee(_request);
        if (_remaining < fee) revert InsufficientFee(FeeType.CallbackFee);
        _addCallbackReimbursement(_remaining);
        remaining = _remaining - fee;
    }

    // ********** Internals - Gas Price **********

    function _updateGasPrice() internal {
        gasPrice = tx.gasprice;
    }

    // ********** Internals - Callback Reimbursement **********

    function _getCallbackReimbursement() internal view returns (uint256) {
        return _callbackReimbursement;
    }

    function _addCallbackReimbursement(uint256 _amount) internal {
        _callbackReimbursement += _amount;
    }

    function _resetCallbackReimbursement() internal {
        _callbackReimbursement = 0;
    }
}
