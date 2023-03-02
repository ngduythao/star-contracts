// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { FeeCollectors } from "./internal/FeeCollectors.sol";
import { IRewardSplitter } from "./interfaces/IRewardSplitter.sol";

contract RewardSplitter is IRewardSplitter, Initializable, Ownable, FeeCollectors {
    bytes32 private constant TRANSFER_SELECTOR =
        0xa9059cbb00000000000000000000000000000000000000000000000000000000;
    bytes32 private constant BALANCEOF_SELECTOR =
        0x70a0823100000000000000000000000000000000000000000000000000000000;

    receive() external payable {}

    function initialize(
        address owner_,
        address[] calldata recipients_,
        uint256[] calldata percents_
    ) external initializer {
        _transferOwnership(owner_);
        _configFees(recipients_, percents_);
    }

    // do we really need a nonReentrant modifier?
    function slittingRewards(address[] calldata tokens_, bool withNative_) external override {
        if (!_contain(_msgSender())) revert NotAuthorized();

        uint256 tokensLength = tokens_.length;
        uint256 rLength = _viewRecipientsLength();
        uint256 total;
        uint256 i;
        uint256 j;
        uint256 result;
        (address[] memory recipients, uint256[] memory fees) = viewFees();

        if (withNative_) {
            assembly {
                total := selfbalance()
                let recipientSlot := add(recipients, 0x20)
                let feeSlot := add(fees, 0x20)

                for {
                    let end := add(recipientSlot, shl(5, rLength))
                } lt(recipientSlot, end) {
                    recipientSlot := add(recipientSlot, 0x20)
                    feeSlot := add(feeSlot, 0x20)
                } {
                    result := call(
                        gas(),
                        mload(recipientSlot),
                        div(mul(total, mload(feeSlot)), HUNDER_PERCENT),
                        0,
                        0,
                        0,
                        0
                    )
                    if iszero(result) {
                        revert(0, 0)
                    }
                }
            }
        }

        for (i = 0; i < tokensLength; ) {
            total = _safeBalanceOf(tokens_[i], address(this));
            for (j = 0; j < rLength; ) {
                _safeTransferToken(tokens_[i], recipients[i], (total * fees[i]) / HUNDER_PERCENT);
                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        emit RewardsSplitted();
    }

    function configFees(
        address[] calldata recipients_,
        uint256[] calldata percents_
    ) external override onlyOwner {
        _configFees(recipients_, percents_);
    }

    function withdraw(address token_, address account_, uint256 amount_) external onlyOwner {
        if (token_ == address(0)) {
            _safeTransferNative(account_, amount_);
        } else {
            _safeTransferToken(token_, account_, amount_);
        }
    }

    function _safeTransferNative(address account_, uint256 amount_) private {
        if (amount_ == 0) return;

        assembly {
            let s := call(gas(), account_, amount_, 0, 0, 0, 0)
            if iszero(s) {
                revert(0, 0)
            }
        }
    }

    function _safeTransferToken(
        address token_,
        address account_,
        uint256 amount_
    ) private returns (bool success) {
        if (amount_ == 0) return true;

        assembly {
            let mptr := mload(0x40)
            mstore(mptr, TRANSFER_SELECTOR)
            mstore(add(mptr, 0x04), account_)
            mstore(add(mptr, 0x24), amount_)

            success := call(gas(), token_, 0, mptr, add(mptr, 0x44), 0, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            success := mload(0x00)
        }
    }

    function _safeBalanceOf(
        address token_,
        address account_
    ) private view returns (uint256 result) {
        assembly {
            let mptr := mload(0x40)
            mstore(mptr, BALANCEOF_SELECTOR)
            mstore(add(mptr, 0x04), account_)

            let success := staticcall(gas(), token_, mptr, add(mptr, 0x24), 0x00, 0x20)
            if iszero(success) {
                revert(0, 0)
            }
            result := mload(0x00)
        }
    }
}
