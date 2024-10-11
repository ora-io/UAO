// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "../FeeUtils.sol";

/**
 * Node Fee Structure:
 *   - all NodeFee revenue = _totalNodeRevenue + _totalRequestNodeFeeCache
 *   - RequestNodeFeeCache: cache the fee when a request is initiated, waiting for a node to collect;
 *   - NodeRevenue: node revenue, when node fulfill a request, the RequestNodeFeeCache[requestId] amount move from cache to NodeRevenue[node];
 */
abstract contract NodeFeeUpgradeable is FeeUtils, Initializable {
    address internal _nodeFeeToken;
    uint256 internal _nodeFeeAmount;

    mapping(address => uint256) nodeRevenue;
    mapping(uint256 => uint256) requestNodeFeeCache;
    uint256 internal _totalNodeRevenue;
    uint256 internal _totalRequestNodeFeeCache;

    // constructor(address _feeToken, uint256 _feeAmount) {
    //     _setNodeFee(_feeToken, _feeAmount);
    // }

    // **************** Setup Functions  ****************
    function _initializeNodeFee(address _feeToken, uint256 _feeAmount) 
        internal 
        onlyInitializing
    {
       _setNodeFee(_feeToken, _feeAmount);
    }


    // ********** Overrides **********

    function _estimateFee(Request storage) internal view virtual override returns (uint256) {
        return _nodeFeeAmount;
    }

    function _estimateFeeMemory(Request memory) internal view virtual override returns (uint256) {
        return _nodeFeeAmount;
    }

    // use this when a request is received
    function _recordRevenue(Request storage _request, uint256 _remaining)
        internal
        virtual
        override
        returns (uint256 remaining)
    {
        if (_remaining < _nodeFeeAmount) revert InsufficientFee(FeeType.NodeFee);
        _addRequestNodeFeeCache(_request.requestId, _nodeFeeAmount);
        remaining = _remaining - _nodeFeeAmount;
    }

    // ********** Externals **********
    //   - exist because it's mandatory, and less possible to be merged with other fee

    function getMyNodeRevenue() external virtual returns (uint256) {
        return nodeRevenue[msg.sender];
    }

    function claimMyNodeRevenue() external virtual {
        _claimNodeRevenue(msg.sender);
    }

    function getNodeRevenue(address node) external virtual returns (uint256) {
        return nodeRevenue[node];
    }

    function claimNodeRevenue(address node) external virtual {
        _claimNodeRevenue(node);
    }

    // ********** Internals - Node Fee **********

    function _getNodeFeeToken() internal view returns (address) {
        return _nodeFeeToken;
    }

    function _getNodeFeeAmount() internal view returns (uint256) {
        return _nodeFeeAmount;
    }

    function _setNodeFee(address _feeToken, uint256 _feeAmount) internal {
        _nodeFeeToken = _feeToken;
        _nodeFeeAmount = _feeAmount;
    }

    // ********** Internals - Node Revenue **********

    function _getNodeRevenue(address _user) internal view returns (uint256) {
        return nodeRevenue[_user];
    }

    function _addNodeRevenue(address _user, uint256 _amount) internal {
        _totalNodeRevenue += _amount;
        nodeRevenue[_user] += _amount;
    }

    // use this when node fulfilled a _request
    function _addNodeRevenueFromRequest(address _user, uint256 _requestId) internal {
        uint256 amount = requestNodeFeeCache[_requestId];
        _resetRequestNodeFeeCache(_requestId);
        _addNodeRevenue(_user, amount);
    }

    function _resetNodeRevenue(address _user) internal {
        _totalNodeRevenue -= nodeRevenue[_user];
        nodeRevenue[_user] = 0;
    }

    function _claimNodeRevenue(address _node) internal {
        uint256 amount = nodeRevenue[_node];
        _resetNodeRevenue(_node);
        _tokenTransferOut(_nodeFeeToken, _node, amount);
    }

    // ********** Internals - RequestNodeFeeCache **********

    function _getRequestNodeFeeCache(uint256 _requestId) internal view returns (uint256) {
        return requestNodeFeeCache[_requestId];
    }

    function _addRequestNodeFeeCache(uint256 _requestId, uint256 _amount) internal {
        _totalRequestNodeFeeCache += _amount;
        requestNodeFeeCache[_requestId] += _amount;
    }

    function _resetRequestNodeFeeCache(uint256 _requestId) internal {
        _totalRequestNodeFeeCache -= requestNodeFeeCache[_requestId];
        requestNodeFeeCache[_requestId] = 0;
    }
}
