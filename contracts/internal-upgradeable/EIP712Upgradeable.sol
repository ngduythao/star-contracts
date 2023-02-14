// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    /// @dev value is equal to keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
    bytes32 private constant _TYPE_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 internal _domainSeparator;
    uint256 internal _domainChainId;

    function __EIP712_init(
        string calldata name,
        string calldata version
    ) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(
        string memory name,
        string memory version
    ) internal onlyInitializing {
        _domainChainId = block.chainid;
        _domainSeparator = keccak256(
            abi.encode(
                _TYPE_HASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator, structHash));
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
