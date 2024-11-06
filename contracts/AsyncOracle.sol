// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";

import "./interfaces/IAsyncOracle.sol";

abstract contract AsyncOracle is IAsyncOracle, Initializable {
    bytes4 public callbackFunctionSelector;

    uint256 _lastRequestId; // replacable by child contracts.

    mapping(uint256 => Request) public requests;

    // **************** Setup Functions  ****************

    function _initializeAsyncOracle(bytes4 _callbackFunctionSelector)  
        internal
        onlyInitializing
    {
        callbackFunctionSelector = _callbackFunctionSelector;
    }

    // *********** Overrides & Externals ***********

    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external payable virtual returns (uint256 requestId) {
        requestId = _nextRequestID();
        _async(requestId, modelId, input, callbackAddr, gasLimit, callbackData);
    }

    function invoke(uint256 requestId, bytes calldata output, bytes calldata) external virtual {
        _invoke(requestId, output);
    }

    // *********** Internals ***********

    function _async(
        uint256 requestId,
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) internal virtual returns (Request storage req) {
        req = _newRequestCalldataToStorage(msg.sender, requestId, modelId, input, callbackAddr, gasLimit, callbackData);

        // Emit event
        emit AsyncRequest(req.requester, requestId, modelId, input, callbackAddr, gasLimit, callbackData);
    }

    function _asyncMemory(
        uint256 requestId,
        uint256 modelId,
        bytes memory input,
        address callbackAddr,
        uint64 gasLimit,
        bytes memory callbackData
    ) internal virtual returns (Request storage req) {
        req = _newRequestMemoryToStorage(msg.sender, requestId, modelId, input, callbackAddr, gasLimit, callbackData);

        // Emit event
        emit AsyncRequest(req.requester, requestId, modelId, input, callbackAddr, gasLimit, callbackData);
    }

    function _invoke(uint256 requestId, bytes memory output) internal {
        // locate request data of AsyncID
        Request storage request = requests[requestId];

        // invoke callback
        if (request.callbackAddr != address(0)) {
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

        emit AsyncResponse(msg.sender, requestId, request.modelId, output);
    }

    function _invokeUint256(uint256 requestId, bytes memory output) internal {
        // locate request data of AsyncID
        Request storage request = requests[requestId];

        // invoke callback
        if (request.callbackAddr != address(0)) {
            uint256 outputUint256 = abi.decode(output, (uint256)); // convert bytes to uint256, for callback only
            bytes memory payload =
                abi.encodeWithSelector(callbackFunctionSelector, requestId, outputUint256, request.callbackData);
            (bool success, bytes memory data) = request.callbackAddr.call{gas: request.gasLimit}(payload);
            require(success, "callback fail");
            if (!success) {
                assembly {
                    revert(add(data, 32), mload(data))
                }
            }
        }

        emit AsyncResponse(msg.sender, requestId, request.modelId, output);
    }

    // *********** Internals - Request ***********

    function _nextRequestID() internal returns (uint256) {
        return _lastRequestId++;
    }

    function _peekNextRequestID() internal view returns (uint256) {
        return _lastRequestId + 1;
    }

    function _newRequestCalldataToStorage(
        address requester,
        uint256 requestId,
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) internal returns (Request storage req) {
        req = requests[requestId];

        req.requester = requester;
        req.requestId = requestId;
        req.modelId = modelId;
        req.input = input;
        req.callbackAddr = callbackAddr;
        req.gasLimit = gasLimit;
        req.callbackData = callbackData;
    }

    function _newRequestCalldataToMemory(
        address requester,
        uint256 requestId,
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) internal pure returns (Request memory req) {
        req.requester = requester;
        req.requestId = requestId;
        req.modelId = modelId;
        req.input = input;
        req.callbackAddr = callbackAddr;
        req.gasLimit = gasLimit;
        req.callbackData = callbackData;
    }

    function _newRequestMemoryToStorage(
        address requester,
        uint256 requestId,
        uint256 modelId,
        bytes memory input,
        address callbackAddr,
        uint64 gasLimit,
        bytes memory callbackData
    ) internal returns (Request storage req) {
        req = requests[requestId];

        req.requester = requester;
        req.requestId = requestId;
        req.modelId = modelId;
        req.input = input;
        req.callbackAddr = callbackAddr;
        req.gasLimit = gasLimit;
        req.callbackData = callbackData;
    }

    function _newRequestMemoryToMemory(
        address requester,
        uint256 requestId,
        uint256 modelId,
        bytes memory input,
        address callbackAddr,
        uint64 gasLimit,
        bytes memory callbackData
    ) internal view returns (Request memory req) {
        req = requests[requestId];

        req.requester = requester;
        req.requestId = requestId;
        req.modelId = modelId;
        req.input = input;
        req.callbackAddr = callbackAddr;
        req.gasLimit = gasLimit;
        req.callbackData = callbackData;
    }
}
