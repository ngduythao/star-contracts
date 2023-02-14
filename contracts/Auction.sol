// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Initializable } from "oz-custom/contracts/oz-upgradeable/proxy/utils/Initializable.sol";
import {
    PausableUpgradeable
} from "oz-custom/contracts/oz-upgradeable/security/PausableUpgradeable.sol";
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

import { Bytes32Address } from "./libraries/Bytes32Address.sol";
import { SigUtil } from "oz-custom/contracts/libraries/SigUtil.sol";

import {
    ERC165CheckerUpgradeable
} from "oz-custom/contracts/oz-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

struct Bidder {
    address payment;
    uint256 unitPrice;
    uint256 deadline;
    bytes signature;
}

struct BidPermit {
    address token;
    uint256 value;
    uint256 deadline;
    Bidder bidder;
    bytes extraData;
}

struct Claimer {
    uint256 deadline;
    bytes signature;
}

struct ClaimPermit {
    bytes32 bidId;
    uint256 deadline;
    Claimer claimer;
    bytes extraData;
}

interface IAuction {
    error Auction__InvalidBid();
    error Auction__ZeroAddress();
    error Auction__Blacklisted();
    error Auction__Unauthorized();
    error Auction__InvalidClaim();
    error Auction__InvalidAddress();
    error Auction__InvalidSignature();

    event Refunded(address indexed operator_, uint256 indexed refund);

    event ClaimedBid(
        address indexed operator,
        address indexed bidder,
        address indexed claimer,
        BidPermit bid,
        ClaimPermit claim
    );
}

library AuctionLib {
    function hash(BidPermit calldata bidPermit_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to keccak256("BidPermit(address token,address value,uint256 deadline,Bidder bidder,bytes extraData)Bidder(address account,address payment,uint256 unitPrice,uint256 deadline,bytes signature)")
                    0x984eb53d0241e40771e083d5e7ada0e9f2f0ca4641e6d22efdabefea39ae90ae,
                    bidPermit_.token,
                    bidPermit_.value,
                    bidPermit_.deadline,
                    hash(bidPermit_.bidder),
                    keccak256(bytes(bidPermit_.extraData))
                )
            );
    }

    function hash(Bidder calldata bidder_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to keccak256("Bidder(address payment,uint256 unitPrice,uint256 deadline,bytes signature)")
                    0xdd8457a7974f19e42d370295cf21a07a3bcc8937960ebe0d2c464fb5379fd1e0,
                    bidder_.payment,
                    bidder_.unitPrice,
                    bidder_.deadline,
                    keccak256(bytes(bidder_.signature))
                )
            );
    }

    function hash(ClaimPermit calldata claimPermit_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to keccak256("ClaimPermit(bytes32 bidId,uint256 deadline,Claimer claimer,bytes extraData)Claimer(uint256 deadline,bytes signature)")
                    0x03a3e39d54d630493934dec65ee871b9cf07021a492696ee3be67e9fa9a94247,
                    claimPermit_.bidId,
                    claimPermit_.deadline,
                    hash(claimPermit_.claimer),
                    keccak256(bytes(claimPermit_.extraData))
                )
            );
    }

    function hash(Claimer calldata claimer_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to keccak256("Claimer(uint256 deadline,bytes signature)")
                    0xc423a54977fa86ce95ab175f3932b892b4ed74989969230a2b2fb470cca22711,
                    claimer_.deadline,
                    keccak256(bytes(claimer_.signature))
                )
            );
    }
}

