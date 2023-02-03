// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IStarToken {
    function pause() external;

    function unpause() external;

    function mint(address to_, uint256 amount_) external;

    function setLockUser(address account_, bool status_) external;
}
