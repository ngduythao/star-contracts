// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { EnumerableSet } from "../libraries/EnumerableSet.sol";

error LengthMisMatch();
error InvalidRecipient();

contract FeeCollectors {
    event FeeUpdated();

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant HUNDER_PERCENT = 10_000; // 100%
    EnumerableSet.AddressSet internal _feeRecipients;
    mapping(address => uint256) internal _percents;

    function _configFees(address[] calldata recipients_, uint256[] calldata percents_) internal {
        uint256 length = recipients_.length;
        if (percents_.length != length) revert LengthMisMatch();

        for (uint256 i = 0; i < length; ) {
            if (recipients_[i] == address(0)) revert InvalidRecipient();
            if (percents_[i] != 0) {
                _feeRecipients.add(recipients_[i]); // whether exists or not
                _percents[recipients_[i]] = percents_[i];
            } else {
                _feeRecipients.remove(recipients_[i]);
            }

            unchecked {
                i++;
            }
        }

        emit FeeUpdated();
    }

    function viewFees()
        external
        view
        returns (address[] memory recipients, uint256[] memory fees)
    {
        uint256 length = _feeRecipients.length();
        fees = new uint256[](length);

        for (uint256 i = 0; i < length; ) {
            fees[i] = _percents[_feeRecipients.at(i)];
            unchecked {
                ++i;
            }
        }
        return (_feeRecipients.values(), fees);
    }

    function _viewRecipientsLength() internal view returns (uint256) {
        return _feeRecipients.length();
    }

    function _getRecipient(uint256 index) internal view returns (address) {
        return _feeRecipients.at(index);
    }

    function _contain(address recipient) internal view returns (bool) {
        return _feeRecipients.contains(recipient);
    }
}
