// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/PausableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./AsyncOracleUpgradeable.sol";
import {IFraudAsync} from "./interface/IAsyncOracle.sol";

abstract contract AsyncOracleFraudUpgradeable is AsyncOracleUpgradeable, IFraudAsync {
    // constructor(bytes4 _callbackFunctionSelector) AsyncOracle(_callbackFunctionSelector) {}
    
    // **************** Setup Functions  ****************
    function initializeAsyncOracleFraud(bytes4 _callbackFunctionSelector) 
        external
        initializer
    {
       initialize(_callbackFunctionSelector);
    }

    function invoke(uint256 requestId, bytes memory output) external virtual {
        _invoke(requestId, output);
        // _updateGasPrice();
    }

    // function update(uint256 requestId) external virtual {
    //     // bytes output = getUpdatedOutput()
    //     _invoke(requestId, output);
    // }
}
