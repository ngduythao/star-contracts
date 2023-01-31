// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";

contract CurrencyManagerUpgradeable is ICurrencyManager, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant ERC20_TYPE = 1;
    uint256 public constant ERC721_TYPE = 2;
    address public constant NATIVE_TOKEN = address(0); // The address interpreted as native token of the chain.
    address public treasury;

    // solhint-disable func-name-mixedcase
    function __CurrencyManager_init() internal onlyInitializing {
        __CurrencyManager_init_unchained();
    }

    function __CurrencyManager_init_unchained() internal onlyInitializing {}

    /// @dev Transfers a given amount of currency.
    function _transferCurrency(address currency_, address from_, address to_, uint256 amount_, bool isReceived_) internal {
        if (amount_ == 0) return;

        if (currency_ == NATIVE_TOKEN) {
            if (isReceived_) {
                uint256 nativeValue = msg.value;
                require(nativeValue >= amount_, "Insufficient balance");
                if (nativeValue > amount_) _safeTransferNativeToken(msg.sender, amount_ - nativeValue);
            }
            _safeTransferNativeToken(to_, amount_);
        } else {
            _safeTransferERC20(currency_, from_, to_, amount_);
        }
    }

    function _setTreasury(address treasury_) internal {
        if (address(treasury_) == address(0)) revert Zero();
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function _safeTransferERC20(address currency_, address from_, address to_, uint256 amount_) private {
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
        require(success, "Transfer failed!");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
