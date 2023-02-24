// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {
    BitMapsUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    ECDSAUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import {
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {
    ERC721URIStorageUpgradeable
} from "./internal-upgradeable/ERC721URIStorageUpgradeable.sol";
import { ERC721BurnableUpgradeable } from "./internal-upgradeable/ERC721BurnableUpgradeable.sol";
import {
    EIP712Upgradeable,
    ERC721WithPermitUpgradable
} from "./internal-upgradeable/ERC721WithPermitUpgradable.sol";
import { CurrencyManagerUpgradeable } from "./internal-upgradeable/CurrencyManagerUpgradeable.sol";
import { IStarNFT } from "./interfaces/IStarNFT.sol";
import { PermitHelper } from "./libraries/PermitHelper.sol";

contract StarNFT is
    IStarNFT,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    CurrencyManagerUpgradeable,
    ERC721WithPermitUpgradable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using PermitHelper for address;

    /// @dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 private constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    /// @dev value is equal to keccak256("MINTER_ROLE")
    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;
    /// @dev value is equal to keccak256("UPGRADER_ROLE")
    bytes32 private constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    /// @dev value is equal to keccak256("Metadata(string name)")
    bytes32 private constant METADATA_TYPEHASH =
        0xbf715eb9495814abc85e5e9775550839f827f87ceb101d58a20b16146e57d69c;
    /// @dev value is equal to keccak256("CreateStore(uint256 uid,address account,Metadata metadata)Metadata(string name)")
    bytes32 private constant CREATE_STORE_TYPEHASH =
        0x182bb33cb8661f6356010cf040184dc3c21e21e9f5d7e5fb2479fe6d33e03d21;

    address public treasury;
    uint256 private constant CHAIN_ID_SLOT = 3;
    uint256 private _chainIdentity;
    uint256 private _idCounter;
    BitMapsUpgradeable.BitMap private _isUsed;
    mapping(uint256 => Metadata) private _metadata;
    mapping(address => uint256) private _paymentAmount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        string calldata version_,
        string calldata baseUri_,
        uint256 chainIdentity_
    ) external initializer {
        __Pausable_init_unchained();
        __EIP712_init_unchained(name_, version_);
        __ERC721URIStorage_init_unchained(baseUri_);
        __ERC721WithPermitUpgradable_init(name_, symbol_);

        address sender = _msgSender();

        _setTreasury(sender);

        _grantRole(MINTER_ROLE, sender);
        _grantRole(OPERATOR_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _grantRole(DEFAULT_ADMIN_ROLE, sender);

        _idCounter = 1;
        _chainIdentity = chainIdentity_;
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function setBaseURI(string calldata uri_) external onlyRole(OPERATOR_ROLE) {
        _setBaseURI(uri_);
    }

    function setTreasury(address treasury_) external onlyRole(OPERATOR_ROLE) {
        _setTreasury(treasury_);
    }

    function setPayment(address token_, uint256 amount_) external onlyRole(OPERATOR_ROLE) {
        _paymentAmount[token_] = amount_;
    }

    function createStore(Store calldata store_) external onlyRole(MINTER_ROLE) {
        _createStore(store_.uid, store_.account, store_.metadata);
    }

    function createStore(
        Store calldata store_,
        address paymentToken_,
        uint256 deadline_,
        bytes calldata permitSignature_,
        bytes calldata signature_
    ) external {
        uint256 amount = _paymentAmount[paymentToken_];
        require(amount > 0, "!TOKEN");

        bytes32 structHash = keccak256(
            abi.encode(
                CREATE_STORE_TYPEHASH,
                store_.uid,
                store_.account,
                _hashMetadata(store_.metadata)
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);
        (address recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signature_);
        require(
            (recoveredAddress != address(0) && hasRole(MINTER_ROLE, recoveredAddress)),
            "!SIG"
        );

        if (permitSignature_.length != 0)
            paymentToken_.permit(amount, deadline_, permitSignature_);
        _transferCurrency(paymentToken_, _msgSender(), treasury, amount);
        _createStore(store_.uid, store_.account, store_.metadata);
    }

    function setMetadata(uint256 tokenId_, Metadata calldata metadata_) external {
        address user = _msgSender();
        if (_ownerOf(tokenId_) != user) revert NotOwner();
        _metadata[tokenId_] = Metadata({ name: metadata_.name });
        emit SetMetadata(user, tokenId_, metadata_);
    }

    function paymentAmount(address paymentToken_) external view returns (uint256) {
        return _paymentAmount[paymentToken_];
    }

    function chainIdentity() external view returns (uint256) {
        return _chainIdentity;
    }

    function isUsed(uint256 uid_) external view returns (bool) {
        return _isUsed.get(uid_);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _hashMetadata(Metadata calldata metadata_) internal pure returns (bytes32) {
        return keccak256(abi.encode(METADATA_TYPEHASH, keccak256(bytes(metadata_.name))));
    }

    function _createStore(uint256 uid_, address account_, Metadata calldata metadata_) internal {
        _checkUnique(uid_);

        uint256 tokenId = (_idCounter << CHAIN_ID_SLOT) | _chainIdentity;
        _metadata[tokenId] = Metadata({ name: metadata_.name });
        _safeMint(account_, tokenId);

        emit Registered(uid_, account_, tokenId, metadata_);

        unchecked {
            ++_idCounter;
        }
    }

    function _checkUnique(uint256 uid_) internal {
        if (_isUsed.get(uid_)) revert AlreadyUsed();
        _isUsed.set(uid_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal override(ERC721Upgradeable, ERC721WithPermitUpgradable) {
        super._transfer(from_, to_, tokenId_);
    }

    function _baseURI()
        internal
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return _baseUri;
    }

    function _setTreasury(address treasury_) internal {
        if (treasury_ == address(0) || treasury_ == address(this)) revert ZeroAddress();

        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721WithPermitUpgradable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}
