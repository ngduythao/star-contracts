// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IERC4494 } from "../internal-upgradeable/interfaces/IERC4494.sol";

/**
 * @title PermitHelper
 * @notice This library allows verification of permit
 */
library PermitHelper {
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    function permit(address asset_, uint256 assetValue_, uint256 deadline_, bytes calldata permitSignature_) internal {
        if ((IERC165Upgradeable(asset_).supportsInterface(INTERFACE_ID_ERC721))) {
            IERC4494(asset_).permit(address(this), assetValue_, deadline_, permitSignature_);
        } else {
            (bytes32 r, bytes32 s, uint8 v) = _splitSignature(permitSignature_);
            IERC20PermitUpgradeable(asset_).permit(msg.sender, address(this), assetValue_, deadline_, v, r, s);
        }
    }

    function _splitSignature(bytes calldata signature_) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature_.length == 65, "invalid signature length");

        // solhint-disable no-inline-assembly
        assembly {
            r := calldataload(signature_.offset)
            s := calldataload(add(signature_.offset, 0x20))
            v := byte(0, calldataload(add(signature_.offset, 0x40)))
        }
    }
}
