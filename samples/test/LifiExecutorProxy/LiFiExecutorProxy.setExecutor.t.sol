// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./_LiFiExecutorProxy.Setup.t.sol";

contract SetExecutor is LiFiExecutorProxyTestSetup {
    address private newExecutor = address(0x123);

    function test_setExecutor_SetsNewExecutor() public {
        proxy.setExecutor(newExecutor);
        assertEq(proxy.executor(), newExecutor, "Executor should be updated");
    }

    function test_setExecutor_OnlyOwnerCanCall() public {
        address nonOwner = address(0x456);
        vm.prank(nonOwner);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));

        proxy.setExecutor(address(0x789));
    }
}
