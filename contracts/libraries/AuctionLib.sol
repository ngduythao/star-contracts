// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { BidPermit, Bidder, ClaimPermit, Claimer } from "../interfaces/IStarAuction.sol";

library AuctionLib {
    function hash(BidPermit calldata bidPermit_, uint256 nonce_) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to
                    //keccak256(
                    //"BidPermit(address token,address value,uint256 nonce,uint256 deadline,Bidder bidder,bytes extraData)Bidder(address account,address payment,uint256 unitPrice,uint256 deadline,bytes signature)"
                    //)
                    0x08fde214c4bd5a5f97340a3b8b370c9be5f0a80d47a374f8e2469c1e7406cf2d,
                    bidPermit_.token,
                    bidPermit_.value,
                    nonce_,
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

    function hash(
        ClaimPermit calldata claimPermit_,
        uint256 nonce_
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    /// @dev value is equal to keccak256(
                    //"ClaimPermit(bytes32 bidId,uint256 nonce,uint256 deadline,Claimer claimer,bytes extraData)Claimer(uint256 deadline,bytes signature)"
                    //)
                    0xe93ebbc6a90f74222f40762a35d515227cb4b2e78e83817f5a91f826188a43b1,
                    claimPermit_.bidId,
                    nonce_,
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
