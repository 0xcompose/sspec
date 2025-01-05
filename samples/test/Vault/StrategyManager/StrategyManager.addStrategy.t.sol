// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../_.Vault.Setup.sol";
import {Strategy} from "maat-strategies/contracts/Strategy.sol";

import {IWithdrawRequestLogic} from "../../../src/interfaces/IExecutor.sol";

contract AddStrategy is MaatVaultTestSetup {
    Strategy strategyUSDC;

    address public yearnVaultAddr = 0x6FAF8b7fFeE3306EfcFc2BA9Fec912b4d49834C1;
    address public USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function _afterSetUp() internal override {
        maatVault.removeStrategy(strategyId);

        MaatVaultV1 usdcVault =
            new MaatVaultV1(address(this), USDC, 100, address(addressProvider), commander, watcher, 1);

        IStrategyFromStrategies.StrategyParams memory strategyParams =
            IStrategyFromStrategies.StrategyParams(chainId, "YEARN", 3, USDC, yearnUSDTVault);

        strategyUSDC = Strategy(address(new YearnV3Strategy(strategyParams, address(usdcVault), feeTo, performanceFee)));
    }

    function test_getStrategyById_RevertsWhen_StrategyDoesNotExist() public {
        vm.expectRevert("MaatVaultV1: Nonexistent strategy");
        maatVault.getStrategyById(strategyId);
    }

    function test_AddsStrategy() public {
        maatVault.addStrategy(address(strategy));

        (address strategyAddress, bool isActive) = maatVault.getStrategyById(strategyId);

        assertTrue(isActive);
        assertEq(strategyAddress, address(strategy));
    }

    function test_AddsStrategyToArray() public {
        address[] memory strategies = maatVault.getStrategies();
        assertEq(strategies.length, 0, "Strategy wasn't removed at Vault Setup");

        maatVault.addStrategy(address(strategy));

        strategies = maatVault.getStrategies();
        assertEq(strategies.length, 1, "Strategy wasn't added to Vault");
        assertEq(strategies[0], address(strategy), "Added Strategy has incorrect address");
    }

    function testFuzz_RevertIf_StrategyIsNotRegisteredInProvider(address _strategy) public {
        vm.expectRevert("MaatVaultV1: Invalid strategy");
        maatVault.addStrategy(_strategy);
    }

    function test_RevertsWhen_StrategyWithDifferentAssetPassed() public {
        addressProvider.addStrategy(address(strategyUSDC));

        vm.expectRevert("MaatVaultV1: Cannot add strategy with different asset");
        maatVault.addStrategy(address(strategyUSDC));
    }

    function test_RevertsWhen_StrategyAlreadyAdded() public {
        maatVault.addStrategy(address(strategy));

        vm.expectRevert("MaatVaultV1: Strategy already exists");
        maatVault.addStrategy(address(strategy));
    }

    function test_EmitsEvent_StrategyAdded() public {
        bytes32 _strategyId = strategy.getStrategyId();

        vm.expectEmit(address(maatVault));
        emit IStrategyManager.StrategyAdded(_strategyId);
        maatVault.addStrategy(address(strategy));
    }
}
