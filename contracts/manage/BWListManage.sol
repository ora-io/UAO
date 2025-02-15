// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

error NotInWhitelist();
error IsInBlocklist();

contract BWListManage {
    // avoid calling special callback contracts
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;

    modifier onlyWhitelist(address _address) {
        if (!whitelist[_address]) revert NotInWhitelist();
        _;
    }

    modifier onlyNotBlacklist(address _address) {
        if (blacklist[_address]) revert IsInBlocklist();
        _;
    }

    function _addToWhitelist(address _address) internal {
        whitelist[_address] = true;
    }

    function _delFromWhitelist(address _address) internal {
        whitelist[_address] = false;
    }

    function _addToBlacklist(address _address) internal {
        blacklist[_address] = true;
    }

    function _delFromBlacklist(address _address) internal {
        blacklist[_address] = false;
    }
}
