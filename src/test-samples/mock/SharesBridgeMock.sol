// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMaatSharesBridge} from "../../src/interfaces/IMaatSharesBridge.sol";
import {AddressProviderKeeper} from
    "../../src/core/base/AddressProviderKeeper.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMaatVaultV1} from "../../src/interfaces/IMaatVaultV1.sol";

contract SharesBridgeMock is IMaatSharesBridge, AddressProviderKeeper {
    /// @notice sends token to StargateAdapter on destination chain
    using SafeERC20 for ERC20;

    uint256 public fees;

    event SendTokens(
        uint32 dstEid, address token, uint256 amount, bytes32 intentionId
    );

    mapping(uint32 eid => address vault) eidToVault;

    constructor(address _addressProvider)
        AddressProviderKeeper(_addressProvider)
    {}

    function bridge(
        uint32 _dstEid,
        BridgeData memory data,
        bytes calldata _options
    ) external payable onlyMaatVault {
        // Encode the data before invoking _lzSend.
        bytes memory _payload = abi.encode(data);

        // MessagingReceipt memory _receipt = _lzSend(
        //     _dstEid,
        //     _payload,
        //     _options,
        //     MessagingFee(msg.value, 0),
        //     data.user
        // );

        emit SendShares(
            bytes32(0),
            data.user,
            msg.sender,
            data.targetVault,
            data.amount,
            _dstEid
        );

        _lzReceive(_payload);
    }

    function _lzReceive(
        // Origin calldata _origin,
        // bytes32 _guid,
        bytes memory payload
    ) internal 
    // address _executor, // Executor address as specified by the OApp.
    // bytes calldata _extraData // Any extra data or options to trigger on receipt.
    {
        // Decode the payload to get the message
        // In this case, type is string, but depends on your encoding!
        BridgeData memory data = abi.decode(payload, (BridgeData));

        IMaatVaultV1(data.targetVault).finishSharesBridge(
            data.user, data.amount
        );

        emit ReceiveShares(bytes32(0), data.user, data.targetVault, data.amount);
    }

    function setPeer(uint32 eid, address vault) external {
        eidToVault[eid] = vault;
    }

    modifier onlyMaatVault() {
        if (!addressProvider().isVault(msg.sender)) revert NotMaatVault();

        _;
    }
}
