# Universal AsyncOracle: the Async-style Oracle Contract Framework

## TODO
- Complete nodeManagers
- Upgradable support
- Ownership transfer support
- Test case coverage

## Usage

Init a forge project if haven't

```bash
$ mkdir new-project && cd new-project
$ forge init --force
```

Install and use

```bash
$ forge install ora-io/uao
$ forge remappings > remappings.txt
```

In solidity:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@ora-io/uao/AsyncOracle.sol";

// await(uint256 requestId, bytes calldata output, bytes calldata callbackData)
bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyAsyncOracle is AsyncOracle {
    constructor() AsyncOracle(callbackFunctionSelector) {}
}
```

Then compile the contract, should succeed without errors.

```bash
$ forge build
```

## Sample
- check `src/mock`

## Framework Structure
- `AsyncOracle.sol`: the main/basic AsyncOracle contract
- `fee/`
  - `feebase/`
    - includes basic fee types, that can be flexibly combined to use
    - currently has 4 basic fee types: protocol fee, model fee, node fee, callback fee
    - should have minimum externals
  - `feemodel/`
    - includes variant fee models that combines the basic fee types in different ways
    - currently has 1 fee model: PNMC_Ownerable, i.e. Protocol+Model+Node+Callback+Ownerable
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
