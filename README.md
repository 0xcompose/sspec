# sspec

sspec comes from `Solidity SPECification`. Smart contract repositories often lack detailed or even general descriptions of what the repo and its smart contracts do. Only AIs can understand what's going on (not always). This tool was created to improve development and review simplicity.

This is a reimagining of [`scopelint`'s](https://github.com/ScopeLift/scopelint) `spec` command, which generates specifications for source smart contracts based on test files and test names.

This functionality helps not only with understanding your own test suites, but also with reviewing other repositories.

Built using [slang](https://github.com/NomicFoundation/slang).

## Installation

Install via npm or yarn:

```bash
npm i @0xcompose/sspec --save-dev
```

```bash
yarn add @0xcompose/sspec --dev
```

## Foundry Test Naming Conventions

There are three valid naming conventions for unit testing (according to Foundry best practices):

1. Testing whole contract:
   - Test file: `SourceContractName.t.sol`
   - Test contract: `SourceContractNameTest`

2. Testing single function:
   - Test file: `SourceContractName.sourceFunctionName.t.sol` 
   - Test contract: `SourceFunctionName` (in PascalCase)

3. Testing features:
   - Test file: `SourceContractName.FeatureName.t.sol`
   - Test contract: `FeatureName`
   - Note: Feature can be anything, including integration tests