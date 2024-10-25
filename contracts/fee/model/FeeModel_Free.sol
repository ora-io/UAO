// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interface/IFeeModel.sol";

abstract contract FeeModel_Free is IFeeModel, Initializable {
    // **************** Setup Functions  ****************
    function initialize() external initializer {}

    // ********** Externals - Permissionless **********

    function estimateFee(uint256, bytes calldata, address, uint64, bytes calldata)
        external
        pure
        virtual
        override
        returns (uint256)
    {
        return 0;
    }
}
