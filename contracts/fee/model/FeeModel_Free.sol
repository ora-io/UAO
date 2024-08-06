// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interface/IFeeModel.sol";

abstract contract FeeModel_Free is IFeeModel {
    constructor() {}

    // ********** Externals - Permissionless **********

    function estimateFee(uint256, bytes calldata, address, uint64, bytes calldata, DA, DA)
        external
        pure
        virtual
        override
        returns (uint256)
    {
        return 0;
    }
}
