// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IFeeModel {
    function estimateFee(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external view returns (uint256);
}
