// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Metadata} from
    "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from
    "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ReentrancyGuard} from
    "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {AddressProviderKeeper} from "../base/AddressProviderKeeper.sol";
import {IMaatVaultV1} from "../../interfaces/IMaatVaultV1.sol";
import {IMaatOracleGlobalPPS} from "../../interfaces/IMaatOracleGlobalPPS.sol";
import {FeeManager} from "./FeeManager.sol";
import {TokenKeeper} from "../base/TokenKeeper.sol";
import {ERC165Registry, IERC165} from "../../lib/ERC165Registry.sol";
import {IntentionGenerator} from "../base/IntentionGenerator.sol";

// Must inherit from most basic ones to most derived contracts!
// Otherwise "Linearization of inheritance graph impossible" will occur
// https://docs.soliditylang.org/en/develop/contracts.html#multiple-inheritance-and-linearization
abstract contract Vault is
    IntentionGenerator,
    Ownable,
    AddressProviderKeeper,
    FeeManager,
    TokenKeeper,
    ERC20,
    IMaatVaultV1,
    ERC165Registry,
    ReentrancyGuard
{
    using Math for uint256;
    using SafeERC20 for ERC20;

    uint256 public minAmount;

    /* ======== ERRORS ======== */

    error UnauthorizedUser(address user);
    error AmountIsTooLow();

    /* ======== CONSTRUCTOR ======== */
    constructor(
        address admin,
        address assetAddress,
        address addressProvider,
        uint256 minAmount_
    )
        Ownable(admin)
        AddressProviderKeeper(addressProvider)
        FeeManager(admin)
        ERC20(_getVaultName(assetAddress), _getVaultSymbol(assetAddress))
    {
        minAmount = minAmount_;

        _registerInterface(type(IERC4626).interfaceId);
    }

    /* ======== EXTERNAL ======== */

    ///@dev function is calling by users to deposit their funds. Do not use it to deposit funds from stargate adapter.
    function deposit(uint256 _assets, address _receiver)
        external
        nonReentrant
        returns (uint256 shares)
    {
        _validateMinAmount(_assets);

        require(_receiver != address(0), "MaatVaultV1: Mint To Zero Address");

        uint256 sharesWithoutFee = convertToShares(_assets);

        (, shares) = _deposit(_assets, sharesWithoutFee, _receiver);
    }

    function mint(uint256 shares, address receiver)
        external
        nonReentrant
        returns (uint256 assets)
    {
        require(receiver != address(0), "MaatVaultV1: Mint To Zero Address");

        uint256 assetsWithoutFee = convertToAssets(shares);

        _validateMinAmount(assetsWithoutFee);

        (assets,) = _deposit(assetsWithoutFee, shares, receiver);
    }

    function withdraw(uint256 _assets, address _receiver, address _owner)
        external
        nonReentrant
        returns (uint256 shares)
    {
        _validateMinAmount(_assets);
        _validateUser(_owner, msg.sender);

        shares = _withdraw(_assets, _receiver, _owner);
    }

    function redeem(uint256 _shares, address _receiver, address _owner)
        public
        nonReentrant
        returns (uint256 assets)
    {
        uint256 assetsWithoutFee = _convertToAssetsByLowerPPS(_shares);

        _validateMinAmount(assetsWithoutFee);
        _validateUser(_owner, msg.sender);

        assets = _redeem(_shares, _receiver, _owner);
    }

    /* ======== INTERNAL FUNCTIONS ======== */

    function _deposit(uint256 assets, uint256 shares, address receiver)
        internal
        returns (uint256 adjustedAssets, uint256 adjustedShares)
    {
        token.safeTransferFrom(msg.sender, address(this), assets);

        adjustedShares = shares - _calculateFee(shares, feeIn());
        adjustedAssets = convertToAssets(adjustedShares);

        _mint(address(this), shares);
        this.transfer(receiver, adjustedShares);
        _sendFee(shares - adjustedShares);
        _increaseIdle(assets);

        bytes32 intentionId = _generateIntentionId();

        emit Deposit(msg.sender, receiver, assets, adjustedShares, intentionId);
    }

    ///@dev burn shares from _owner and transfer assets to _receiver
    function _redeem(uint256 _shares, address _receiver, address _owner)
        internal
        returns (uint256 assets)
    {
        ///@dev if condition is not completed => fulfillRequestWithdraw
        if (_owner != address(this)) {
            this.transferFrom(msg.sender, address(this), _shares);
        }

        uint256 adjustedShares = _shares - _calculateFee(_shares, feeOut());

        assets = _convertToAssetsByLowerPPS(adjustedShares);

        _sendFunds(_receiver, assets, adjustedShares, _shares - adjustedShares);

        emit Withdraw(msg.sender, _receiver, _owner, assets, adjustedShares);
    }

    function _withdraw(uint256 _assets, address _receiver, address _owner)
        internal
        returns (uint256 adjustedShares)
    {
        uint256 shares = _convertToSharesByLowerPPS(_assets);
        adjustedShares = shares + _calculateFee(shares, feeOut());
        this.transferFrom(msg.sender, address(this), adjustedShares);

        _sendFunds(_receiver, _assets, shares, adjustedShares - shares);

        emit Withdraw(msg.sender, _receiver, _owner, _assets, adjustedShares);
    }

    function _sendFunds(
        address _receiver,
        uint256 _assets,
        uint256 _shares,
        uint256 fee
    ) internal {
        _burn(address(this), _shares);

        token.safeTransfer(_receiver, _assets);

        _decreaseIdle(_assets);

        _sendFee(fee);
    }

    /* ====== FEES ====== */

    function _sendFee(uint256 fee) internal {
        if (feeTo() == address(0) || fee == 0) return;

        this.transfer(feeTo(), fee);
    }

    /* ====== ONLY OWNER ====== */

    function setMinAmount(uint256 amount) external onlyOwner {
        minAmount = amount;
    }

    /* ======== VIEWS ======== */

    function _getVaultName(address _asset)
        internal
        view
        returns (string memory)
    {
        //MAAT USDC VAULT
        return string.concat("MAAT ", ERC20(_asset).symbol(), " MaatVaultV1");
    }

    function _getVaultSymbol(address _asset)
        internal
        view
        returns (string memory)
    {
        //mUSDC
        return string.concat("mt", ERC20(_asset).symbol());
    }

    function oracle() public view returns (IMaatOracleGlobalPPS) {
        return IMaatOracleGlobalPPS(addressProvider().oracle());
    }

    function asset() public view returns (address) {
        return address(token);
    }

    function totalAssets() external view virtual returns (uint256) {
        (uint256 pps,) = oracle().getGlobalPPS(address(this));

        return totalSupply().mulDiv(pps, 10 ** oracle().decimals());
    }

    function convertToShares(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToSharesByHigherPPS(assets);
    }

    function convertToSharesByHigherPPS(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        (uint256 prevPPS,) = oracle().getPrevGlobalPPS(address(this));
        (uint256 currentPPS,) = oracle().getGlobalPPS(address(this));

        uint256 higherPPS = prevPPS > currentPPS ? prevPPS : currentPPS;

        return assets.mulDiv(
            10 ** oracle().decimals(), higherPPS, Math.Rounding.Floor
        );
    }

    function _convertToSharesByLowerPPS(uint256 assets)
        internal
        view
        virtual
        returns (uint256)
    {
        (uint256 prevPPS,) = oracle().getPrevGlobalPPS(address(this));
        (uint256 currentPPS,) = oracle().getGlobalPPS(address(this));

        uint256 lowerPPS = prevPPS < currentPPS ? prevPPS : currentPPS;

        return assets.mulDiv(
            10 ** oracle().decimals(), lowerPPS, Math.Rounding.Floor
        );
    }

    /// @dev Default function for IERC4626
    function convertToAssets(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        return _convertToAssetsByHigherPPS(shares);
    }

    /// @dev Used for deposit/mint to protect from sandwich attacks on PPS update
    /// @dev In case of PPS drop, deposit/mint will be processed by higher PPS
    /// @dev to exclude an arbitrage opportunity
    /// @dev this function is counterpart for convertToAssetsByLowerPPS
    function _convertToAssetsByHigherPPS(uint256 shares)
        internal
        view
        virtual
        returns (uint256)
    {
        (uint256 prevPPS,) = oracle().getPrevGlobalPPS(address(this));
        (uint256 currentPPS,) = oracle().getGlobalPPS(address(this));

        uint256 higherPPS = prevPPS > currentPPS ? prevPPS : currentPPS;

        return shares.mulDiv(
            higherPPS, 10 ** oracle().decimals(), Math.Rounding.Floor
        );
    }

    /// @dev Used for redeem/withdraw to protect from sandwich attacks on PPS update
    /// @dev In case of PPS drop, withdraw/redeem will be processed by lower PPS
    /// @dev to exclude an arbitrage opportunity
    /// @dev this function is counterpart for convertToAssets
    function _convertToAssetsByLowerPPS(uint256 shares)
        internal
        view
        virtual
        returns (uint256)
    {
        (uint256 prevPPS,) = oracle().getPrevGlobalPPS(address(this));
        (uint256 currentPPS,) = oracle().getGlobalPPS(address(this));

        uint256 lowerPPS = prevPPS < currentPPS ? prevPPS : currentPPS;

        return shares.mulDiv(
            lowerPPS, 10 ** oracle().decimals(), Math.Rounding.Floor
        );
    }

    function maxDeposit(address) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) external view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxRedeem(address receiver)
        external
        view
        virtual
        returns (uint256)
    {
        return balanceOf(receiver);
    }

    function maxWithdraw(address receiver)
        external
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(balanceOf(receiver));
    }

    function previewDeposit(uint256 assets)
        external
        view
        virtual
        returns (uint256)
    {
        uint256 shares = convertToShares(assets);
        return shares - _calculateFee(shares, feeIn());
    }

    function previewMint(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(shares + _calculateFee(shares, feeIn()));
    }

    function previewWithdraw(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 shares = _convertToSharesByLowerPPS(assets);

        return (shares + _calculateFee(shares, feeOut()));
    }

    function previewRedeem(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        return
            _convertToAssetsByLowerPPS(shares - _calculateFee(shares, feeOut()));
    }

    function decimals()
        public
        view
        override(ERC20, IERC20Metadata)
        returns (uint8)
    {
        return token.decimals();
    }

    /* ======== VALIDATION ======== */

    function _validateUser(address _owner, address sender) internal pure {
        if (_owner != sender) revert UnauthorizedUser(sender);
    }

    function _validateMinAmount(uint256 amount) internal view {
        if (amount < minAmount) revert AmountIsTooLow();
    }
}
