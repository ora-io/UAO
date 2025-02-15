// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "../utils/TokenAdapter.sol";
import "../interfaces/IAsyncOracle.sol";

enum FeeType {
    ModelFee,
    NodeFee,
    ProtocolFee,
    CallbackFee
}

error InsufficientFee(FeeType);
error ZeroRevenue(); // current revenue is zero

abstract contract FeeUtils is TokenAdapter {
    address internal feeToken;
    function _estimateFee(Request storage _request) internal view virtual returns (uint256);
    function _estimateFeeMemory(Request memory _request) internal view virtual returns (uint256);
    function _recordRevenue(Request storage _request, uint256 _remaining) internal virtual returns (uint256);

    function getFeeToken() external view returns (address) {
        return feeToken;
    }

    function setFeeToken(address _feeToken) external {
        _setFeeToken(_feeToken);
    }

    function _setFeeToken(address _feeToken) internal {
        feeToken = _feeToken;
    }
}
