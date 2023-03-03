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

        uint256 rLength = _viewRecipientsLength();
        (address[] memory recipients, uint256[] memory fees) = viewFees();

        assembly {
            let contractAddress := address()
            let recipientSlot
            let feeSlot
            let endLoop
            let total
            let callResult

            if withNative_ {
                total := selfbalance()

                if gt(total, 0) {
                    recipientSlot := add(recipients, 0x20)
                    feeSlot := add(fees, 0x20)

                    for {
                        endLoop := add(recipientSlot, shl(5, rLength))
                    } lt(recipientSlot, endLoop) {
                        recipientSlot := add(recipientSlot, 0x20)
                        feeSlot := add(feeSlot, 0x20)
                    } {
                        callResult := call(
                            gas(),
                            mload(recipientSlot),
                            div(mul(total, mload(feeSlot)), HUNDER_PERCENT),
                            0,
                            0,
                            0,
                            0
                        )
                        if iszero(callResult) {
                            revert(0, 0)
                        }
                    }
                }
            }

            if tokens_.length {
                for {
                    let offset := tokens_.offset
                    endLoop := add(tokens_.offset, shl(5, tokens_.length)) // length * 32
                } lt(offset, endLoop) {
                    offset := add(offset, 0x20)
                } {
                    let mptr := mload(0x40)
                    mstore(mptr, BALANCEOF_SELECTOR)
                    mstore(add(mptr, 0x04), contractAddress)

                    callResult := staticcall(
                        gas(),
                        calldataload(offset),
                        mptr,
                        add(mptr, 0x24),
                        0x00,
                        0x20
                    )
                    if iszero(callResult) {
                        revert(0, 0)
                    }
                    total := mload(0x00)

                    recipientSlot := add(recipients, 0x20)
                    feeSlot := add(fees, 0x20)

                    for {
                        let nestedEnd := add(recipientSlot, shl(5, rLength))
                    } lt(recipientSlot, nestedEnd) {
                        recipientSlot := add(recipientSlot, 0x20)
                        feeSlot := add(feeSlot, 0x20)
                    } {
                        if gt(total, 0) {
                            mptr := mload(0x40)
                            mstore(mptr, TRANSFER_SELECTOR)
                            mstore(add(mptr, 0x04), mload(recipientSlot))
                            mstore(
                                add(mptr, 0x24),
                                div(mul(total, mload(feeSlot)), HUNDER_PERCENT)
                            )

                            callResult := call(
                                gas(),
                                calldataload(offset),
                                0,
                                mptr,
                                add(mptr, 0x44),
                                0,
                                0x20
                            )

                            if iszero(callResult) {
                                revert(0, 0)
                            }
                        }
                    }
                }
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
}
