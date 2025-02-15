// SPDX-License-Identifier: MIT 
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

error NotFinancialOperator();

abstract contract FinancialOperator is OwnableUpgradeable {

    address internal _financialOperator;

    // **************** Modifiers  ****************

    modifier onlyFinancialOperator() {
        if (_financialOperator != msg.sender) revert NotFinancialOperator();
        _;
    }
    
    // **************** Getter & Setter  ****************

    function _getFinancialOperator() internal view returns (address) {
        return _financialOperator;
    } 

    function _setFinancialOperator(address _operator) internal {
        _financialOperator = _operator;
    }

    function getFinancialOperator() external virtual returns (address){
        return _getFinancialOperator();
    }

    function setFinancialOperator(address _operator) external virtual onlyOwner {
        _setFinancialOperator(_operator);
    }
}