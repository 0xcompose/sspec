// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";

contract Fee is MaatVaultTestSetup {
    address buyer = address(0x031);

    function _afterSetUp() internal override {
        feeTo = address(this);

        maatVault.setFeeTo(feeTo);

        deal(address(token), buyer, 10 ** 30);
        deal(address(token), address(maatVault), 10 ** 60);
        deal(address(maatVault), buyer, 10 ** 50);

        address[] memory vaultsArray = new address[](1);
        vaultsArray[0] = address(maatVault);

        uint112[] memory ppsArray = new uint112[](1);
        ppsArray[0] = 14612431;

        skip(10);
        oracle.updateGlobalPPS(vaultsArray, ppsArray);
        skip(10);
        oracle.updateGlobalPPS(vaultsArray, ppsArray);
    }

    function testFuzz_FeeDeposit(uint256 amountIn, uint64 feeIn) public {
        vm.assume(feeIn > 10 ** 6 && feeIn < 5 * 10 ** 6);
        vm.assume(amountIn > 10 ** 6 && amountIn < 10 ** 30);

        maatVault.setFees(feeIn, 0);

        uint256 initialTokenBalanceVault = token.balanceOf(address(maatVault));
        uint256 initialSharesBalanceBuyer = maatVault.balanceOf(buyer);

        vm.startPrank(buyer);
        token.approve(address(maatVault), amountIn);
        maatVault.deposit(amountIn, buyer);

        uint256 predictedShares = (maatVault.convertToShares(amountIn) * (10 ** 8 - feeIn)) / 10 ** 8;
        // console.log(predictedShares);

        vm.assertApproxEqAbs(maatVault.balanceOf(buyer), predictedShares + initialSharesBalanceBuyer, 10);
        vm.assertApproxEqAbs(maatVault.balanceOf(feeTo), maatVault.convertToShares(amountIn) - predictedShares, 10);
        vm.assertEq(token.balanceOf(address(maatVault)), amountIn + initialTokenBalanceVault);
    }

    function testFuzz_FeeMint(uint256 shares, uint64 feeIn) public {
        vm.assume(feeIn > 10 ** 6 && feeIn < 5 * 10 ** 6);
        vm.assume(shares > 10 ** 6 && shares < 10 ** 30);

        maatVault.setFees(feeIn, 0);

        uint256 initialTokenBalanceVault = token.balanceOf(address(maatVault));
        uint256 initialSharesBalanceBuyer = maatVault.balanceOf(buyer);

        vm.startPrank(buyer);
        token.approve(address(maatVault), shares);
        maatVault.mint(shares, buyer);

        uint256 predictedShares = (shares * (10 ** 8 - feeIn)) / 10 ** 8;

        vm.assertApproxEqAbs(maatVault.balanceOf(buyer), predictedShares + initialSharesBalanceBuyer, 10);
        vm.assertApproxEqAbs(maatVault.balanceOf(feeTo), shares - predictedShares, 10);
        vm.assertEq(token.balanceOf(address(maatVault)), maatVault.convertToAssets(shares) + initialTokenBalanceVault);
    }

    function testFuzz_FeeWithdraw(uint256 assets, uint64 feeOut) public {
        vm.assume(feeOut > 10 ** 6 && feeOut < 5 * 10 ** 6);
        vm.assume(assets > 10 ** 6 && assets < 10 ** 30);

        maatVault.setFees(0, feeOut);

        uint256 initialSharesBalanceBuyer = maatVault.balanceOf(buyer);
        uint256 initialTokenBalanceBuyer = token.balanceOf(buyer);

        vm.startPrank(buyer);
        maatVault.approve(address(maatVault), 10 ** 50);
        maatVault.withdraw(assets, buyer, buyer);

        uint256 predictedShares = maatVault.previewWithdraw(assets);

        vm.assertEq(maatVault.balanceOf(buyer), initialSharesBalanceBuyer - predictedShares);
        vm.assertEq(
            maatVault.balanceOf(feeTo), maatVault.calculateFee(maatVault.convertToSharesByLowerPPS(assets), feeOut)
        );

        vm.assertApproxEqAbs(token.balanceOf(buyer), initialTokenBalanceBuyer + assets, 10);
    }

    function testFuzz_FeeRedeem(uint256 shares, uint64 feeOut) public {
        vm.assume(feeOut > 10 ** 6 && feeOut < 5 * 10 ** 6);
        vm.assume(shares > 10 ** 6 && shares < 10 ** 30);

        maatVault.setFees(0, feeOut);

        uint256 initialTokenBalanceBuyer = token.balanceOf(buyer);
        uint256 initialSharesBalanceBuyer = maatVault.balanceOf(buyer);

        vm.startPrank(buyer);
        maatVault.approve(address(maatVault), 10 ** 50);
        maatVault.redeem(shares, buyer, buyer);

        uint256 predictedAssets = maatVault.previewRedeem(shares);

        vm.assertEq(maatVault.balanceOf(buyer), initialSharesBalanceBuyer - shares);
        vm.assertEq(maatVault.balanceOf(feeTo), maatVault.calculateFee(shares, feeOut));
        vm.assertApproxEqAbs(token.balanceOf(buyer), initialTokenBalanceBuyer + predictedAssets, 10);
    }

    function testFuzz_FeeRequestWithdraw(uint256 shares, uint64 feeOut) public {
        uint256 initialTokenBalanceBuyer = token.balanceOf(buyer);
        uint256 initialSharesBalanceBuyer = maatVault.balanceOf(buyer);

        vm.assume(maatVault.convertToAssetsByLowerPPS(shares) > amountMin && shares < initialSharesBalanceBuyer);
        vm.assume(feeOut > 10 ** 6 && feeOut < 5 * 10 ** 6);

        maatVault.setFees(0, feeOut);

        vm.startPrank(buyer);
        uint256 assets = maatVault.previewRedeem(shares);

        maatVault.approve(address(maatVault), shares);

        bytes32 intentionId = maatVault.requestWithdraw(shares, 1, buyer, buyer);
        vm.stopPrank();

        assertEq(maatVault.balanceOf(buyer), initialSharesBalanceBuyer - shares);

        IExecutor.ActionType fulfillWithdrawRequest = IExecutor.ActionType.FULFILL_WITHDRAW_REQUEST;

        IExecutor.ActionType[] memory actions = new IExecutor.ActionType[](1);
        actions[0] = fulfillWithdrawRequest;

        IExecutor.ActionInput[] memory actionData = new IExecutor.ActionInput[](1);

        actionData[0] = IExecutor.ActionInput({dstEid: 0, strategyId: bytes32(0), amount: 0, intentionId: intentionId});

        maatVault.execute(actions, actionData);

        assertEq(token.balanceOf(buyer), initialTokenBalanceBuyer + assets);
        assertEq(maatVault.balanceOf(feeTo), maatVault.calculateFee(shares, feeOut));
    }

    function testFuzz_FeePreviewDeposit(uint256 assets, uint64 feeIn) public {
        vm.assume(feeIn > 10 ** 6 && feeIn < 5 * 10 ** 6);
        vm.assume(assets > 10 ** 4 && assets < 10 ** 30);

        maatVault.setFees(feeIn, 0);

        uint256 shares = maatVault.previewDeposit(assets);
        uint256 predictedShares =
            maatVault.convertToShares(assets) - maatVault.calculateFee(maatVault.convertToShares(assets), feeIn);

        assertEq(shares, predictedShares);
    }

    function testFuzz_FeePreviewMint(uint256 shares, uint64 feeIn) public {
        vm.assume(feeIn > 10 ** 6 && feeIn < 5 * 10 ** 6);
        vm.assume(shares > 10 ** 4 && shares < 10 ** 30);

        maatVault.setFees(feeIn, feeIn);

        uint256 assets = maatVault.previewMint(shares);
        uint256 predictedAssets = maatVault.convertToAssets(shares + maatVault.calculateFee(shares, feeIn));

        assertEq(assets, predictedAssets);
    }

    function testFuzz_FeePreviewWithdraw(uint256 assets, uint64 feeOut) public {
        vm.assume(feeOut > 10 ** 6 && feeOut < 5 * 10 ** 6);
        vm.assume(assets > 10 ** 4 && assets < 10 ** 30);

        maatVault.setFees(0, feeOut);

        uint256 shares = maatVault.previewWithdraw(assets);

        uint256 predictedShares = maatVault.convertToSharesByLowerPPS(assets)
            + maatVault.calculateFee(maatVault.convertToSharesByLowerPPS(assets), feeOut);

        assertEq(shares, predictedShares);
    }

    function testFuzz_FeePreviewRedeem(uint256 shares, uint64 feeOut) public {
        vm.assume(feeOut > 10 ** 6 && feeOut < 5 * 10 ** 6);
        vm.assume(shares > 10 ** 4 && shares < 10 ** 30);

        maatVault.setFees(0, feeOut);

        uint256 assets = maatVault.previewRedeem(shares);

        uint256 predictedAssets = maatVault.convertToAssetsByLowerPPS(shares - maatVault.calculateFee(shares, feeOut));

        assertEq(assets, predictedAssets);
    }
}
