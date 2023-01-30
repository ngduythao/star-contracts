// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { BitMapsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { ERC721Upgradeable, ERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { ERC721URIStorageUpgradeable } from "./internal-upgradeable/ERC721URIStorageUpgradeable.sol";
import { ERC721BurnableUpgradeable } from "./internal-upgradeable/ERC721BurnableUpgradeable.sol";
import { ERC721WithPermitUpgradable } from "./internal-upgradeable/ERC721WithPermitUpgradable.sol";

import { IStore } from "./interfaces/IStore.sol";

contract StoreNFT is
    IStore,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ERC721WithPermitUpgradable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;

    bytes32 public constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    bytes32 public constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    bytes32 public constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    uint256 private _idCounter;
    BitMapsUpgradeable.BitMap private _isUsed;
    mapping(uint256 => Metadata) private _metadata;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_, string memory version_, string memory baseUri_) public initializer {
        address sender = _msgSender();

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        __ERC721WithPermitUpgradable_init(name_, symbol_, version_);
        __ERC721URIStorage_init(baseUri_);
        __ERC721Burnable_init();
        __ERC721Enumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(OPERATOR_ROLE, sender);
        _grantRole(MINTER_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _idCounter = 1;
    }

    function pause() public onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function setBaseURI(string calldata uri_) external onlyRole(OPERATOR_ROLE) {
        _setBaseURI(uri_);
    }

    function createStore(uint256 uid_, address account_, Metadata calldata metadata_) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _idCounter;
        _checkUnique(uid_);
        _metadata[tokenId] = Metadata({ name: metadata_.name });
        _safeMint(account_, tokenId);
        emit Registered(uid_, account_, tokenId, metadata_);
        _idCounter = ++tokenId;
    }

    function setMetadata(uint256 tokenId_, Metadata calldata metadata_) external {
        address user = _msgSender();
        if (_ownerOf(tokenId_) != user) revert NotOwner();
        _metadata[tokenId_] = Metadata({ name: metadata_.name });
        emit SetMetadata(user, tokenId_, metadata_);
    }

    function isUsed(uint256 uid_) external view returns (bool) {
        return _isUsed.get(uid_);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _checkUnique(uint256 uid_) internal {
        if (_isUsed.get(uid_)) revert AlreadyUsed();
        _isUsed.setTo(uid_, true);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _transfer(address from_, address to_, uint256 tokenId_) internal override(ERC721Upgradeable, ERC721WithPermitUpgradable) {
        super._transfer(from_, to_, tokenId_);
    }

    function _baseURI() internal view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return _baseUri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721WithPermitUpgradable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
