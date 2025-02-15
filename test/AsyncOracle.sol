// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {BabyOracle} from "../contracts/mock/baby/BabyOracle.sol";

contract AsyncOracleTest is Test {
    BabyOracle public bao;

    function setUp() public {
        bao = new BabyOracle();
        BabyOracle(address(bao)).initializeBabyOracle();
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
