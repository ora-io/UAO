# Universal AsyncOracle: the Async-style Oracle Contract Framework

## Usage

Init a forge project if haven't

```bash
$ mkdir new-project && cd new-project
$ forge init --force
```

Install and use

```bash
$ forge install ora-io/uao
# recommended for vscode syntax check by https://book.getfoundry.sh/config/vscode
$ forge remappings > remappings.txt
```

In solidity (Validity Proof style example):

`BabyAsyncOracle.sol`
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@ora-io/uao/AsyncOracleValidity.sol";
import "@ora-io/uao/fee/model/FeeModel_Free.sol";

// await(uint256 requestId, bytes calldata output, bytes calldata callbackData)
bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyAsyncOracle is AsyncOracleValidity, FeeModel_Free {
    constructor() AsyncOracleValidity(callbackFunctionSelector) {}
}
```

Then compile the contract, should succeed without errors.

```bash
$ forge build
```

## TODO
[x] Upgradable support
[] Complete nodeManagers
[] Ownership transfer support
[] Test case coverage

## Examples
- check `src/mock`
- [UAO-based OAO](https://github.com/ora-io/OAO-UAO)

## Framework Structure
- `AsyncOracle.sol`: the main AsyncOracle contract
- `AsyncOracleFraud.sol`: the main AsyncOracle contract with **Fraud Proof** style `invoke` and `update`
- `AsyncOracleValidity.sol`: the main AsyncOracle contract with **Validity Proof** style `invoke`
- `fee/`
  - `base/`
    - includes basic fee types, that can be flexibly combined to use
    - currently has 4 basic fee types: protocol fee, model fee, node fee, callback fee
    - should have minimum externals
  - `model/`
    - includes variant fee models that combines the basic fee types in different ways
    - currently has 3 fee models: 
      - Free, i.e. no fee
      - PMC_Ownerable, i.e. Protocol+Model+Callback+Ownerable
      - PNMC_Ownerable, i.e. Protocol+Model+Node+Callback+Ownerable
    - can have externals
- `manage/`
  - `BWListManage.sol`: Blacklist and Whitelist
  - `ModelManageBase.sol`: provide basic manage, doesn't care about access control (maybe can add `modelManagers` role similar to `nodeManagers`); also is used by ModelFee (maybe can separate in the future).
  - `NodeManageBase.sol`: only `nodeManagers` can manage node list
    - recommend usage: only owner can manage `nodeManagers` list, then nodeManagers manage node list
- `utils/`
  - `TokenAdapter.sol`: transfer in/out & balanceOf for any token;

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
