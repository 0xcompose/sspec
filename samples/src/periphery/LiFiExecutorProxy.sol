// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {MaatVaultV1} from "../core/MaatVaultV1.sol";
import {AddressProviderKeeper} from "../core/base/AddressProviderKeeper.sol";

/// @title LiFiExecutorProxy
/// @notice Proxy contract to deposit assets to Maat Vaults from LiFi Executor
/// @dev This contract is a helper to deposit assets swapped through LiFi
/// @dev LiFi doesn't support depositing arbitrary amount of tokens, so we are forced to use this proxy
contract LiFiExecutorProxy is AddressProviderKeeper, Ownable {
    using SafeERC20 for IERC20;

    address public executor;

    constructor(address _owner, address _executor, address _addressProvider)
        AddressProviderKeeper(_addressProvider)
        Ownable(_owner)
    {
        executor = _executor;
    }

    function deposit(address vault, address _token, address receiver)
        external
        payable
    {
        require(
            msg.sender == executor,
            "LiFiExecutorProxy: Only executor can call this function"
        );

        require(
            addressProvider().isVault(vault),
            "LiFiExecutorProxy: Vault not found"
        );

        require(_token != address(0), "LiFiExecutorProxy: Zero address token");
        require(
            receiver != address(0), "LiFiExecutorProxy: Zero address receiver"
        );

        IERC20 token = IERC20(_token);
        uint256 assets = token.balanceOf(executor);

        token.safeTransferFrom(executor, address(this), assets);

        token.approve(vault, type(uint256).max);

        MaatVaultV1(vault).deposit(assets, receiver);
    }

    function setExecutor(address _executor) external onlyOwner {
        executor = _executor;
    }

    /// @notice Sweep any ERC20 token to the owner
    /// @dev to rescue tokens, just in case of any issues
    function sweep(address token, address receiver) external onlyOwner {
        IERC20(token).safeTransfer(
            receiver, IERC20(token).balanceOf(address(this))
        );
    }
}
