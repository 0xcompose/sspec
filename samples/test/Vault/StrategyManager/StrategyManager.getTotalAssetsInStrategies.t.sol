// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../_.Vault.Setup.sol";

contract GetTotalAssetsInStrategies is MaatVaultTestSetup {
    uint256 numberOfStrategies = 10;

    uint256 depositErrorDelta = 7 wei;
    uint256 withdrawErrorDelta = 10 wei; // on withdraw bigger error occurs

    function _afterSetUp() internal override {
        // Remove initial strategy
        address[] memory strategies = maatVault.getStrategies();
        bytes32 strategyId = Strategy(strategies[0]).getStrategyId();
        maatVault.removeStrategy(strategyId);

        // YearnV3Strategy[] memory strategies =
        _setupMultipleStrategiesOnVault(maatVault, numberOfStrategies);
    }

    function test_ZeroAssetsInStrategiesAfterDeployment() public view {
        assertEq(maatVault.getTotalAssetsInStrategies(), 0, "total assets in strategies MUST be 0 after deployment");
    }

    function test_DepositOnVaultDoesNotAffectTotalAssetsInStrategies() public {
        deal(address(token), address(this), 1000e6);

        token.approve(address(maatVault), 1000e6);

        maatVault.deposit(1000e6, address(this));

        assertEq(
            maatVault.getTotalAssetsInStrategies(),
            0,
            "Deposit on vault MUST NOT be reflected in total assets in strategies"
        );
    }

    function testFuzz_DepositToStrategyIsReflectedInTotalAssetsInStrategies(uint32 amountToDeposit) public {
        uint256 totalAssets = 1000e6;
        vm.assume(amountToDeposit > 10 wei);
        vm.assume(amountToDeposit <= totalAssets / numberOfStrategies);

        deal(address(token), address(this), totalAssets);

        token.approve(address(maatVault), totalAssets);

        maatVault.deposit(totalAssets, address(this));

        // Distribute funds to strategies
        address[] memory strategies = maatVault.getStrategies();

        uint256 totalAssetsInStrategies;

        for (uint256 i = 0; i < strategies.length; i++) {
            address strategy = strategies[i];

            _depositToStrategy(maatVault, strategy, amountToDeposit);

            assertApproxEqAbs(
                maatVault.getTotalAssetsInStrategies(),
                totalAssetsInStrategies + amountToDeposit,
                depositErrorDelta,
                "Distribution to strategies MUST be reflected in total assets in strategies"
            );

            // Update total assets in strategies to mitigate increasing error
            totalAssetsInStrategies = maatVault.getTotalAssetsInStrategies();
        }
    }

    function testFuzz_WithdrawFromStrategyIsReflectedInTotalAssetsInStrategies(uint32 amountToWithdraw) public {
        uint256 totalAssets = 1000e6;

        vm.assume(amountToWithdraw > 10 wei);
        vm.assume(amountToWithdraw < totalAssets / numberOfStrategies);

        deal(address(token), address(this), totalAssets);

        token.approve(address(maatVault), totalAssets);

        maatVault.deposit(totalAssets, address(this));

        // Distribute funds to strategies
        address[] memory strategies = maatVault.getStrategies();

        for (uint256 i = 0; i < strategies.length; i++) {
            address strategy = strategies[i];

            // Distribute equally to all strategies
            _depositToStrategy(maatVault, strategy, totalAssets / numberOfStrategies);
        }

        // Withdraw funds from strategies
        uint256 totalAssetsInStrategies = maatVault.getTotalAssetsInStrategies();

        for (uint256 i = 0; i < strategies.length; i++) {
            address strategy = strategies[i];

            _withdrawFromStrategy(maatVault, strategy, amountToWithdraw);

            assertApproxEqAbs(
                maatVault.getTotalAssetsInStrategies(),
                totalAssetsInStrategies - amountToWithdraw,
                withdrawErrorDelta,
                "Withdraw from strategies MUST be reflected in total assets in strategies"
            );

            // Update total assets in strategies to mitigate increasing error
            totalAssetsInStrategies = maatVault.getTotalAssetsInStrategies();
        }
    }

    // Should the function count assets on the disabled strategies?
}
