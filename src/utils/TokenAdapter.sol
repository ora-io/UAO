// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ******** Errors ************
error TransferInFail();
error TransferOutFail();
error ZeroAmount();

address constant ETH_IDENTIFIER = address(0);

contract TokenAdapter {
    function _tokenTransferIn(address _token, address from, uint256 _amount) internal {
        if (_amount == 0) revert ZeroAmount();
        bool success;
        if (_token == ETH_IDENTIFIER) {
            success = msg.value == _amount;
        } else {
            success = IERC20(_token).transferFrom(from, address(this), _amount);
        }
        if (!success) revert TransferInFail();
    }

    function _tokenTransferOut(address _token, address _to, uint256 _amount) internal {
        if (_amount == 0) revert ZeroAmount();
        bool success;
        if (_token == ETH_IDENTIFIER) {
            (success,) = _to.call{value: _amount}(new bytes(0));
        } else {
            success = IERC20(_token).transfer(_to, _amount);
        }
        if (!success) revert TransferOutFail();
    }

    function _tokenBalanceOf(address _token, address _holder) internal view returns (uint256 balance) {
        if (_token == ETH_IDENTIFIER) {
            balance = _holder.balance;
        } else {
            balance = IERC20(_token).balanceOf(_holder);
        }
        return balance;
    }
}
