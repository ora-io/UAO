// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AIOracle} from "../contracts/mock/oao/AIOracle.sol";
import {ETH_IDENTIFIER} from "../contracts/utils/TokenAdapter.sol";
import {Test, console} from "forge-std/Test.sol";

contract FeeModelTest is Test {
    AIOracle public oao;
    uint256 protocolFee = 1;
    uint256 nodeFee = 10;

    function setUp() public {
        oao = new AIOracle();
        AIOracle(address(oao)).initializeAIOracle(ETH_IDENTIFIER, protocolFee, nodeFee);
    }

    function test_estimateFee() public view {
        uint256 modelId = 0;
        bytes memory input = new bytes(1);
        input[0] = 0xab;
        address callbackAddr = address(0);
        uint64 gasLimit = 0;
        bytes memory callbackData = new bytes(1);
        callbackData[0] = 0xab;
        assertEq(oao.estimateFee(modelId, input, callbackAddr, gasLimit, callbackData), protocolFee + nodeFee);
    }
}
