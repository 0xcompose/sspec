// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "../mock/SharesBridgeMock.sol";

import "../utils.sol";
import "./_.Vault.Utils.sol";
import "../mock/StargateAdapterMock.sol";
import "../../src/core/vault/Vault.sol";
import {MaatOracleGlobalPPS} from "../../src/periphery/MaatOracleGlobalPPS.sol";
import {MaatAddressProviderV1} from "src/periphery/MaatAddressProviderV1.sol";

/* ======== INTERFACES ======== */

import "../../src/interfaces/IExecutor.sol";
import "../../src/interfaces/IMaatVaultV1.sol";

contract MaatVaultTestSetup is TestUtils, VaultUtils {
    // Arbitrum
    uint32 public chainId = 42161;
    uint256 public forkBlockNumber = 222806410;

    MaatVaultHarness maatVault;
    MaatOracleGlobalPPS oracle;
    Strategy strategy;

    address commander = address(0xad);
    address watcher = address(0xdae);

    MaatAddressProviderV1 addressProvider;

    // USDT Arb
    address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    ERC20 public token = ERC20(USDT);

    address feeTo = address(0xdeadbeef);
    uint256 performanceFee = 2 * 10 ** 7;

    address yearnUSDTVault = 0xc0ba9bfED28aB46Da48d2B69316A3838698EF3f5;

    address admin = address(this);

    bytes32 strategyId;
    uint256 amountMin = 100;

    uint32 sourceEid = 1;
    uint32 targetEid = 2;

    uint112 initialPPS = 10 ** 8;

    function setUp() public virtual {
        fork(chainId, forkBlockNumber);

        /* ======== ADDRESS PROVIDER SETUP ======== */

        addressProvider = new MaatAddressProviderV1();
        addressProvider.initialize(admin);

        /* ======== VAULT SETUP ======== */

        maatVault = new MaatVaultHarness(
            address(this),
            address(token),
            amountMin,
            address(addressProvider),
            commander,
            watcher,
            sourceEid
        );

        addressProvider.addVault(address(maatVault));

        /* ======== HANDLE TOKENS ======== */

        deal(address(token), address(this), 1_000_000e6);

        token.approve(address(maatVault), 1_000_000e6);

        /* ======== STRATEGY SETUP ======== */

        YearnV3Strategy yearnV3Strategy = _setUpStrategy(
            "YEARN FINANCE",
            yearnUSDTVault,
            address(token),
            address(addressProvider),
            feeTo,
            performanceFee
        );

        strategy = Strategy(yearnV3Strategy);

        strategyId = strategy.getStrategyId();

        addressProvider.addStrategy(address(strategy));

        maatVault.addStrategy(address(strategy));

        /* ======== ORACLE SETUP ======== */

        oracle = new MaatOracleGlobalPPS(
            admin,
            10 ** 20, // Recommended value = 116 and it equals to 10% change per day
            address(addressProvider)
        );

        addressProvider.changeOracle(address(oracle));

        oracle.initPPS(address(maatVault), initialPPS, initialPPS);

        /* ======== MISC SETUP ======== */

        maatVault.setFees(0, 0);
        // Used to be able to use deal(address(token), address(maatVault), amount) in tests
        // instead of making deposit()
        maatVault.setIdle(10 ** 70);

        /* ======== LABELS ======== */

        vm.label(USDT, "USDT Proxy");
        vm.label(0xf31e1AE27e7cd057C1D6795a5a083E0453D39B50, "USDT");
        vm.label(yearnUSDTVault, "Yearn USDT Vault");

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {}

    function _setupMultipleStrategiesOnVault(
        MaatVaultHarness vault,
        uint256 numberOfStrategies
    ) internal returns (YearnV3Strategy[] memory) {
        YearnV3Strategy[] memory strategies =
            new YearnV3Strategy[](numberOfStrategies);

        // Setup 10 strategies and add them to Vault
        for (uint256 i = 0; i < numberOfStrategies; i++) {
            YearnV3Strategy strategy = _setUpStrategy(
                string.concat("Strategy ", Strings.toHexString(i)),
                yearnUSDTVault,
                address(token),
                address(addressProvider),
                feeTo,
                performanceFee
            );

            // Add strategy to Vault
            strategies[i] = strategy;
            addressProvider.addStrategy(address(strategy));
            vault.addStrategy(address(strategy));
        }

        return strategies;
    }

    function _setupTargetVault()
        internal
        returns (MaatVaultHarness targetVault)
    {
        // Deploy second vault to test bridge arrival
        targetVault = new MaatVaultHarness(
            address(this),
            address(token),
            amountMin,
            address(addressProvider),
            commander,
            watcher,
            targetEid
        );

        addressProvider.addVault(address(targetVault));

        address[] memory vaults = new address[](1);
        vaults[0] = address(targetVault);
        uint32[] memory eids = new uint32[](1);
        eids[0] = targetEid;

        maatVault.addRelatedVaults(eids, vaults);
    }

    function _setupSharesBridge()
        internal
        returns (SharesBridgeMock sharesBridgeMock)
    {
        sharesBridgeMock = new SharesBridgeMock(address(addressProvider));
        addressProvider.changeSharesBridge(address(sharesBridgeMock));
    }

    function _labelContracts() internal {
        vm.label(USDT, "USDT Proxy");
        // vm.label(address(token), "USDT");
        vm.label(address(maatVault), "MaatVaultV1");
        vm.label(address(oracle), "Oracle");
        vm.label(address(strategy), "Strategy");
    }
}
