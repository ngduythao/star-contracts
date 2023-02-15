// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Initializable } from "oz-custom/contracts/oz-upgradeable/proxy/utils/Initializable.sol";
import {
    UUPSUpgradeable
} from "oz-custom/contracts/oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    PausableUpgradeable
} from "oz-custom/contracts/oz-upgradeable/security/PausableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "oz-custom/contracts/oz-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "oz-custom/contracts/oz-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import { WNT, IWNT } from "oz-custom/contracts/utils/WNT.sol";

import {
    IERC20Upgradeable,
    TransferableUpgradeable
} from "oz-custom/contracts/internal-upgradeable/TransferableUpgradeable.sol";
import {
    BlacklistableUpgradeable
} from "oz-custom/contracts/internal-upgradeable/BlacklistableUpgradeable.sol";
import {
    SignableUpgradeable
} from "oz-custom/contracts/internal-upgradeable/SignableUpgradeable.sol";
import {
    ProxyCheckerUpgradeable
} from "oz-custom/contracts/internal-upgradeable/ProxyCheckerUpgradeable.sol";

import {
    IERC20PermitUpgradeable
} from "oz-custom/contracts/oz-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import {
    IERC721Upgradeable,
    IERC721PermitUpgradeable
} from "oz-custom/contracts/oz-upgradeable/token/ERC721/extensions/IERC721PermitUpgradeable.sol";

import { IStarAuction } from "./interfaces/IStarAuction.sol";

import { BidPermit, ClaimPermit, Bidder, Claimer, AuctionLib } from "./libraries/AuctionLib.sol";

import { Bytes32Address } from "./libraries/Bytes32Address.sol";
import { SigUtil } from "oz-custom/contracts/libraries/SigUtil.sol";

import {
    ERC165CheckerUpgradeable
} from "oz-custom/contracts/oz-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