contract Auction is
    IAuction,
    Initializable,
    PausableUpgradeable,
    SignableUpgradeable,
    TransferableUpgradeable,
    ProxyCheckerUpgradeable,
    BlacklistableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using AuctionLib for *;
    using SigUtil for bytes;
    using Bytes32Address for address;
    using ERC165CheckerUpgradeable for address;

    /// @dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 private constant OPERATOR_ROLE =
        0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;

    IWNT public wnt;

    modifier validCaller() virtual {
        _checkCaller(_msgSender());
        _;
    }

    function initialize(IWNT wnt_, address[] calldata operators_) external initializer {
        __Pausable_init_unchained();
        __Auction_init_unchained(wnt_, operators_);
        __Signable_init_unchained(type(Auction).name, "1");
    }

    function __Auction_init_unchained(
        IWNT wnt_,
        address[] calldata operators_
    ) internal virtual onlyInitializing {
        wnt = wnt_;

        uint256 length = operators_.length;
        bytes32 operatorRole = OPERATOR_ROLE;
        for (uint256 i; i < length; ) {
            _grantRole(operatorRole, operators_[i]);

            unchecked {
                ++i;
            }
        }
    }

    function setUserStatus(
        address account_,
        bool status_
    ) external override onlyRole(OPERATOR_ROLE) {
        _setUserStatus(account_, status_);
    }

    function version() public pure returns (bytes32) {
        /// @dev value is equal to keccak256("Auction_v1")
        return 0xffa2af4479cc119ea2b7c2be2004b9e67e391aa833d052f18616e1fb320f7781;
    }

    function claimBid(
        BidPermit calldata bid_,
        ClaimPermit calldata claim_,
        bytes calldata bidSignature_,
        bytes calldata claimSignature_
    ) external payable whenNotPaused {
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

    function _handleNativeTransfer(
        address operator_,
        address claimer_,
        uint256 value_
    ) internal virtual {
        address _wnt = address(wnt);
        IWNT(_wnt).deposit{ value: value_ }();
        _safeERC20Transfer(IERC20Upgradeable(_wnt), claimer_, value_);

        uint256 refund = msg.value - value_;
        if (refund == 0) return;

        _safeNativeTransfer(operator_, refund, "REFUND");
        emit Refunded(operator_, refund);
    }

    function _handleERC20Transfer(
        address bidder_,
        address claimer_,
        BidPermit calldata bid_
    ) internal virtual {
        if (
            IERC20Upgradeable(bid_.bidder.payment).allowance(bidder_, address(this)) <
            bid_.bidder.unitPrice
        ) {
            (bytes32 r, bytes32 s, uint8 v) = bid_.bidder.signature.split();
            IERC20PermitUpgradeable(bid_.bidder.payment).permit(
                bidder_,
                address(this),
                bid_.bidder.unitPrice,
                bid_.bidder.deadline,
                v,
                r,
                s
            );
        }

        _safeERC20TransferFrom(
            IERC20Upgradeable(bid_.bidder.payment),
            bidder_,
            claimer_,
            bid_.bidder.unitPrice
        );
    }

    function _handleERC721Transfer(
        address bidder_,
        address claimer_,
        BidPermit calldata bid_,
        ClaimPermit calldata claim_
    ) internal virtual {
        if (claimer_ != IERC721Upgradeable(bid_.token).ownerOf(bid_.value))
            revert Auction__Unauthorized();

        if (IERC721Upgradeable(bid_.token).getApproved(bid_.value) != address(this))
            IERC721PermitUpgradeable(bid_.token).permit(
                address(this),
                bid_.value,
                claim_.claimer.deadline,
                claim_.claimer.signature
            );

        IERC721Upgradeable(bid_.token).safeTransferFrom(claimer_, bidder_, bid_.value, "");
    }

    function nonces(address account_) external view returns (uint256) {
        return _nonce(account_.fillLast12Bytes());
    }

    function _nonZeroAddress(address addr_) internal pure virtual {
        if (addr_ == address(0)) revert Auction__ZeroAddress();
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
        ) revert Auction__InvalidBid();
    }

    function _checkClaim(bytes32 bidId_, ClaimPermit calldata claim_) internal view virtual {
        if (bidId_ != claim_.bidId || claim_.deadline > block.timestamp)
            revert Auction__InvalidClaim();
    }

    function _checkBlacklist(address account_) internal view virtual {
        if (isBlacklisted(account_)) revert Auction__Blacklisted();
    }

    uint256[49] private __gap;
}
