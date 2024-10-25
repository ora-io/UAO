// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BabyAsyncOracle} from "../contracts/mock/babyasync/BabyAsyncOracle.sol";

contract AsyncOracleTest is Test {
    BabyAsyncOracle public bao;

    function setUp() public {
        bao = new BabyAsyncOracle();
    }

    function test_estimateFee() public view {
        uint256 modelId = 0;
        bytes memory input = new bytes(1);
        input[0] = 0xab;
        address callbackAddr = address(0);
        uint64 gasLimit = 0;
        bytes memory callbackData = new bytes(1);
        callbackData[0] = 0xab;

        bao.estimateFee(modelId, input, callbackAddr, gasLimit, callbackData);
    }
}
