// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { FeeCollectors } from "./internal/FeeCollectors.sol";
import { ErrorHandler } from "./libraries/ErrorHandler.sol";

error InvalidTransferInfo();
error NotAuthorized();

contract RewardSplitter is ReentrancyGuard, Initializable, Ownable, FeeCollectors {
    using ErrorHandler for bool;

    bytes4 private constant TRANSFER_SELECTOR = 0xa9059cbb;
    bytes4 private constant BALANCEOF_SELECTOR = 0x70a08231;

    receive() external payable {}

    function initialize(
        address owner_,
        address[] calldata recipients_,
        uint256[] calldata percents_
    ) external initializer {
        _transferOwnership(owner_);
        _configFees(recipients_, percents_);
    }

    // do we really need nonReentrant?
    function slittingRewards(address[] calldata tokens_) external nonReentrant {
        if (!_contain(_msgSender())) revert NotAuthorized();

        uint256 tokensLength = tokens_.length;
        uint256 recipientsLength = _viewRecipientsLength();

        for (uint256 i = 0; i < tokensLength; ) {
            address token = tokens_[i];
            uint256 total = _safeBalanceOf(token, address(this));
            bool isNative = token == address(0);

            for (uint256 j = 0; j < recipientsLength; ) {
                address recipient = _getRecipient(j);
                uint256 amount = (total * _percents[recipient]) / HUNDER_PERCENT;

                if (recipient == address(0) || amount == 0) revert InvalidTransferInfo();

                _safeTransfer(isNative, token, recipient, amount);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function configFees(
        address[] calldata recipients_,
        uint256[] calldata percents_
    ) external onlyOwner {
        _configFees(recipients_, percents_);
    }

    function withdraw(address token_, uint256 amount_) external onlyOwner {
        _safeTransfer(token_ == address(0), token_, _msgSender(), amount_);
    }

    function _safeTransfer(
        bool isNative_,
        address token_,
        address account_,
        uint256 amount_
    ) private {
        bool success;
        bytes memory returnData;

        if (isNative_) {
            (success, returnData) = account_.call{ value: amount_ }("");
        } else {
            (success, returnData) = token_.call(
                abi.encodeWithSelector(TRANSFER_SELECTOR, account_, amount_)
            );
        }

        success.handleRevertIfNotSuccess(returnData);
    }

    function _safeBalanceOf(
        address token_,
        address account_
    ) private view returns (uint256 balance) {
        if (token_ == address(0)) {
            balance = address(account_).balance;
        } else {
            (bool success, bytes memory data) = token_.staticcall(
                abi.encodeWithSelector(BALANCEOF_SELECTOR, account_)
            );
            if (success) {
                return abi.decode(data, (uint256));
            }
            success.handleRevertIfNotSuccess(data);
        }
    }
}
