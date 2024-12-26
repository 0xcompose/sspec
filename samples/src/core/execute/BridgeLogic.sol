// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {AddressProviderKeeper} from "../base/AddressProviderKeeper.sol";
import {TokenKeeper} from "../base/TokenKeeper.sol";
import {IBridgeLogic} from "../../interfaces/IExecutor.sol";
import {IStargateAdapter} from "../../interfaces/IStargateAdapter.sol";
import {RelatedVaultManager} from "../base/RelatedVaultManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BridgeLogic is
    Ownable,
    AddressProviderKeeper,
    TokenKeeper,
    RelatedVaultManager,
    IBridgeLogic
{
    /* ======== STATE ======== */

    using SafeERC20 for ERC20;

    /* ======== EXTERNAL/PUBLIC ======== */

    function stargateAdapter() public view returns (IStargateAdapter) {
        return IStargateAdapter(addressProvider().stargateAdapter());
    }

    ///@dev called by stargate adapter to receive tokens
    function finishBridge(
        uint256 amountBridged,
        uint256 feesPaid,
        uint32 originEid,
        bytes32 intentionId
    ) external onlyStargateAdapter {
        _finishBridge(amountBridged, feesPaid);

        emit BridgeFinished(amountBridged, originEid, intentionId);
    }

    /// @dev supposed to be called only by stargate adapter
    function _finishBridge(uint256 amountBridged, uint256 feesPaid) internal {
        token.safeTransferFrom(msg.sender, address(this), amountBridged);

        _increaseIdle(amountBridged);

        _decreaseVirtualAssets(amountBridged + 2 * feesPaid);
    }

    /* ======== INTERNAL ======== */

    function _bridge(uint256 _amount, uint32 dstEid, bytes32 intentionId)
        internal
    {
        IStargateAdapter _stargateAdapter = stargateAdapter();

        token.safeIncreaseAllowance(address(_stargateAdapter), _amount);

        _decreaseIdle(_amount);
        _increaseVirtualAssets(_amount);

        _stargateAdapter.sendTokens(
            getRelatedVault(dstEid),
            dstEid,
            address(token),
            _amount,
            intentionId
        );

        emit Bridged(uint32(dstEid), address(token), _amount, intentionId);
    }

    function _bridgeToUser(uint256 amount, address _receiver, uint32 dstEid)
        internal
    {
        IStargateAdapter _stargateAdapter = stargateAdapter();

        token.safeIncreaseAllowance(address(_stargateAdapter), amount);

        //Idle is not changing because it is changed before
        _stargateAdapter.sendTokensToReceiver(
            dstEid, address(token), amount, _receiver
        );
    }

    /* ======== MODIFIERS ======== */

    modifier onlyStargateAdapter() {
        require(
            msg.sender == address(stargateAdapter()),
            "MaatVaultV1: Caller is not stargate adapter"
        );
        _;
    }
}
