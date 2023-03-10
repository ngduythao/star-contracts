// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {
    ClonesUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ErrorHandler } from "../libraries/ErrorHandler.sol";

abstract contract FactoryUpgradeable is Initializable {
    using ErrorHandler for bool;
    using ClonesUpgradeable for address;

    address public implementation;
    address[] private _clones;

    mapping(bytes32 => address) private _instances;

    function getContracts() external view returns (address[] memory) {
        return _clones;
    }

    function getInstance(bytes32 salt_) external view returns (address) {
        return _instances[salt_];
    }

    function __Factory_init(address implement_) internal onlyInitializing {}

    function __Factory_init_unchained(address implement_) internal onlyInitializing {
        _setImplement(implement_);
    }

    function _setImplement(address implement_) internal {
        implementation = implement_;
    }

    function _cheapClone(
        bytes32 salt_,
        bytes4 selector_,
        bytes memory args_
    ) internal returns (address clone) {
        clone = implementation.cloneDeterministic(salt_);
        (bool success, bytes memory revertData) = clone.call(abi.encodePacked(selector_, args_));
        if (!success) {
            success.handleRevertIfNotSuccess(revertData);
        }
        _instances[salt_] = clone;
        _clones.push(clone);
    }

    uint256[47] private __gap;
}
