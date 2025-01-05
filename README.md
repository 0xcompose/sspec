# sspec

sspec comes from `Solidity SPECification`. Often smart contract repos lack detailed of even general description of what repo and smart contracts in it are doing. Only AIs can understand what's going (not always). So for sake of development and review simplicity this tool was created.

This is a re-imagined of [`scopelint`'s](https://github.com/ScopeLift/scopelint) `spec` command, which generated specification for source smart contracts based on test files and test names.

Such functionality helps not only understanding your own suites of tests, but also review other's repos.

Built using [slang](https://github.com/NomicFoundation/slang).

## Foundry Test Naming According to `sspec`

There are three valid naming conventions for unit testing (according to foundry best practice):
1. `SourceContractName.t.sol`, where test contract is named `SourceContractNameTest`
2. `SourceContractName.sourceFunctionName.t.sol`, where test contract is named `SourceFunctionName` with pascal case
3. `SourceContractName.FeatureName.t.sol`, where test contract is named `FeatureName`. It is not required to be actual feature, feature can be anything, including integration tests