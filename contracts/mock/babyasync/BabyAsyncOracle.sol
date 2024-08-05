// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../AsyncOracle.sol";

// await(uint256 requestId, bytes calldata output, bytes calldata callbackData)
bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyAsyncOracle is AsyncOracle {
    constructor() AsyncOracle(callbackFunctionSelector) {}
}
