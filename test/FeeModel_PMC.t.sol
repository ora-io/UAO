// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BabyOraclePMC} from "../contracts/mock/baby/BabyOraclePMC.sol";
import {ETH_IDENTIFIER} from "../contracts/utils/TokenAdapter.sol";
import {Test, console} from "forge-std/Test.sol";

contract FeeModelPMCTest is Test {
    BabyOraclePMC public bo;
    uint256 protocolFee = 1;
    address owner = address(this);
    address financialOperator = address(0x456);
    address invokeOperator = address(0x789);

    function setUp() public {
        bo = new BabyOraclePMC();
        BabyOraclePMC(address(bo)).initialize(owner, financialOperator, invokeOperator, ETH_IDENTIFIER, protocolFee);
    }

    function test_estimateFee() public view {
        uint256 modelId = 0;
        bytes memory input = new bytes(1);
        input[0] = 0xab;
        address callbackAddr = address(0);
        uint64 gasLimit = 0;
        bytes memory callbackData = new bytes(1);
        callbackData[0] = 0xab;
        assertEq(bo.estimateFee(modelId, input, callbackAddr, gasLimit, callbackData), protocolFee);
    }

    function test_feeToken() public {
        address feeToken = address(0);
        bo.setFeeToken(feeToken);
        assertEq(bo.getFeeToken(), feeToken);
    }

    function test_financialOperator() public {
        // Make an async call to ensure fee > 0 for succ claim later
        bo.addModel(0, 0, owner, 0);
        bo.async{value: 1 ether}(0, new bytes(1), address(0), 0, new bytes(1));

        // Ensure the receiver is set correctly
        assertEq(bo.getFinancialOperator(), financialOperator);
        
        // Change operator
        address newOperator = address(0xaaa);
        bo.setFinancialOperator(newOperator);
        
        // Simulate unauthorized receiver trying to claim revenue
        vm.expectRevert();
        bo.claimProtocolRevenue(); // Expect revert
        
        // Simulate claim revenue
        vm.prank(newOperator);
        bo.claimProtocolRevenue(); // Expect succ
    }

    function test_protocolFee() public {
        uint256 newProtocolFee = 10;
        bo.setProtocolFeeAmount(newProtocolFee);
        assertEq(bo.getProtocolFeeAmount(), newProtocolFee);
    }
}
