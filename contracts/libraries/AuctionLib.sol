// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { BidPermit, Bidder, ClaimPermit, Claimer } from "../interfaces/IStarAuction.sol";

library AuctionLib {
    function hash(BidPermit calldata bidPermit_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to
                    //keccak256(
                    //"BidPermit(address token,address value,uint256 deadline,Bidder bidder,bytes extraData)Bidder(address account,address payment,uint256 unitPrice,uint256 deadline,bytes signature)"
                    //)
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
                    /// @dev value is equal to keccak256(
                    //"ClaimPermit(bytes32 bidId,uint256 deadline,Claimer claimer,bytes extraData)Claimer(uint256 deadline,bytes signature)"
                    //)
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
