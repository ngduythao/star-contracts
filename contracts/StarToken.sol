// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import { IStarToken } from "./interfaces/IStarToken.sol";
import { Lockable } from "./internal/Lockable.sol";

contract SToken is IStarToken, AccessControl, Pausable, ERC20, ERC20Burnable, ERC20Permit, Lockable {
    /// @dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 private constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    /// @dev value is equal to keccak256("MINTER_ROLE")
    bytes32 private constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;

    constructor() payable Pausable() ERC20("SToken", "S") ERC20Permit("StarToken") {
        address sender = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(MINTER_ROLE, sender);
        //_grantRole(MINTER_ROLE, sender);
        _mint(sender, 1_000_000 ether);
    }

    function setLockUser(address account_, bool status_) external onlyRole(OPERATOR_ROLE) {
        _setLockUser(account_, status_);
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function mint(address to_, uint256 amount_) external onlyRole(MINTER_ROLE) {
        _mint(to_, amount_);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        _notLocked(_msgSender(), from, to);
        super._beforeTokenTransfer(from, to, amount);
    }
}
