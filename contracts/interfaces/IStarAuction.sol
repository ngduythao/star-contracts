// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

interface IStarAuction {
    error StarAuction__Expired();
    error StarAuction__InvalidBid();
    error StarAuction__ZeroAddress();
    error StarAuction__Blacklisted();
    error StarAuction__Unauthorized();
    error StarAuction__InvalidClaim();
    error StarAuction__LengthMismatch();
    error StarAuction__InvalidAddress();
    error StarAuction__InvalidSignature();

    event Refunded(address indexed operator_, uint256 indexed refund);

    event ClaimedBid(
        address indexed operator,
        address indexed bidder,
        address indexed claimer,
        BidPermit bid,
        ClaimPermit claim
    );

    event ClaimedFee(
        address indexed operator,
        address indexed receiver,
        address indexed signer,
        address token,
        uint256 amount
    );

    function pause() external;

    function unpause() external;

    function version() external pure returns (bytes32);

    function claimBid(
        BidPermit calldata bid_,
        ClaimPermit calldata claim_,
        bytes calldata bidSignature_,
        bytes calldata claimSignature_
    ) external payable;

    function nonces(address receiver_) external view returns (uint256);

    function nonces(bytes32 bidId_) external view returns (uint256);

    function nonces(address nft_, uint256 tokenId_) external view returns (uint256);
}
