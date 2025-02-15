// SPDX-License-Identifier: MIT 
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

error NotInvokeOperator();

abstract contract InvokeOperator is OwnableUpgradeable {

    address internal _invokeOperator;

    // **************** Modifiers  ****************

    modifier onlyInvokeOperator() {
        if (_invokeOperator != msg.sender) revert NotInvokeOperator();
        _;
    }
    
    // **************** Getter & Setter  ****************

    function _getInvokeOperator() internal view returns (address) {
        return _invokeOperator;
    } 

    function _setInvokeOperator(address _operator) internal {
        _invokeOperator = _operator;
    }

    function getInvokeOperator() external virtual returns (address){
        return _getInvokeOperator();
    }

    function setInvokeOperator(address _operator) external virtual onlyOwner {
        _setInvokeOperator(_operator);
    }
}