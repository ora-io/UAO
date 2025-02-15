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

In solidity:

`BabyOracle.sol`
```solidity
// // SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "@ora-io/uao/AsyncOracle.sol";
import "@ora-io/uao/fee/model/FeeModel_Free.sol";

bytes4 constant callbackFunctionSelector = 0x3f92108c;

contract BabyOracle is AsyncOracle, FeeModel_Free {
    function initializeBabyOracle()  
        external
        initializer
    {
        _initializeAsyncOracle(callbackFunctionSelector);
    }
}
```

Then compile the contract, should succeed without errors.

```bash
$ forge build
```

## Examples
- check `src/mock`
- [UAO-based OAO](https://github.com/ora-io/OAO-UAO)

## Framework Structure
- `AsyncOracle.sol`: the main AsyncOracle contract
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
  - `FinancialOperator.sol`: the FinancialOperator manage contract, for owner-operator separation.
- `utils/`
  - `TokenAdapter.sol`: transfer in/out & balanceOf for any token;
- `mock/`
  - `baby/`: sample usage for fee models (no verifiability)
  - `verfiability/`: sample usage for verifiabilities (no fee model)
  - `oao/`: a more complicated example - AIOracle
