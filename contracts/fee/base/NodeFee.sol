// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../FeeUtils.sol";
import "../../manage/NodeManageBase.sol";

/**
 * Node Fee Structure:
 *   - all NodeFee revenue = _totalNodeRevenue + _totalRequestNodeFeeCache
 *   - RequestNodeFeeCache: cache the fee when a request is initiated, waiting for a node to collect;
 *   - NodeRevenue: node revenue, when node fulfill a request, the RequestNodeFeeCache[requestId] amount move from cache to NodeRevenue[node];
 */
abstract contract NodeFee is FeeUtils, NodeManageBase, OwnableUpgradeable {
    uint256 internal _nodeFeeAmount;

    mapping(address => uint256) nodeRevenue;
    mapping(uint256 => uint256) requestNodeFeeCache;
    uint256 internal _totalNodeRevenue;
    uint256 internal _totalRequestNodeFeeCache;

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

    // ********** Externals - Fee **********
    function getNodeFeeAmount() external virtual returns (uint256) {
        return _getNodeFeeAmount();
    }
    function setNodeFeeAmount(uint256 _feeAmount) external virtual onlyOwner {
        _setNodeFeeAmount(_feeAmount);
    }

    // ********** Externals - Revenue **********
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

    // *********** Externals - Add/Remove Node ***********

    function addNode(address node) external onlyOwner onlyNotNode(node) {
        _addNode(node);
    }

    // remove the model from OAO, so OAO would not serve the model
    function removeNode(address node) external onlyOwner onlyNotNode(node) {
        // claim the corresponding revenue first
        _claimNodeRevenue(node);
        // remove from NodeManageBase
        _removeNode(node);
    }

    // ********** Internals - Fee **********

    function _getNodeFeeAmount() internal view returns (uint256) {
        return _nodeFeeAmount;
    }

    function _setNodeFeeAmount(uint256 _feeAmount) internal {
        _nodeFeeAmount = _feeAmount;
    }

    // ********** Internals - Revenue **********

    function _getNodeRevenue(address _node) internal view returns (uint256) {
        return nodeRevenue[_node];
    }

    function _addNodeRevenue(address _node, uint256 _amount) internal {
        _totalNodeRevenue += _amount;
        nodeRevenue[_node] += _amount;
    }

    // use this when node fulfilled a _request
    function _addNodeRevenueFromRequest(address _node, uint256 _requestId) internal {
        uint256 amount = requestNodeFeeCache[_requestId];
        _resetRequestNodeFeeCache(_requestId);
        _addNodeRevenue(_node, amount);
    }

    function _resetNodeRevenue(address _node) internal {
        _totalNodeRevenue -= nodeRevenue[_node];
        nodeRevenue[_node] = 0;
    }

    function _claimNodeRevenue(address _node) internal {
        uint256 amount = nodeRevenue[_node];
        _resetNodeRevenue(_node);
        _tokenTransferOut(feeToken, _node, amount);
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
