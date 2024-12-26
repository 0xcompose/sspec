// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "../../src/core/MaatVaultV1.sol";
import "../../src/interfaces/IExecutor.sol";
import {MaatAddressProviderV1 as AddressProvider} from
    "../../src/periphery/MaatAddressProviderV1.sol";

import {
    YearnV3Strategy,
    Strategy
} from "maat-strategies/contracts/strategies/Yearn/YearnV3Strategy.sol";
import {IStrategy as IStrategyFromStrategies} from
    "maat-strategies/contracts/interfaces/IStrategy.sol";

contract MaatVaultHarness is MaatVaultV1 {
    constructor(
        address _owner,
        address _token,
        uint256 _minAmount,
        address _addressProvider,
        address commander,
        address watcher,
        uint32 chainEid
    )
        MaatVaultV1(
            _owner,
            _token,
            _minAmount,
            _addressProvider,
            commander,
            watcher,
            chainEid
        )
    {}

    function depositInStrategy(
        bytes32 _strategyId,
        uint256 _amount,
        bytes32 _intentionId
    ) public {
        super._depositToStrategy(_strategyId, _amount, _intentionId);
    }

    function withdrawFromStrategy(
        bytes32 _strategyId,
        uint256 _amount,
        bytes32 _intentionId
    ) public {
        super._withdrawFromStrategy(_strategyId, _amount, _intentionId);
    }

    function bridge(uint256 _amount, uint256 _chainId, bytes32 intentionId)
        public
    {
        super._bridge(_amount, uint32(_chainId), intentionId);
    }

    function bridgeToUser(uint256 amount, address _receiver, uint32 dstEid)
        external
    {
        super._bridgeToUser(amount, _receiver, dstEid);
    }

    function convertToAssetsByLowerPPS(uint256 shares)
        public
        view
        returns (uint256)
    {
        return super._convertToAssetsByLowerPPS(shares);
    }

    function convertToSharesByLowerPPS(uint256 assets)
        public
        view
        returns (uint256)
    {
        return super._convertToSharesByLowerPPS(assets);
    }

    function calculateFee(uint256 amount, uint112 fee)
        public
        view
        returns (uint256)
    {
        return super._calculateFee(amount, fee);
    }

    function setNonce(uint256 _nonce) public {
        _nonces[tx.origin] = _nonce;
    }

    function getIntentionId(uint256 _nonce) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        return keccak256(
            abi.encodePacked(
                address(this), tx.origin, _nonces[tx.origin], chainId
            )
        );
    }

    // Overridden Idle calculations for tests

    uint256 internal idle_;

    function idle() public view override returns (uint256) {
        return idle_;
    }

    function _increaseIdle(uint256 value) internal virtual override {
        idle_ += value;
    }

    function _decreaseIdle(uint256 value) internal virtual override {
        require(
            value <= idle_,
            "MaatVaultV1: Arithmetic error during idle calculations"
        );
        idle_ -= value;
    }

    function setIdle(uint256 amount) public {
        idle_ = amount;
    }

    /* ======== PPS DATA SETTERS ======== */

    /* ======== VIRTUAL ASSETS SETTERS ======== */

    function increaseVirtualAssets(uint256 value) public {
        _increaseVirtualAssets(value);
    }

    function decreaseVirtualAssets(uint256 value) public {
        _decreaseVirtualAssets(value);
    }

    /* ======== VIRTUAL SUPPLY SETTERS ======== */

    function increaseVirtualSupply(uint256 value) public {
        virtualSupply += int256(value);
    }

    function decreaseVirtualSupply(uint256 value) public {
        virtualSupply -= int256(value);
    }
}

contract VaultUtils {
    function _setUpStrategy(
        string memory _protocolName,
        address protocolVault,
        address token,
        address addressProvider,
        address feeTo,
        uint256 performanceFee
    ) internal returns (YearnV3Strategy) {
        IStrategyFromStrategies.StrategyParams memory strategyParams =
        IStrategyFromStrategies.StrategyParams(
            42161, _protocolName, 3, token, protocolVault
        );

        return new YearnV3Strategy(
            strategyParams, addressProvider, feeTo, performanceFee
        );
    }

    function _depositToStrategy(
        MaatVaultHarness vault,
        address strategy,
        uint256 amountToDeposit
    ) internal {
        IExecutor.ActionType[] memory actionType = new IExecutor.ActionType[](1);
        actionType[0] = IExecutor.ActionType.DEPOSIT;

        IExecutor.ActionInput[] memory input = new IExecutor.ActionInput[](1);

        input[0] = IExecutor.ActionInput({
            dstEid: 0,
            strategyId: Strategy(strategy).getStrategyId(),
            amount: amountToDeposit,
            intentionId: bytes32(0)
        });

        vault.execute(actionType, input);
    }

    function _withdrawFromStrategy(
        MaatVaultHarness vault,
        address strategy,
        uint256 amountToWithdraw
    ) internal {
        IExecutor.ActionType[] memory actionType = new IExecutor.ActionType[](1);
        actionType[0] = IExecutor.ActionType.WITHDRAW;

        IExecutor.ActionInput[] memory input = new IExecutor.ActionInput[](1);

        input[0] = IExecutor.ActionInput({
            dstEid: 0,
            strategyId: Strategy(strategy).getStrategyId(),
            amount: amountToWithdraw,
            intentionId: bytes32(0)
        });

        vault.execute(actionType, input);
    }
}
