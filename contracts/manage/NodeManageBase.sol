// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

error NotNode();
error NodeAlreadyExists();

contract NodeManageBase {
    mapping(address => bool) public isNode;
    address[] public nodeList;
    // TODO: complete nodeManagers, only nodeManagers address can operate add/remove nodes
    mapping(address => bool) public isManager;
    address[] public nodeManagers;

    // *********** Modifiers ***********

    modifier onlyNode(address _addr) {
        if (!isNode[_addr]) revert NotNode();
        _;
    }

    modifier onlyNotNode(address _addr) {
        if (isNode[_addr]) revert NodeAlreadyExists();
        _;
    }

    // *********** Externals ***********

    function numberOfNodes() external view returns (uint256) {
        return nodeList.length;
    }

    // *********** Internals ***********

    function _addNode(address _addr) internal onlyNotNode(_addr) {
        isNode[_addr] = true;
        nodeList.push(_addr);
    }

    function _removeNode(address _addr) internal onlyNode(_addr) {
        // set to non-exist
        isNode[_addr] = false;
        // remove from nodeList
        for (uint256 i = 0; i < nodeList.length; i++) {
            if (nodeList[i] == _addr) {
                // Replace the element at index with the last element
                nodeList[i] = nodeList[nodeList.length - 1];
                // Remove the last element by reducing the array's length
                nodeList.pop();
                break;
            }
        }
    }

    function _removeAllNodes() internal {
        for (uint256 i = 0; i < nodeList.length; i++) {
            isNode[nodeList[i]] = false;
        }
        delete nodeList;
    }
}
