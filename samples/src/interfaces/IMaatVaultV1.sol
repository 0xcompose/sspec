// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IExecutor} from "./IExecutor.sol";

interface IMaatVaultV1 is IExecutor, IERC4626 {
    /// @notice Data for PPS calculation
    /// @dev totalSupply = realSupply + virtualSupply (counter for bridges)
    /// @dev totalAssets = realAssets + virtualAssets (counter for bridges)
    /// @dev virtual variables can go negative
    struct PPSData {
        int256 totalAssets;
        int256 totalSupply;
    }

    function finishSharesBridge(address account, uint256 value) external;

    function bridgeShares(
        uint32 _dstEid,
        uint256 _amount,
        bytes calldata options
    ) external payable;
}
