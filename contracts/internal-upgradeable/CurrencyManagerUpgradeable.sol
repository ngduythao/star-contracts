// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    AddressUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {
    IERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    SafeERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { IERC20PermitUpgradeable } from "./interfaces/IERC20PermitUpgradeable.sol";
import { IERC4494Upgradeable } from "./interfaces/IERC4494Upgradeable.sol";
import { IERC721Upgradeable } from "./interfaces/IERC721Upgradeable.sol";
import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";
import { PermitHelper } from "../libraries/PermitHelper.sol";

contract CurrencyManagerUpgradeable is ICurrencyManager, Initializable {
    using PermitHelper for address;
    using AddressUpgradeable for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant NATIVE_TOKEN = address(0); // The address interpreted as native token of the chain.

    function __CurrencyManager_init() internal onlyInitializing {
        __CurrencyManager_init_unchained();
    }

    function __CurrencyManager_init_unchained() internal onlyInitializing {}

    /**
     * @notice Transfer NFT
     * @param collection_ address of the token collection
     * @param from_ address of the sender
     * @param to_ address of the recipient
     * @param tokenId_ tokenId
     */
    function _transferNonFungibleToken(
        address collection_,
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 deadline_,
        bytes calldata permitSignature_
    ) internal {
        if (permitSignature_.length != 0)
            collection_.permit(tokenId_, deadline_, permitSignature_);

        IERC721Upgradeable(collection_).safeTransferFrom(from_, to_, tokenId_);
        if (_safeOwnerOf(collection_, tokenId_) != to_) revert NotReceivedERC721();
    }

    /// @dev Transfers a given amount of currency.
    function _receiveNative(uint256 amount_) internal {
        uint256 refund = msg.value - amount_; // throw error if msg.value < amount
        if (refund == 0) return;
        _safeTransferNativeToken(msg.sender, refund);
    }

    /// @dev Transfers a given amount of currency.
    function _transferCurrency(
        address currency_,
        address from_,
        address to_,
        uint256 amount_
    ) internal {
        if (amount_ == 0) return;

        if (currency_ == NATIVE_TOKEN) {
            _safeTransferNativeToken(to_, amount_);
        } else {
            _safeTransferERC20(currency_, from_, to_, amount_);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function _safeTransferERC20(
        address currency_,
        address from_,
        address to_,
        uint256 amount_
    ) private {
        if (from_ == to_) return;

        if (from_ == address(this)) {
            IERC20Upgradeable(currency_).safeTransfer(to_, amount_);
        } else {
            IERC20Upgradeable(currency_).safeTransferFrom(from_, to_, amount_);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function _safeTransferNativeToken(address to_, uint256 value_) private {
        if (to_ == address(this)) return;
        // solhint-disable avoid-low-level-calls
        // slither-disable-next-line low-level-calls
        (bool success, ) = to_.call{ value: value_ }("");
        require(success, "!TF");
    }

    function _safeOwnerOf(address token_, uint256 tokenId_) private view returns (address owner) {
        (bool success, bytes memory data) = token_.staticcall(
            abi.encodeCall(IERC721Upgradeable.ownerOf, (tokenId_))
        );
        if (success) {
            owner = abi.decode(data, (address));
        }
    }

    function _safeBalanceOf(
        address account_,
        address token_
    ) private view returns (uint256 balance) {
        if (token_ == NATIVE_TOKEN) {
            balance = address(account_).balance;
        } else {
            (bool success, bytes memory data) = token_.staticcall(
                abi.encodeCall(IERC20Upgradeable.balanceOf, (account_))
            );
            if (success) {
                balance = abi.decode(data, (uint256));
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
