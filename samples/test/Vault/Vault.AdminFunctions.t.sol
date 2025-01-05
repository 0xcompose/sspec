// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";
import {Strategy} from "maat-strategies/contracts/Strategy.sol";

import {IWithdrawRequestLogic} from "../../src/interfaces/IExecutor.sol";

contract AdminFunctions is MaatVaultTestSetup {
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

    function test_addRelatedVault() public {
        uint32 chainId = 123;
        uint32[] memory eids = new uint32[](1);
        eids[0] = chainId;

        address[] memory vaults = new address[](1);
        vaults[0] = address(address(this));

        maatVault.addRelatedVaults(eids, vaults);

        assertEq(maatVault.getRelatedVault(chainId), address(this));
    }

    function test_removeRelatedVault() public {
        uint32 chainId = 123;
        uint32[] memory eids = new uint32[](1);
        eids[0] = chainId;

        address[] memory vaults = new address[](1);
        vaults[0] = address(address(this));

        maatVault.addRelatedVaults(eids, vaults);

        maatVault.removeRelatedVault(chainId);

        vm.expectRevert("MaatVaultV1: Vault not found");
        maatVault.getRelatedVault(chainId);
    }

    function test_setCommander() public {
        address newCommander = address(0x12309);

        maatVault.setCommander(newCommander);

        assertEq(maatVault.commander(), newCommander);
    }

    function test_getMinAmount() public {
        maatVault.setMinAmount(100);

        assertEq(maatVault.minAmount(), 100);
    }

    function test_setWithdrawCancelTimer() public {
        maatVault.setWithdrawCancellationDelay(1000);

        assertEq(maatVault.withdrawCancellationDelay(), 1000);
    }

    function test_setEmergencyWithdrawalDelay() public {
        uint256 newDelay = 1000;

        uint256 initialDelay = maatVault.emergencyWithdrawalDelay();

        vm.expectEmit(true, true, true, true);
        emit IWithdrawRequestLogic.EmergencyWithdrawalDelayChanged(initialDelay, newDelay);
        maatVault.setEmergencyWithdrawalDelay(newDelay);

        assertEq(maatVault.emergencyWithdrawalDelay(), newDelay);
    }
}
