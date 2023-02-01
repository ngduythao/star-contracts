// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity 0.8.17;

import { ERC721Upgradeable, StringsUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    using StringsUpgradeable for uint256;

    string internal _baseUri;

    /* solhint-disable func-name-mixedcase */
    function __ERC721URIStorage_init(string calldata baseUri_) internal onlyInitializing {
        __ERC721URIStorage_init_unchained(baseUri_);
    }

    /* solhint-disable func-name-mixedcase */
    function __ERC721URIStorage_init_unchained(string calldata baseUri_) internal onlyInitializing {
        _setBaseURI(baseUri_);
    }

    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseUri = _baseUri;

        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString())) : "";
    }

    function _setBaseURI(string memory baseUri_) internal virtual {
        _baseUri = baseUri_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
