// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";

contract MaatVaultCancelWithdrawTesting is MaatVaultTestSetup {
    address owner = address(0x12854888);
    address receiver = address(0xdddd);

    uint256 initialBalanceShares = 10 ** 40;
    uint256 initialBalanceToken = 10 ** 40;

    function _afterSetUp() internal override {
        deal(address(token), owner, initialBalanceToken * 2);
        deal(address(token), address(maatVault), initialBalanceToken);

        vm.startPrank(owner);
        token.approve(address(maatVault), initialBalanceShares * 2);
        maatVault.mint(initialBalanceShares, owner);
        vm.stopPrank();

        address[] memory vaultsArray = new address[](1);
        vaultsArray[0] = address(maatVault);

        uint112[] memory ppsArray = new uint112[](1);
        ppsArray[0] = 132123123;

        skip(10);
        oracle.updateGlobalPPS(vaultsArray, ppsArray);
        skip(10);
        oracle.updateGlobalPPS(vaultsArray, ppsArray);
    }

    function test_FuzzCancellingWithdraw(uint256 sharesToWithdraw) public {
        vm.assume(sharesToWithdraw <= 10 ** 40);
        vm.assume(sharesToWithdraw > amountMin);

        vm.startPrank(owner);
        maatVault.approve(address(maatVault), sharesToWithdraw);

        maatVault.setNonce(12);
        vm.expectEmit(address(maatVault));
        emit IWithdrawRequestLogic.WithdrawalRequested(
            sharesToWithdraw, maatVault.previewRedeem(sharesToWithdraw), owner, maatVault.getIntentionId(12), 1
        );
        bytes32 intentionId = maatVault.requestWithdraw(sharesToWithdraw, 1, owner, receiver);

        skip(maatVault.withdrawCancellationDelay());
        uint256 sharesBeforeCancelling = maatVault.balanceOf(owner);
        maatVault.cancelWithdrawal(intentionId);

        assertEq(maatVault.balanceOf(owner), sharesBeforeCancelling + sharesToWithdraw);

        vm.expectRevert("MaatVaultV1: Request not found");

        IMaatVaultV1.WithdrawRequestInfo memory info = maatVault.getWithdrawRequest(intentionId);
    }

    function test_CancellingWithdraw_RevertIf_NotEnoughTimeHasPassedYet() public {
        uint256 sharesToWithdraw = 10 * 10;

        vm.startPrank(owner);
        maatVault.approve(address(maatVault), sharesToWithdraw);

        maatVault.setNonce(0);
        vm.expectEmit(address(maatVault));
        emit IWithdrawRequestLogic.WithdrawalRequested(
            sharesToWithdraw, maatVault.previewRedeem(sharesToWithdraw), owner, maatVault.getIntentionId(0), 1
        );
        bytes32 intentionId = maatVault.requestWithdraw(sharesToWithdraw, 1, owner, receiver);

        vm.expectRevert("WithdrawRequestLogic: Not enough time has passed yet to withdraw");
        maatVault.cancelWithdrawal(intentionId);
    }

    function test_CancellingWithdraw_RevertIf_RequestIsNotExist() public {
        uint256 sharesToWithdraw = 10 * 10;

        vm.startPrank(owner);
        maatVault.approve(address(maatVault), sharesToWithdraw);

        maatVault.setNonce(0);
        vm.expectEmit(address(maatVault));
        emit IWithdrawRequestLogic.WithdrawalRequested(
            sharesToWithdraw, maatVault.previewRedeem(sharesToWithdraw), owner, maatVault.getIntentionId(0), 1
        );
        bytes32 intentionId = maatVault.requestWithdraw(sharesToWithdraw, 1, owner, receiver);

        skip(maatVault.withdrawCancellationDelay());
        maatVault.cancelWithdrawal(intentionId);

        vm.expectRevert("WithdrawRequestLogic: Request does not exist");
        maatVault.cancelWithdrawal(intentionId);
    }

    function test_CancellingWithdraw_RevertIf_SenderIsNotOwner() public {
        uint256 sharesToWithdraw = 10 * 10;

        vm.startPrank(owner);
        maatVault.approve(address(maatVault), sharesToWithdraw);

        maatVault.setNonce(0);
        vm.expectEmit(address(maatVault));
        emit IWithdrawRequestLogic.WithdrawalRequested(
            sharesToWithdraw, maatVault.previewRedeem(sharesToWithdraw), owner, maatVault.getIntentionId(0), 1
        );
        bytes32 intentionId = maatVault.requestWithdraw(sharesToWithdraw, 1, owner, receiver);
        vm.stopPrank();

        skip(maatVault.withdrawCancellationDelay());

        vm.prank(address(0xdead));
        vm.expectRevert("WithdrawRequestLogic: Unauthorized caller");
        maatVault.cancelWithdrawal(intentionId);
    }
}
