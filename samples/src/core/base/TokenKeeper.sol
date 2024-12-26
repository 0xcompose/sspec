// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenKeeper {
    using SafeERC20 for ERC20;

    ERC20 public immutable token;

    uint256 private _idle;

    /// @notice Feature for new Oracle
    /// @dev This is a virtual counter of assets that is used to calculate totalAssets
    /// @dev this variable is made to account for inflight bridges
    /// @dev it's increased on bridge departure and decreased on bridge arrival
    /// @dev on bridge arrival we decrease virtualAssets by amount of tokens that were bridged
    /// @dev also we decrease virtualAssets by amount of fees that were paid for the bridge
    /// @dev can be negative due to specific chain to be more popular bridge destination
    int256 private _virtualAssets;

    // Vault Total Assets = realAssets + virtualAssets
    // Global Total Assets = sum of all Vault's Total Assets

    constructor(address _token) {
        token = ERC20(_token);
    }

    function _increaseVirtualAssets(uint256 value) internal virtual {
        _virtualAssets += int256(value);
    }

    function _decreaseVirtualAssets(uint256 value) internal virtual {
        _virtualAssets -= int256(value);
    }

    function _increaseIdle(uint256 value) internal virtual {
        _idle += value;
    }

    function _decreaseIdle(uint256 value) internal virtual {
        require(
            value <= _idle,
            "MaatVaultV1: Arithmetic error during idle calculations"
        );
        _idle -= value;
    }

    function idle() public view virtual returns (uint256) {
        return _idle;
    }

    function virtualAssets() public view returns (int256) {
        return _virtualAssets;
    }
}
