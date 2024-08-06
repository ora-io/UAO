// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BabyAsyncOracle} from "../contracts/mock/babyasync/BabyAsyncOracle.sol";
import {DA} from "../contracts/interface/IAsyncOracle.sol";
import {Test, console} from "forge-std/Test.sol";

contract AsyncOracleTest is Test {
    BabyAsyncOracle public bao;
    uint256 protocolFee = 1;
    uint256 nodeFee = 10;

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
        DA inputDA = DA.Calldata;
        DA outputDA = DA.Calldata;

        bao.estimateFee(modelId, input, callbackAddr, gasLimit, callbackData, inputDA, outputDA);
    }

    // function testFuzz_SetNumber(uint256 x) public {
    //     counter.setNumber(x);
    //     assertEq(counter.number(), x);
    // }
}
