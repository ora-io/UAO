// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../utils/TokenAdapter.sol";
import "../interface/IAsyncOracle.sol";

enum FeeType {
    ModelFee,
    NodeFee,
    ProtocolFee,
    CallbackFee
}

error InsufficientFee(FeeType);
error ZeroRevenue(); // current revenue is zero

abstract contract FeeUtils is TokenAdapter {
    // function _estimateFee(uint256 _modelId, uint256 _gasLimit) internal view virtual returns (uint256);
    // function _recordRevenue(uint256 _modelId, uint256 _gasLimit, uint256 _remaining)
    function _estimateFee(Request storage _request) internal view virtual returns (uint256);
    function _estimateFeeMemory(Request memory _request) internal view virtual returns (uint256);
    function _recordRevenue(Request storage _request, uint256 _remaining) internal virtual returns (uint256);
}
