// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_LiFiExecutorProxy.Setup.t.sol";
import {console} from "forge-std/console.sol";

contract LiFiExecutorProxyDepositTest is LiFiExecutorProxyTestSetup {
    function test_deposit_OnlyExecutorCanCall() public {
        address nonExecutor = address(0x123);
        vm.prank(nonExecutor);

        vm.expectRevert(
            "LiFiExecutorProxy: Only executor can call this function"
        );
        proxy.deposit(vaultUSDC, address(0), receiver);
    }

    function test_deposit_VaultMustExist() public {
        address nonExistentVault = address(0x456);
        vm.prank(executor);

        vm.expectRevert("LiFiExecutorProxy: Vault not found");
        proxy.deposit(nonExistentVault, address(0), receiver);
    }

    function test_deposit_TokenAddressMustNotBeZero() public {
        vm.prank(executor);

        vm.expectRevert("LiFiExecutorProxy: Zero address token");
        proxy.deposit(vaultUSDC, address(0), receiver);
    }

    function test_deposit_ReceiverAddressMustNotBeZero() public {
        vm.prank(executor);

        vm.expectRevert("LiFiExecutorProxy: Zero address receiver");
        proxy.deposit(vaultUSDC, address(token), address(0));
    }

    function test_deposit_TransfersTokensFromExecutor() public {
        uint256 initialBalanceExecutor = token.balanceOf(executor);
        uint256 initialBalanceVault = token.balanceOf(vaultUSDC);

        proxy.deposit(vaultUSDC, address(token), receiver);

        uint256 finalBalance = token.balanceOf(executor);
        assertEq(finalBalance, 0);
        assertEq(
            token.balanceOf(vaultUSDC),
            initialBalanceVault + initialBalanceExecutor
        );
    }

    function test_deposit_ApprovesVaultForToken() public {
        uint256 assets = token.balanceOf(executor);

        proxy.deposit(vaultUSDC, address(token), receiver);

        assertEq(
            token.allowance(address(proxy), vaultUSDC),
            type(uint256).max - assets
        );
    }

    function test_deposit_DepositsToVault() public {
        uint256 assets = token.balanceOf(executor);

        uint256 expectedBalance = MaatVaultV1(vaultUSDC).previewDeposit(assets);

        proxy.deposit(vaultUSDC, address(token), receiver);

        assertEq(MaatVaultV1(vaultUSDC).balanceOf(receiver), expectedBalance);
    }
}
