// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { ILockable } from "./interfaces/ILockable.sol";

import { BitMaps } from "../libraries/BitMaps.sol";
import { Bytes32Address } from "../libraries/Bytes32Address.sol";

error Lockable__Locked();

abstract contract Lockable is ILockable {
    using Bytes32Address for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _isLocked;

    function isLocked(address account) external view returns (bool) {
        return _isLocked.get(account.fillLast96Bits());
    }

    function _notLocked(address sender_, address from_, address to_) internal view virtual {
        if (_isLocked.get(sender_.fillLast96Bits()) || _isLocked.get(from_.fillLast96Bits()) || _isLocked.get(to_.fillLast96Bits())) revert Lockable__Locked();
    }

    function _setLockUser(address account_, bool status_) internal {
        _isLocked.setTo(account_.fillLast96Bits(), status_);

        emit NewUserStatus(msg.sender, account_, status_);
    }
}
