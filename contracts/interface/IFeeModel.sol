// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {DA} from "./IAsyncOracle.sol";

interface IFeeModel {
    function estimateFee(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) external view returns (uint256);
}
