// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./_LiFiExecutorProxy.Setup.t.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract Sweep is LiFiExecutorProxyTestSetup {
    function test_SweepsERC20Tokens() public {
        uint256 initialBalance = token.balanceOf(receiver);
        uint256 amountToSweep = 500e6; // 500 USDC

        deal(address(token), address(proxy), amountToSweep);

        proxy.sweep(address(token), receiver);

        uint256 finalBalance = token.balanceOf(receiver);
        assertEq(finalBalance, initialBalance + amountToSweep, "Receiver should receive the swept tokens");
    }

    function test_OnlyOwnerCanCall() public {
        address nonOwner = address(0x123);

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        proxy.sweep(address(token), receiver);
    }
}
