// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";

contract MaatVaultGetPPSDataTest is MaatVaultTestSetup {
    MaatVaultHarness targetVault;
    SharesBridgeMock sharesBridgeMock;

    uint256 maxErrorForTotalAssets = 2;
    uint256 maxErrorForTotalSupply = 2;

    function _afterSetUp() internal override {
        maatVault.setIdle(0);
        // To allow more tests cases to check
        maatVault.setMinAmount(0);
    }

    function test_getPPSData_MustBeZeroAfterSetup() public {
        IMaatVaultV1.PPSData memory ppsData = maatVault.getPPSData();

        assertEq(ppsData.totalSupply, 0);
        assertEq(ppsData.totalAssets, 0);
    }

    function testFuzz_getPPSData_MustCalculateTotalAssets(
        uint64 _assetsOnVault,
        uint64 _assetsInStrategies,
        int64 _virtualAssets
    ) public {
        vm.assume(_assetsOnVault > 0);
        vm.assume(_assetsInStrategies > 10);
        vm.assume(
            _assetsInStrategies <= strategy.maxDeposit(address(maatVault))
        );
        // getPPSData() MUST return totalAssets as a sum of:
        // - assets on vault
        // - assets in strategies
        // - virtual assets

        // Params are limited in size to limit fuzzing guesses
        // After generation params are converted to uint and int to fit the function params
        uint256 assetsOnVault = uint256(_assetsOnVault);
        uint256 assetsInStrategies = uint256(_assetsInStrategies);
        int256 virtualAssets = int256(_virtualAssets);

        if (virtualAssets > 0) {
            maatVault.increaseVirtualAssets(uint256(int256(virtualAssets)));
        } else {
            maatVault.decreaseVirtualAssets(uint256(-int256(virtualAssets)));
        }

        uint256 totalAssetsOnVault =
            uint256(assetsOnVault) + uint256(assetsInStrategies);

        deal(address(token), address(this), totalAssetsOnVault);

        token.approve(address(maatVault), totalAssetsOnVault);

        maatVault.deposit(totalAssetsOnVault, address(this));

        // Distribute assetsInStrategies to strategies

        _depositToStrategy(maatVault, address(strategy), assetsInStrategies);

        int256 expectedTotalAssets =
            int256(assetsOnVault) + int256(assetsInStrategies) + virtualAssets;

        assertApproxEqAbs(
            maatVault.getPPSData().totalAssets,
            expectedTotalAssets,
            maxErrorForTotalAssets,
            "Total assets MUST be a sum of assets on vault, in strategies and virtual assets"
        );
    }

    function test_getPPSData_MustCalculateTotalSupply(
        uint64 _totalSupply,
        int64 _virtualSupply
    ) public {
        // Assume some initial total supply and virtual supply
        uint256 totalSupply = uint256(_totalSupply);
        int256 virtualSupply = int256(_virtualSupply);

        // Deposit to create totalSupply
        deal(address(token), address(this), type(uint256).max);

        token.approve(address(maatVault), type(uint256).max);

        maatVault.mint(totalSupply, address(this));

        // Adjust virtual supply
        if (virtualSupply > 0) {
            maatVault.increaseVirtualSupply(uint256(int256(virtualSupply)));
        } else {
            maatVault.decreaseVirtualSupply(uint256(-int256(virtualSupply)));
        }

        // Calculate expected total supply
        int256 expectedTotalSupply = int256(totalSupply) + virtualSupply;

        // Assert that the total supply is calculated correctly
        assertApproxEqAbs(
            maatVault.getPPSData().totalSupply,
            expectedTotalSupply,
            maxErrorForTotalSupply,
            "Total supply MUST be a sum of current totalSupply and virtualSupply"
        );
    }
}
