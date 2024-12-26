// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {TestUtils} from "../utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";
import "../../src/periphery/LiFiExecutorProxy.sol";

contract LiFiExecutorProxyTestSetup is TestUtils {
    LiFiExecutorProxy proxy;

    IERC20 token = IERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831);
    address executor = address(this);
    address addressProvider = 0x6CA228Aadd078fcf54254F90FA15C85BcFF761dD;
    address vaultUSDC = 0x1f1EeFc9eaa0d3989AbB8F384fDfFA843240eD1e;
    address receiver = address(bytes20("receiver"));

    function setUp() public {
        fork(42161, 280239377);

        proxy = new LiFiExecutorProxy(executor, address(this), addressProvider);

        // Test Contract is an Executor in this tests
        // Following lines simulate behavior of real Executor
        deal(address(token), executor, 1000e6);
        token.approve(address(proxy), type(uint256).max);
    }
}
