// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { FactoryUpgradeable } from "./internal-upgradeable/FactoryUpgradeable.sol";
import { IRewardSplitterFactory } from "./interfaces/IRewardSplitterFactory.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";

contract RewardSplitterFactory is
    IRewardSplitterFactory,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    FactoryUpgradeable
{
    using ErrorHandler for bool;

    /// @dev value is the first 4 bytes of keccak256(initialize(address,address[],uint256[]))
    bytes4 private constant INITIALIZE_SELECTOR = 0xff1d5752;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address implement_) external initializer {
        __Factory_init_unchained(implement_);
        __Ownable_init_unchained();
    }

    function setImplement(address implement_) external onlyOwner {
        _setImplement(implement_);
    }

    function createContract(
        address[] calldata recipients_,
        uint256[] calldata percents_
    ) external {
        address instance = _cheapClone(
            bytes32(block.number),
            INITIALIZE_SELECTOR,
            abi.encode(_msgSender(), recipients_, percents_)
        );
        emit NewInstance(instance);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    uint256[50] private __gap;
}
