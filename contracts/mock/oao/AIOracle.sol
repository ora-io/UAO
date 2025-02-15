// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "@ora-io/uao/AsyncOracle.sol";
import "@ora-io/uao/fee/model/FeeModel_PNMC_Ownerable.sol";
import "@ora-io/uao/manage/ModelManageBase.sol";
import "@ora-io/uao/manage/NodeManageBase.sol";
import "@ora-io/uao/manage/BWListManage.sol";
import "@ora-io/uao/interfaces/IOpml.sol";

// aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData)
bytes4 constant callbackFunctionSelector = 0xb0347814;

struct ModelData {
    bytes32 modelHash;
    bytes32 programHash;
}

contract AIOracle is
    ModelManageBase,
    NodeManageBase,
    BWListManage,
    AsyncOracle,
    FeeModel_PNMC_Ownerable
{
    mapping(uint256 => ModelData) public modelDataMap;
    IOpml public opml;

    // **************** Setup Functions  ****************

    function initializeAIOracle(address feeToken, uint256 protocolFee, uint256 nodeFee, address financialOperator)
        external
        initializer
    {
        _initializeAsyncOracle(callbackFunctionSelector);
        _initializeFeeModel_PNMC_Ownerable(msg.sender, feeToken, protocolFee, nodeFee, financialOperator);
    }

    // ********** Core Logic **********

    /**
     * override
     */
    function async(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) public payable override returns (uint256) {
        // init opml request
        ModelData memory model = modelDataMap[modelId];
        uint256 requestId = opml.initOpmlRequest(model.modelHash, model.programHash, input);

        // record & emit async request
        Request storage request = _async(requestId, modelId, input, callbackAddr, gasLimit, callbackData);
        // bytes4 defaultFSig = MID2FuncSig[modelId];

        // validate params
        _validateParams(request);

        // receive & record fee, use eth only for now
        _receiveAndRecordRevenue(request, msg.value);

        return requestId;
    }

    // view function
    function _validateParams(Request storage request)
        internal
        view
        onlyModelExists(request.modelId)
        onlyNotBlacklist(request.callbackAddr)
    {
        // validate fee
        require(msg.value >= _estimateFee(request), "insufficient fee");
        // validate input
        require(request.input.length > 0, "input not uploaded");
        // validate call back
        bool noCallback = request.callbackAddr == address(0);
        require(noCallback == (request.gasLimit == 0), "Invalid gasLimit");
    }

    //onlyWhitelist(msg.sender)
    function invoke(uint256 requestId, bytes calldata output, bytes calldata) external override onlyNode(msg.sender) {
        // others can challenge if the result is incorrect!
        opml.uploadResult(requestId, output);

        // invoke callback
        _invoke(requestId, output);
        _updateGasPrice();
    }

    // call this function if the opml result is challenged and updated!
    // anyone can call it!
    function update(uint256 requestId) external {
        // get Latest output of request
        bytes memory output = opml.getOutput(requestId);
        require(output.length > 0, "output not uploaded");

        // invoke callback
        _invoke(requestId, output);
        _updateGasPrice();
    }

    function isFinalized(uint256 requestId) external view returns (bool) {
        return opml.isFinalized(requestId);
    }

    function getOutput(uint256 requestId) external view returns (bytes memory output) {
        return opml.getOutput(requestId);
    }

    // ********** Model Operations **********

    function getModel(uint256 modelId) external view onlyModelExists(modelId) returns (ModelData memory) {
        ModelData memory model = modelDataMap[modelId];
        return model;
    }

    function uploadModel(
        uint256 modelId,
        bytes32 modelHash,
        bytes32 programHash,
        uint256 fee,
        address receiver,
        uint256 receiverPercentage
    ) external onlyOwner onlyModelNotExists(modelId) {
        _addModel(modelId);
        _setModelFeeData(modelId, fee, receiver, receiverPercentage);
        ModelData storage model = modelDataMap[modelId];
        model.modelHash = modelHash;
        model.programHash = programHash;
        opml.uploadModel(modelHash, programHash);
    }

    function updateModel(
        uint256 modelId,
        bytes32 modelHash,
        bytes32 programHash,
        uint256 fee,
        address receiver,
        uint256 receiverPercentage
    ) external onlyOwner onlyModelExists(modelId) {
        _setModelFeeData(modelId, fee, receiver, receiverPercentage);
        ModelData storage model = modelDataMap[modelId];
        model.modelHash = modelHash;
        model.programHash = programHash;
        opml.uploadModel(modelHash, programHash);
    }

    // remove the model from OAO, so OAO would not serve the model
    function removeModel(uint256 modelId) external onlyOwner onlyModelExists(modelId) {
        // claim the corresponding revenue first
        _claimModelReceiverRevenue(modelId);
        // remove from ModelManageBase
        _removeModel(modelId);
    }

    // ********** Whilte/Block List **********

    function addToWhitelist(address _address) external onlyOwner {
        _addToWhitelist(_address);
    }

    function delFromWhitelist(address _address) external onlyOwner {
        _delFromWhitelist(_address);
    }

    function addToBlacklist(address _address) external onlyOwner {
        _addToBlacklist(_address);
    }

    function delFromBlacklist(address _address) external onlyOwner {
        _delFromBlacklist(_address);
    }

    // ********** Backword Compatible **********
    event AICallbackResult(address indexed account, uint256 indexed requestId, address invoker, bytes output);

    function withdraw() external onlyOwner {
        claimProtocolRevenue();
    }

    function requestCallback(
        uint256 modelId,
        bytes calldata input,
        address callbackAddr,
        uint64 gasLimit,
        bytes calldata callbackData
    ) external payable returns (uint256) {
        return async(modelId, input, callbackAddr, gasLimit, callbackData);
    }

    function invokeCallback(uint256 requestId, bytes calldata output) external onlyWhitelist(msg.sender) {
        // others can challenge if the result is incorrect!
        opml.uploadResult(requestId, output);

        // invoke callback
        _invoke(requestId, output);
        _updateGasPrice();

        emit AICallbackResult(requests[requestId].requester, requestId, msg.sender, output);
    }

    function setModelFee(uint256 modelId, uint256 fee) external onlyOwner {
        _setModelFee(modelId, fee);
    }

    function setModelReceiver(uint256 modelId, address receiver) external onlyOwner {
        _setModelReceiver(modelId, receiver);
    }

    function setModelReceiverPercentage(uint256 modelId, uint256 receiverPercentage) external onlyOwner {
        _setModelReceiverPercentage(modelId, receiverPercentage);
    }

    // set the gasPrice = 0 initially
    function resetGasPrice() external onlyOwner {
        gasPrice = 0;
    }
}