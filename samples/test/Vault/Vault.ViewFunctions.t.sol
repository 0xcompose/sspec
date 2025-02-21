// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./_.Vault.Setup.sol";

contract ViewFunctions is MaatVaultTestSetup {
    function testFuzz_convertToShares(uint256 assets) public {
        vm.assume(assets < 10 ** 50);

        uint256 shares = maatVault.convertToShares(assets);
        assertEq(shares, assets);

        _updateOracle(200000000);

        shares = maatVault.convertToShares(assets);
        assertEq(shares, assets / 2);

        _updateOracle(150000000);

        shares = maatVault.convertToShares(assets);
        assertEq(shares, (assets * 10) / 15);
    }

    function testFuzz_ConvertToAssets(uint256 shares) public {
        vm.assume(shares < 10 ** 50);
        vm.assume(shares > 100);

        uint256 assets = maatVault.convertToAssets(shares);
        assertEq(assets, shares);

        _updateOracle(200000000);

        assets = maatVault.convertToAssets(shares);
        assertEq(assets, shares * 2);

        _updateOracle(150000000);

        assets = maatVault.convertToAssets(shares);
        assertEq(assets, (shares * 15) / 10);
    }

    function testFuzz_PreviewDeposit(uint256 assets) public {
        //if assets > 10 ** 69, it will overflow uint
        vm.assume(assets < 10 ** 50);

        uint256 shares = maatVault.previewDeposit(assets);
        assertEq(shares, assets);

        _updateOracle(200000000);

        shares = maatVault.previewDeposit(assets);
        assertEq(shares, assets / 2);

        _updateOracle(150000000);

        shares = maatVault.previewDeposit(assets);
        assertEq(shares, (assets * 10) / 15);
    }

    function testFuzz_PreviewMint(uint256 shares) public {
        //if shares > 10 ** 68, it will overflow uint
        vm.assume(shares < 10 ** 50);

        uint256 assets = maatVault.previewMint(shares);
        assertEq(assets, shares);

        //twice becuase oracle returns last before update value
        _updateOracle(200000000);

        assets = maatVault.previewMint(shares);
        assertEq(assets, shares * 2);

        _updateOracle(150000000);

        assets = maatVault.previewMint(shares);
        assertEq(assets, (shares * 15) / 10);
    }

    function testFuzz_PreviewWithdraw(uint256 assets) public {
        //if assets > 10 ** 69, it will overflow uint
        vm.assume(assets < 10 ** 50);

        uint256 shares = maatVault.previewWithdraw(assets);
        assertEq(shares, assets);

        _updateOracle(200000000);

        shares = maatVault.previewWithdraw(assets);
        assertEq(shares, assets / 2);

        _updateOracle(150000000);

        shares = maatVault.previewWithdraw(assets);
        assertEq(shares, (assets * 10) / 15);
    }

    function testFuzz_PreviewRedeem(uint256 shares) public {
        //if shares > 10 ** 68, it will overflow uint
        vm.assume(shares < 10 ** 50);

        uint256 assets = maatVault.previewRedeem(shares);
        assertEq(assets, shares);

        _updateOracle(200000000);

        assets = maatVault.previewRedeem(shares);
        assertEq(assets, shares * 2);

        _updateOracle(150000000);

        assets = maatVault.previewRedeem(shares);
        assertEq(assets, (shares * 15) / 10);
    }

    function testFuzz_MaxWithdraw(uint256 shares, uint112 PPS) public {
        address user = address(0x1234);
        deal(address(maatVault), user, shares);

        //if shares > 10 ** 58, it will overflow uint
        vm.assume(shares < 10 ** 58);
        vm.assume(PPS > 0 && PPS < 10 ** 18);

        _updateOracle(PPS);

        uint256 assets = maatVault.maxWithdraw(user);
        assertEq(assets, maatVault.convertToAssets(shares));
    }

    function testFuzz_MaxRedeem(uint256 shares) public {
        address user = address(0x1234);
        deal(address(maatVault), user, shares);

        //if shares > 10 ** 68, it will overflow uint
        vm.assume(shares < 10 ** 68);

        assertEq(maatVault.maxRedeem(user), maatVault.balanceOf(user));
    }

    function _updateOracle(uint256 value) internal {
        address[] memory vaultsArray = new address[](1);
        vaultsArray[0] = address(maatVault);

        uint112[] memory ppsArray = new uint112[](1);
        ppsArray[0] = uint112(value);

        skip(1);
        oracle.updateGlobalPPS(vaultsArray, ppsArray);
        skip(1);
        oracle.updateGlobalPPS(vaultsArray, ppsArray);
        skip(1);
    }
}
