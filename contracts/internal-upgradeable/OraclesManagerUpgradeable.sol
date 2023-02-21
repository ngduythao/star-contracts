// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSet } from "../libraries/EnumerableSet.sol";
import { IOraclesManager } from "./interfaces/IOraclesManager.sol";

/// @dev The base contract for oracles management. Allows adding/removing oracles,
/// managing the minimal number oracles for the confirmations.
contract OraclesManagerUpgradeable is IOraclesManager, Initializable, OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;
    /* ========== STATE VARIABLES ========== */

    uint8 internal _threshHold;
    EnumerableSet.AddressSet private _oracleAddresses;

    function __OraclesManager_init(
        uint8 threshold_,
        address[] calldata oracles_
    ) internal onlyInitializing {
        __OraclesManager_init_unchained(threshold_, oracles_);
    }

    function __OraclesManager_init_unchained(
        uint8 threshold_,
        address[] calldata oracles_
    ) internal onlyInitializing {
        __Ownable_init_unchained();
        _setThreshhold(threshold_);
        _addOracles(oracles_);
    }

    /* ========== ADMIN ========== */

    function setThreshhold(uint8 threshold_) external onlyOwner {
        _setThreshhold(threshold_);
    }

    function addOracles(address[] calldata oracles_) external onlyOwner {
        _addOracles(oracles_);
    }

    function removeOracle(address oracle_) external onlyOwner {
        _removeOracle(oracle_);
    }

    function _setThreshhold(uint8 threshold_) internal {
        if (threshold_ == 0) revert LowThreshold();
        _threshHold = threshold_;
    }

    function _addOracles(address[] calldata oracles_) internal {
        uint256 length = oracles_.length;

        for (uint256 i; i < length; ) {
            if (!_oracleAddresses.add(oracles_[i])) revert OracleAlreadyExist();

            unchecked {
                ++i;
            }
        }
        emit AddOracles(oracles_);
    }

    function _removeOracle(address oracle_) internal {
        if (!_oracleAddresses.remove(oracle_)) revert OracleNotFound();
        emit RemoveOracle(oracle_);
    }

    /* ========== VIEW ========== */

    function threshHold() external view returns (uint8) {
        return _threshHold;
    }

    function isValidOracle(address oracle) external view override returns (bool) {
        return _isValidOracle(oracle);
    }

    function viewCountOracles() external view override returns (uint256) {
        return _viewCountOracles();
    }

    function viewOracles() external view override returns (address[] memory, uint256) {
        return (_oracleAddresses.values(), _oracleAddresses.length());
    }

    function _viewCountOracles() internal view returns (uint256) {
        return _oracleAddresses.length();
    }

    function _isValidOracle(address oracle) internal view returns (bool) {
        return _oracleAddresses.contains(oracle);
    }

    function _indexOf(address oracle) internal view returns (uint256) {
        return _oracleAddresses.indexOf(oracle);
    }

    uint256[48] private __gap;
}
