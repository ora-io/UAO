// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interface/IAsyncOracle.sol";

abstract contract AsyncOracle is IAsyncOracle {
    bytes4 public callbackFunctionSelector;

    uint256 _lastRequestId; // replacable by child contracts.

    mapping(uint256 => Request) public requests;

    constructor(bytes4 _callbackFunctionSelector) {
        callbackFunctionSelector = _callbackFunctionSelector;
    }

    // function await(uint256 AID) external view {
    //     require(requests[AID].isInvoked);
    // }

    // function encodeAID(uint176 modelId, uint80 requestId) public pure returns (uint256) {
    //     return modelId << 80 + requestId;
    // }

    // function decodeAID(uint256 aid) public pure returns (uint176 modelId, uint80 requestId) {
    //     modelId = aid >> 80;
    //     requestId = aid && (1 << 80 - 1);
    // }

    // *********** Overrides & Externals ***********

    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) external payable virtual returns (uint256 requestId) {
        requestId = _nextRequestID();
        _async(requestId, modelId, input, callbackAddr, gasLimit, callbackData, inputDA, outputDA);
    }

    function invoke(uint256 requestId, bytes memory output) external virtual {
        _invoke(requestId, output);
        // _updateGasPrice();
    }

    function update(uint256 requestId, bytes memory result) external {
        //TODO
    }

    // *********** Internals ***********

    function _async(
        uint256 requestId,
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) internal virtual returns (Request storage req) {
        req =
            _newRequest(msg.sender, requestId, modelId, input, callbackAddr, gasLimit, callbackData, inputDA, outputDA);

        // Emit event
        emit AsyncRequest(
            req.requester, requestId, modelId, input, callbackAddr, gasLimit, callbackData, inputDA, outputDA
        );
    }

    function _invoke(uint256 requestId, bytes memory output) internal {
        // locate request data of AsyncID
        Request storage request = requests[requestId];

        // invoke callback
        if (request.callbackAddr != address(0)) {
            // bytes4 cbFuncSelector =
            //     request.callbackFuncSelector == bytes4(0) ? callbackFunctionSelector : request.callbackFuncSelector;
            bytes memory payload =
                abi.encodeWithSelector(callbackFunctionSelector, requestId, output, request.callbackData);
            (bool success, bytes memory data) = request.callbackAddr.call{gas: request.gasLimit}(payload);
            require(success, "callback fail");
            if (!success) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
        }

        emit AsyncResponse(msg.sender, requestId, request.modelId, output, request.outputDA);
    }

    // *********** Internals - Request ***********

    function _nextRequestID() internal returns (uint256) {
        return _lastRequestId++;
    }

    function _peekNextRequestID() internal view returns (uint256) {
        return _lastRequestId + 1;
    }

    function _newRequest(
        address requester,
        uint256 requestId,
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) internal returns (Request storage req) {
        // uint256 AID = encodeAID(modelId, requestId);
        // Request storage req = requests[AID];
        req = requests[requestId];

        req.requester = requester;
        req.requestId = requestId;
        req.modelId = modelId;
        req.input = input;
        req.callbackAddr = callbackAddr;
        req.gasLimit = gasLimit;
        req.callbackData = callbackData;
        req.inputDA = inputDA;
        req.outputDA = outputDA;
        // req.isInvoked = false;
    }

    function _newRequestMemory(
        address requester,
        uint256 requestId,
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) internal pure returns (Request memory req) {
        req.requester = requester;
        req.requestId = requestId;
        req.modelId = modelId;
        req.input = input;
        req.callbackAddr = callbackAddr;
        req.gasLimit = gasLimit;
        req.callbackData = callbackData;
        req.inputDA = inputDA;
        req.outputDA = outputDA;
        // req.isInvoked = false;
    }

    // set the gasPrice = 0 initially ?
    //TODO: need this?
    // function resetGasPrice() external onlyOwner {
    //     gasPrice = 0;
    // }

    //TODO: module oracle fee
    //TODO: nodes (external contract to control)
    //TODO: add verifiers
    //TODO: gas on this level, "model" on child level
}
