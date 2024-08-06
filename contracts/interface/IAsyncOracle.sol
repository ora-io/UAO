// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum DA {
    Calldata,
    Blob,
    IPFS
}

struct Request {
    address requester;
    uint256 requestId;
    uint256 modelId;
    bytes input;
    address callbackAddr;
    uint64 gasLimit;
    bytes callbackData;
    // bool isInvoked;
    DA inputDA;
    DA outputDA;
}
//TODO: re-order to gas cost opt

interface IAsyncOracle {
    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData,
        DA inputDA,
        DA outputDA
    ) external payable returns (uint256);
    // function await(uint256 AID) external;
    function invoke(uint256 requestId, bytes memory result) external;
    function update(uint256 requestId, bytes memory result) external;

    event AsyncRequest(
        address indexed requester,
        uint256 indexed requestId,
        uint256 indexed modelId,
        bytes input,
        address callbackAddr,
        uint64 gasLimit,
        bytes callbackData,
        DA inputDA,
        DA outputDA
    ); //TODO param

    event AsyncResponse(
        address indexed responder, uint256 indexed requestId, uint256 indexed modelId, bytes output, DA outputDA
    );
}
