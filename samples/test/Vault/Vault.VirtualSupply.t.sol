// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";
import "../mock/SharesBridgeMock.sol";

contract MaatVaultVirtualSupplyTest is MaatVaultTestSetup {
    MaatVaultHarness targetVault;
    SharesBridgeMock sharesBridgeMock;

    function _afterSetUp() internal override {
        targetVault = _setupTargetVault();

        sharesBridgeMock = _setupSharesBridge();

        sharesBridgeMock.setPeer(targetEid, address(targetVault));
    }

    function test_virtualSupply_MustBeZeroBeforeAnyBridges() public {
        assertEq(
            maatVault.virtualSupply(),
            0,
            "Virtual supply MUST be 0 before any bridges"
        );
    }

    function testFuzz_VirtualSupplyMustChangeToBeCounterForBridgeAmounts(
        uint256 amount
    ) public {
        vm.assume(amount > 0);
        deal(address(maatVault), address(this), amount);

        maatVault.bridgeShares(targetEid, amount, "");

        assertEq(
            uint256(maatVault.virtualSupply()),
            amount,
            "Virtual supply MUST be increased on bridge departure for amount of bridge"
        );

        assertEq(
            targetVault.virtualSupply(),
            -int256(amount),
            "Virtual supply MUST be decreased on bridge arrival for amount of bridge"
        );

        assertEq(
            maatVault.virtualSupply() + targetVault.virtualSupply(),
            0,
            "Virtual supply MUST be 0 in total after bridge"
        );
    }
}
