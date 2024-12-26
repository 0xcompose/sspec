// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";

contract MaatVaultVirtualAssetsTest is MaatVaultTestSetup {
    MaatVaultHarness secondMaatVault;

    uint256 amount = 100e6;
    uint32 dstEid = 2;
    bytes32 intentionId = "intentionId";

    IExecutor.ActionType[] bridgeType;
    IExecutor.ActionInput[] bridgeInput;

    StargateAdapterMock stargateAdapter;

    function _afterSetUp() internal override {
        bridgeType.push(IExecutor.ActionType.BRIDGE);
        bridgeInput.push(
            IExecutor.ActionInput(dstEid, strategyId, amount, intentionId)
        );

        stargateAdapter = new StargateAdapterMock();
        addressProvider.changeStargateAdapter(address(stargateAdapter));

        secondMaatVault = new MaatVaultHarness(
            address(this),
            address(token),
            amountMin,
            address(addressProvider),
            commander,
            watcher,
            2
        );

        uint32[] memory eids = new uint32[](1);
        eids[0] = dstEid;

        address[] memory vaults = new address[](1);
        vaults[0] = address(secondMaatVault);

        maatVault.addRelatedVaults(eids, vaults);
        stargateAdapter.setPeer(2, address(secondMaatVault));

        deal(address(token), address(maatVault), amount);
    }

    function test_virtualAssets() public {
        assertEq(maatVault.virtualAssets(), 0);
    }

    function test_virtualAssets_IncreaseOnBridgeDepartureAndDecreaseOnBridgeArrival(
    ) public {
        maatVault.execute(bridgeType, bridgeInput);

        assertEq(
            maatVault.virtualAssets(),
            int256(amount),
            "Source virtualAssets MUST INCREASE for amount of bridged tokens"
        );

        assertEq(
            secondMaatVault.virtualAssets(),
            -int256(amount),
            "Destination virtualAssets MUST DECREASE for amount of bridged tokens"
        );
    }

    function testFuzz_virtualAssets_AccountsForBridgeFees(uint32 fees) public {
        vm.assume(fees < 100000); // <100%

        stargateAdapter.setFees(fees);

        maatVault.execute(bridgeType, bridgeInput);

        assertEq(maatVault.virtualAssets(), int256(amount));

        uint256 feesPaid = calculateFees(amount, fees);

        assertEq(
            secondMaatVault.virtualAssets(),
            -int256(amount + feesPaid),
            "Destination virtualAssets MUST DECREASE for amount of bridged tokens + fees"
        );

        int256 totalVirtualBalance =
            maatVault.virtualAssets() + secondMaatVault.virtualAssets();

        assertEq(
            totalVirtualBalance,
            -int256(feesPaid),
            "Total Virtual Assets MUST be negative and equal to fees paid"
        );
    }

    function calculateFees(uint256 amount, uint32 fees)
        internal
        view
        returns (uint256)
    {
        return (amount * fees) / 100000;
    }
}