contract StarAuction is
    IStarAuction,
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    SignableUpgradeable,
    TransferableUpgradeable,
    ProxyCheckerUpgradeable,
    BlacklistableUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using AuctionLib for *;
    using SigUtil for bytes;
    using Bytes32Address for address;
    using ERC165CheckerUpgradeable for address;

    /// @dev value is equal to keccak256("PAUSER_ROLE")
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    /// @dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 public constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    /// @dev value is equal to keccak256("UPGRADER_ROLE")
    bytes32 public constant UPGRADER_ROLE =
        0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;

    IWNT public wnt;
    uint256 public protocolFeeFraction;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() payable {
        _disableInitializers();
    }

    function initialize(
        IWNT wnt_,
        address admin_,
        bytes32[] calldata roles_,
        address[] calldata operators_
    ) external initializer {
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Signable_init_unchained(type(StarAuction).name, "1");
        __Auction_init_unchained(wnt_, admin_, roles_, operators_);
    }

    function __Auction_init_unchained(
        IWNT wnt_,
        address admin_,
        bytes32[] calldata roles_,
        address[] calldata operators_
    ) internal virtual onlyInitializing {
        wnt = wnt_;

        _grantRole(PAUSER_ROLE, admin_);
        _grantRole(OPERATOR_ROLE, admin_);
        _grantRole(UPGRADER_ROLE, admin_);
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);

        uint256 length = operators_.length;
        if (length != roles_.length) revert StarAuction__LengthMismatch();

        for (uint256 i; i < length; ) {
            _grantRole(roles_[i], operators_[i]);

            unchecked {
                ++i;
            }
        }
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setUserStatus(
        address account_,
        bool status_
    ) external override onlyRole(PAUSER_ROLE) {
        _setUserStatus(account_, status_);
    }

    function claimBid(
        BidPermit calldata bid_,
        ClaimPermit calldata claim_,
        bytes calldata bidSignature_,
        bytes calldata claimSignature_
    ) external payable whenNotPaused nonReentrant {
        /// check input
        address operator = _msgSender();
        _checkCaller(operator);

        _checkBid(bid_);

        bytes32 bidId = bid_.hash();
        _checkClaim(bidId, claim_);

        // validate signature
        address bidder = _recoverSigner(bidId, bidSignature_);
        _nonZeroAddress(bidder);
        _checkBlacklist(bidder);

        address claimer = _recoverSigner(claim_.hash(), claimSignature_);
        _nonZeroAddress(bidder);
        _checkBlacklist(claimer);

        // transfer NFT logic
        _handleERC721Transfer(bidder, claimer, bid_, claim_);

        // transfer asset logic
        if (msg.value == 0) _handleERC20Transfer(bidder, claimer, bid_);
        else _handleNativeTransfer(operator, claimer, bid_.bidder.unitPrice);

        emit ClaimedBid(operator, bidder, claimer, bid_, claim_);
    }

    function nonces(address account_) external view returns (uint256) {
        return _nonce(account_.fillLast12Bytes());
    }

    function percentageFraction() public pure virtual returns (uint256) {
        return 10_000;
    }

    function version() public pure returns (bytes32) {
        /// @dev value is equal to keccak256("Auction_v1")
        return 0xffa2af4479cc119ea2b7c2be2004b9e67e391aa833d052f18616e1fb320f7781;
    }

    function _handleNativeTransfer(
        address operator_,
        address claimer_,
        uint256 value_
    ) internal virtual {
        uint256 total = value_ + _calcProtocolFee(value_);
        uint256 refund = msg.value - total; // will underflow error if msg.value < value

        address _wnt = address(wnt);
        IWNT(_wnt).deposit{ value: total }();
        _safeERC20Transfer(IERC20Upgradeable(_wnt), claimer_, value_);

        if (refund == 0) return;

        _safeNativeTransfer(operator_, refund, "REFUND");
        emit Refunded(operator_, refund);
    }

    function _handleERC20Transfer(
        address bidder_,
        address claimer_,
        BidPermit calldata bid_
    ) internal virtual {
        address payment = bid_.bidder.payment;
        uint256 unitPrice = bid_.bidder.unitPrice;
        uint256 total = unitPrice + _calcProtocolFee(unitPrice);
        if (IERC20Upgradeable(payment).allowance(bidder_, address(this)) < total) {
            (bytes32 r, bytes32 s, uint8 v) = bid_.bidder.signature.split();
            IERC20PermitUpgradeable(payment).permit(
                bidder_,
                address(this),
                total,
                bid_.bidder.deadline,
                v,
                r,
                s
            );
        }

        _safeERC20TransferFrom(IERC20Upgradeable(payment), bidder_, address(this), total);
        _safeERC20TransferFrom(IERC20Upgradeable(payment), address(this), claimer_, unitPrice);
    }

    function _handleERC721Transfer(
        address bidder_,
        address claimer_,
        BidPermit calldata bid_,
        ClaimPermit calldata claim_
    ) internal virtual {
        address token = bid_.token;
        uint256 value = bid_.value;
        if (claimer_ != IERC721Upgradeable(token).ownerOf(value))
            revert StarAuction__Unauthorized();

        if (IERC721Upgradeable(token).getApproved(value) != address(this))
            IERC721PermitUpgradeable(token).permit(
                address(this),
                value,
                claim_.claimer.deadline,
                claim_.claimer.signature
            );

        IERC721Upgradeable(token).safeTransferFrom(claimer_, bidder_, value, "");
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function _calcProtocolFee(uint256 value_) internal view virtual returns (uint256) {
        return (value_ * protocolFeeFraction) / percentageFraction();
    }

    function _checkCaller(address caller_) internal view virtual {
        if (!hasRole(OPERATOR_ROLE, caller_)) _onlyEOA(caller_);
    }

    function _checkBid(BidPermit calldata bid_) internal view virtual {
        if (
            bid_.bidder.unitPrice == 0 ||
            bid_.deadline > block.timestamp ||
            bid_.bidder.deadline > block.timestamp ||
            !bid_.token.supportsInterface(type(IERC721Upgradeable).interfaceId)
        ) revert StarAuction__InvalidBid();
    }

    function _checkClaim(bytes32 bidId_, ClaimPermit calldata claim_) internal view virtual {
        if (bidId_ != claim_.bidId || claim_.deadline > block.timestamp)
            revert StarAuction__InvalidClaim();
    }

    function _checkBlacklist(address account_) internal view virtual {
        if (isBlacklisted(account_)) revert StarAuction__Blacklisted();
    }

    function _nonZeroAddress(address addr_) internal pure virtual {
        if (addr_ == address(0)) revert StarAuction__ZeroAddress();
    }

    uint256[49] private __gap;
}
