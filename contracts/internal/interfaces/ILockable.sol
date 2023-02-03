// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ILockable {
    function isLocked(address account) external view returns (bool);

    event NewUserStatus(address indexed operator, address indexed account, bool indexed status);
}
