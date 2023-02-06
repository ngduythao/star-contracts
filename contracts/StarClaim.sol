// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// external
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// internal
import { EIP712Upgradeable } from "./internal-upgradeable/EIP712Upgradeable.sol";
import { CurrencyManagerUpgradeable } from "./internal-upgradeable/CurrencyManagerUpgradeable.sol";
import { OraclesManagerUpgradeable } from "./internal-upgradeable/OraclesManagerUpgradeable.sol";

// interface
import { IStarClaim } from "./interfaces/IStarClaim.sol";

// libraries
import { ClaimTypes } from "./libraries/ClaimTypes.sol";

/**
 * @title Star Claim
 */

contract StarClaim is IStarClaim, Initializable, UUPSUpgradeable, PausableUpgradeable, CurrencyManagerUpgradeable, OraclesManagerUpgradeable, ReentrancyGuardUpgradeable, EIP712Upgradeable {
    using ClaimTypes for ClaimTypes.Claim;

    /// @dev value is equal to keccak256("VALIDATOR_ROLE")
    bytes32 private constant VALIDATOR_ROLE = 0x21702c8af46127c7fa207f89d0b0a8441bb32959a0ac7df790e9ab1a25c98926;
    /// @dev value is equal to keccak256("UPGRADER_ROLE")
    bytes32 private constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;

    mapping(address => uint256) private _nonces;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata version_, uint8 threshold_, address[] calldata oracles_) public initializer {
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __EIP712_init_unchained(name_, version_);
        __OraclesManager_init_unchained(threshold_, oracles_);
    }

    function claim(ClaimTypes.Claim calldata claim_, Signature[] calldata signatures_) external nonReentrant {
        uint256 length = claim_.tokens.length;
        bytes32 claimHash = claim_.hash();
        address sender = _msgSender();

        if (claim_.deadline < block.timestamp) revert ExpiredSignature();
        if (length != claim_.amounts.length) revert LengthMismatch();

        //solhint-disable-next-line avoid-tx-origin
        if (sender != tx.origin || sender != claim_.user || sender.code.length != 0) revert InvalidSender();

        // prevents replay
        unchecked {
            if (claim_.nonce != ++_nonces[sender]) revert InvalidNonce();
        }

        _validateSignatures(claimHash, signatures_);

        for (uint256 i; i < length; ) {
            _transferCurrency(claim_.tokens[i], address(this), sender, claim_.amounts[i]);
            unchecked {
                ++i;
            }
        }

        emit Claim(sender, claimHash);
    }

    /// @notice Allows to retrieve next nonce for the claim
    /// @param account_ user adddress
    /// @return next account nonce
    function nonce(address account_) external view returns (uint256) {
        unchecked {
            return _nonces[account_] + 1;
        }
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _validateSignatures(bytes32 claimHash_, Signature[] calldata signs_) private view {
        uint256 length = signs_.length;
        if (length < _threshHold) revert NotEnoughOracles();

        address[] memory oracles;
        unchecked {
            oracles = new address[](_viewCountOracles() + 1);
        }
        // reserve index 0 for invalid signer
        address recoveredAddress;
        uint256 index;
        bytes32 digest = _hashTypedDataV4(claimHash_);
        for (uint256 i; i < length; ) {
            (recoveredAddress, ) = ECDSAUpgradeable.tryRecover(digest, signs_[i].v, signs_[i].r, signs_[i].s);
            if (!_isValidOracle(recoveredAddress)) revert InvalidOracle();

            index = _indexOf(recoveredAddress);
            if (oracles[index] != address(0)) revert DuplicateSignatures();
            oracles[index] = recoveredAddress;

            unchecked {
                ++i;
            }
        }
    }
}
