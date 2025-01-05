// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";
import {StargateAdapterMock} from "../mock/StargateAdapterMock.sol";

contract Idle is MaatVaultTestSetup {
    address buyer = address(0xdeadaaaadead);

    StargateAdapterMock stargateAdapter;
    MaatVaultHarness secondMaatVault;

    function _afterSetUp() internal override {
        deal(address(token), address(this), 10 ** 30);
        maatVault.setIdle(0);

        stargateAdapter = new StargateAdapterMock();

        secondMaatVault = new MaatVaultHarness(
            address(this), address(token), amountMin, address(addressProvider), commander, watcher, 2
        );
        addressProvider.changeStargateAdapter(address(stargateAdapter));

        stargateAdapter.setPeer(uint32(2), address(secondMaatVault));
        uint32[] memory eids = new uint32[](1);
        eids[0] = 2;

        address[] memory vaults = new address[](1);
        vaults[0] = address(secondMaatVault);

        maatVault.addRelatedVaults(eids, vaults);
    }

    function testFuzz_deposit_IdleChange(uint256 assets) public {
        vm.assume(assets > amountMin && assets < 2 ** 112 - 1);
        deal(address(token), buyer, assets + 1);

        vm.startPrank(buyer);
        token.approve(address(maatVault), assets);
        maatVault.deposit(assets, buyer);

        token.transfer(address(maatVault), 1);
        assertEq(maatVault.idle(), assets);
    }

    function testFuzz_mint_IdleChange(uint256 shares) public {
        vm.assume(shares > amountMin && shares < 2 ** 112 - 1);
        deal(address(token), buyer, shares + 1);

        vm.startPrank(buyer);
        token.approve(address(maatVault), shares);
        maatVault.mint(shares, buyer);

        token.transfer(address(maatVault), 1);
        assertEq(maatVault.idle(), maatVault.convertToAssets(shares));
    }

    function testFuzz_withdraw_IdleChange(uint256 assets, uint256 dust) public {
        vm.assume(assets > amountMin && assets < 2 ** 112 - 1);
        vm.assume(dust <= assets);
        deal(address(maatVault), buyer, maatVault.previewWithdraw(assets));
        deal(address(token), address(maatVault), assets + dust);

        maatVault.setIdle(assets + dust);

        uint256 initialBalanceVault = token.balanceOf(address(maatVault));

        vm.startPrank(buyer);
        maatVault.approve(address(maatVault), assets);
        maatVault.withdraw(assets, buyer, buyer);

        token.transfer(address(maatVault), 1);
        assertEq(maatVault.idle(), initialBalanceVault - assets);
    }

    function testFuzz_redeem_IdleChanged(uint256 shares, uint256 dust) public {
        vm.assume(shares > amountMin && shares < 2 ** 112 - 1);
        vm.assume(dust <= shares);
        deal(address(maatVault), buyer, maatVault.previewWithdraw(shares));
        deal(address(token), address(maatVault), shares + dust);

        maatVault.setIdle(shares + dust);

        uint256 initialBalanceVault = token.balanceOf(address(maatVault));

        vm.startPrank(buyer);
        maatVault.approve(address(maatVault), shares);
        maatVault.redeem(shares, buyer, buyer);

        token.transfer(address(maatVault), 1);
        assertEq(maatVault.idle(), initialBalanceVault - maatVault.previewRedeem(shares));
    }

    function testFuzz_depositInStrategy_IdleChanged(uint256 amountToDeposit) public {
        vm.assume(amountToDeposit > amountMin && amountToDeposit < 10 ** 10);
        deal(address(token), address(maatVault), amountToDeposit);
        maatVault.setIdle(amountToDeposit);

        token.approve(address(maatVault), amountToDeposit);
        maatVault.depositInStrategy(strategyId, amountToDeposit, bytes32(0));

        token.transfer(address(maatVault), 1);
        assertEq(maatVault.idle(), 0);
    }

    function testFuzz_withdrawFromStrategy_IdleChanged(uint256 amountToWithdraw) public {
        vm.assume(amountToWithdraw > amountMin && amountToWithdraw < 10 ** 10);
        deal(address(token), address(maatVault), amountToWithdraw + 100);
        deal(address(token), address(strategy), amountToWithdraw + 100);

        maatVault.setIdle(amountToWithdraw + 100);

        token.approve(address(maatVault), amountToWithdraw + 2);
        maatVault.depositInStrategy(strategyId, amountToWithdraw + 2, bytes32(0));

        uint256 idleBefore = maatVault.idle();
        maatVault.withdrawFromStrategy(strategyId, amountToWithdraw, bytes32(0));

        token.transfer(address(maatVault), 1);

        assertEq(maatVault.idle(), idleBefore + amountToWithdraw);
    }

    function testFuzz_bridge_IdleChanged(uint256 amountToBridge) public {
        vm.assume(amountToBridge > amountMin && amountToBridge < 10 ** 10);
        deal(address(token), address(maatVault), amountToBridge);
        deal(address(token), address(strategy), amountToBridge);

        maatVault.setIdle(amountToBridge);

        maatVault.bridge(amountToBridge, 2, bytes32(0));

        token.transfer(address(maatVault), 1);
        token.transfer(address(secondMaatVault), 1);

        assertEq(maatVault.idle(), 0);
        assertEq(secondMaatVault.idle(), amountToBridge);
    }

    //REVERT TESTS
    function testFuzz_withdraw_RevertIf_IdleIncorrect(uint256 assets, uint256 dust) public {
        vm.assume(assets > amountMin && assets < 2 ** 112 - 1);
        vm.assume(dust <= assets);
        deal(address(maatVault), buyer, maatVault.previewWithdraw(assets));
        deal(address(token), address(maatVault), assets + dust);

        maatVault.setIdle(0);

        vm.startPrank(buyer);
        maatVault.approve(address(maatVault), assets);

        vm.expectRevert("MaatVaultV1: Arithmetic error during idle calculations");
        maatVault.withdraw(assets, buyer, buyer);
    }

    function testFuzz_redeem_RevertIf_IdleIncorrect(uint256 shares, uint256 dust) public {
        vm.assume(shares > amountMin && shares < 2 ** 112 - 1);
        vm.assume(dust <= shares);
        deal(address(maatVault), buyer, maatVault.previewWithdraw(shares));
        deal(address(token), address(maatVault), shares + dust);

        maatVault.setIdle(0);

        vm.startPrank(buyer);
        maatVault.approve(address(maatVault), shares);

        vm.expectRevert("MaatVaultV1: Arithmetic error during idle calculations");
        maatVault.redeem(shares, buyer, buyer);
    }

    function testFuzz_depositItStrategy_RevertIf_IdleIncorrect(uint256 amountToDeposit) public {
        vm.assume(amountToDeposit > amountMin && amountToDeposit < 10 ** 10);
        deal(address(token), address(maatVault), amountToDeposit);
        maatVault.setIdle(0);

        token.approve(address(maatVault), amountToDeposit);

        vm.expectRevert("MaatVaultV1: Arithmetic error during idle calculations");
        maatVault.depositInStrategy(strategyId, amountToDeposit, bytes32(0));
    }

    function testFuzz_bridge_RevertIf_IdleIncorrect(uint256 amountToBridge) public {
        vm.assume(amountToBridge > amountMin && amountToBridge < 10 ** 10);
        deal(address(token), address(maatVault), amountToBridge);
        deal(address(token), address(strategy), amountToBridge);

        maatVault.setIdle(0);

        vm.expectRevert("MaatVaultV1: Arithmetic error during idle calculations");
        maatVault.bridge(amountToBridge, 2, bytes32(0));
    }
}
