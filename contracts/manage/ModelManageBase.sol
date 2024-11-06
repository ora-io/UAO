// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error InvalidModelID(); // error sig: 3c6e1db8
error ModelIDAlreadyExist();

contract ModelManageBase {
    mapping(uint256 => bool) public modelExists;
    uint256[] public modelIDs;

    // *********** Modifiers ***********

    modifier onlyModelExists(uint256 _modelId) {
        if (!modelExists[_modelId]) revert InvalidModelID();
        _;
    }

    modifier onlyModelNotExists(uint256 _modelId) {
        if (modelExists[_modelId]) revert ModelIDAlreadyExist();
        _;
    }

    // *********** Externals ***********

    function numberOfModels() external view returns (uint256) {
        return modelIDs.length;
    }

    // *********** Internals ***********

    function _totalModelNumber() internal view returns (uint256) {
        return modelIDs.length;
    }

    function _addModel(uint256 _modelId) internal onlyModelNotExists(_modelId) {
        modelExists[_modelId] = true;
        modelIDs.push(_modelId);
    }

    function _removeModel(uint256 _modelId) internal onlyModelExists(_modelId) {
        // set to non-exist
        modelExists[_modelId] = false;
        // remove from modelIDs
        for (uint256 i = 0; i < modelIDs.length; i++) {
            if (modelIDs[i] == _modelId) {
                // Replace the element at index with the last element
                modelIDs[i] = modelIDs[modelIDs.length - 1];
                // Remove the last element by reducing the array's length
                modelIDs.pop();
                break;
            }
        }
    }

    function _removeAllModels() internal {
        for (uint256 i = 0; i < modelIDs.length; i++) {
            modelExists[modelIDs[i]] = false;
        }
        delete modelIDs;
    }
}
