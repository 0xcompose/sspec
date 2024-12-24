// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../_.Vault.Setup.sol";
import {Strategy} from "maat-strategies/contracts/Strategy.sol";

import {IWithdrawRequestLogic} from "../../../src/interfaces/IExecutor.sol";

contract MaatVaultToggleStrategyTest is MaatVaultTestSetup {
    Strategy strategyUSDC;

    address public yearnVaultAddr = 0x6FAF8b7fFeE3306EfcFc2BA9Fec912b4d49834C1;
    address public USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function _afterSetUp() internal override {
        maatVault.removeStrategy(strategyId);

        MaatVaultV1 usdcVault = new MaatVaultV1(
            address(this),
            USDC,
            100,
            address(addressProvider),
            commander,
            watcher,
            1
        );

        IStrategyFromStrategies.StrategyParams memory strategyParams =
        IStrategyFromStrategies.StrategyParams(
            chainId, "YEARN", 3, USDC, yearnUSDTVault
        );

        strategyUSDC = Strategy(
            address(
                new YearnV3Strategy(
                    strategyParams, address(usdcVault), feeTo, performanceFee
                )
            )
        );
    }

    function test_toggleStrategy() public {
        maatVault.addStrategy(address(strategy));

        (address strategyAddress, bool isActive) =
            maatVault.getStrategyById(strategyId);

        assertTrue(isActive);
        assertEq(strategyAddress, address(strategy));

        maatVault.disableStrategy(strategyId);

        (strategyAddress, isActive) = maatVault.getStrategyById(strategyId);

        assertFalse(isActive);
        assertEq(strategyAddress, address(strategy));

        maatVault.enableStrategy(strategyId);

        (strategyAddress, isActive) = maatVault.getStrategyById(strategyId);

        assertTrue(isActive);
        assertEq(strategyAddress, address(strategy));
    }

    function test_enableStrategyFail() public {
        vm.expectRevert("MaatVaultV1: Nonexistent strategy");
        maatVault.enableStrategy(strategyId);
    }

    function test_disableStrategyFail() public {
        vm.expectRevert("MaatVaultV1: Nonexistent strategy");
        maatVault.disableStrategy(strategyId);
    }
}
