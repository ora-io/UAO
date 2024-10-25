// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Request {
    address requester;
    uint256 requestId;
    uint256 modelId;
    bytes input;
    address callbackAddr;
    uint64 gasLimit;
    bytes callbackData;
}
//TODO: re-order to gas cost opt

interface IAsyncOracle {
    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external payable returns (uint256);

    event AsyncRequest(
        address indexed requester,
        uint256 indexed requestId,
        uint256 indexed modelId,
        bytes input,
        address callbackAddr,
        uint64 gasLimit,
        bytes callbackData
    );

    event AsyncResponse(address indexed responder, uint256 indexed requestId, uint256 indexed modelId, bytes output);
}

interface IFraudAsync {
    function invoke(uint256 requestId, bytes calldata output) external;
    function update(uint256 requestId) external;
}

interface IValidityAsync {
    function invoke(uint256 requestId, bytes calldata output, bytes calldata proof) external;
}
