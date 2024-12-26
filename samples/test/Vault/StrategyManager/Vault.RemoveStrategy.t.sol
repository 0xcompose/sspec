// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../_.Vault.Setup.sol";
import {Strategy} from "maat-strategies/contracts/Strategy.sol";

import {IWithdrawRequestLogic} from "../../../src/interfaces/IExecutor.sol";

contract MaatVaultRemoveStrategyTest is MaatVaultTestSetup {
    function test_removeStrategy() public {
        maatVault.removeStrategy(strategyId);

        vm.expectRevert("MaatVaultV1: Nonexistent strategy");
        maatVault.getStrategyById(strategyId);
    }

    function test_removeStrategy_RemovesStrategyFromArray() public {
        maatVault.removeStrategy(strategyId);

        address[] memory strategies = maatVault.getStrategies();
        assertEq(strategies.length, 0, "Strategy wasn't removed from Vault");
    }

    function test_removeStrategy_RemovesStrategyFromArray_WhenMultipleStrategies(
        uint8 numberOfStrategies,
        uint8 randomStrategyIndexToRemove
    ) public {
        vm.assume(randomStrategyIndexToRemove < numberOfStrategies);
        // Remove initial strategy
        maatVault.removeStrategy(strategyId);

        YearnV3Strategy[] memory strategies =
            _setupMultipleStrategiesOnVault(maatVault, numberOfStrategies);

        bytes32 _strategyId =
            strategies[randomStrategyIndexToRemove].getStrategyId();
        address strategyToRemove =
            address(strategies[randomStrategyIndexToRemove]);

        maatVault.removeStrategy(_strategyId);

        address[] memory strategiesAfterRemoval = maatVault.getStrategies();

        assertEq(
            strategiesAfterRemoval.length,
            numberOfStrategies - 1,
            "Exactly 1 Strategy MUST be removed"
        );

        // Check all removed strategies are not in the Vault
        bool isStrategyRemoved = true;

        for (uint256 j = 0; j < strategiesAfterRemoval.length; j++) {
            if (strategiesAfterRemoval[j] == strategyToRemove) {
                isStrategyRemoved = false;
                break;
            }
        }

        assertTrue(isStrategyRemoved, "Strategy wasn't removed");
    }

    function test_RevertIf_StrategyNotExistsInVault() public {
        maatVault.removeStrategy(strategyId);

        vm.expectRevert("MaatVaultV1: Nonexistent strategy");
        maatVault.removeStrategy(strategyId);
    }

    function test_RevertIf_StrategyHasFunds() public {
        deal(address(token), address(maatVault), 100);
        maatVault.depositInStrategy(strategyId, 100, bytes32("intentionId"));

        vm.expectRevert("MaatVaultV1: Cannot delete strategy with funds");
        maatVault.removeStrategy(strategyId);
    }

    function test_removeStrategy_WithStrategySharesWithoutAssets() public {
        deal(address(strategy), address(maatVault), 100);

        maatVault.removeStrategy(strategyId);

        vm.expectRevert("MaatVaultV1: Nonexistent strategy");
        maatVault.getStrategyById(strategyId);
    }
}
