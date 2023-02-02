// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title OrderTypes
 * @notice This library contains exchange order types
 */
library OrderTypes {
    // keccak256("SellerOrder(address signer,address collection,uint256 price,uint256 tokenId,address currency,uint256 nonce,uint256 startTime,uint256 endTime,bytes permit)")
    bytes32 internal constant SELLER_ORDER_HASH = 0x77e6796c71bfe525ae53a0f757d1a87b752a403ddc341df257ce81d3f363e801;

    struct SellerOrder {
        address signer; // signer of the seller
        address collection; // collection address
        uint256 price; // price (token amount )
        uint256 tokenId; // id of the token
        address currency; // currency (e.g., ETH -> address(0))
        uint256 nonce; // order nonce (must be unique)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        bytes permit; //
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    function hash(SellerOrder calldata sellerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SELLER_ORDER_HASH,
                    sellerOrder.signer,
                    sellerOrder.collection,
                    sellerOrder.price,
                    sellerOrder.tokenId,
                    sellerOrder.currency,
                    sellerOrder.nonce,
                    sellerOrder.startTime,
                    sellerOrder.endTime
                )
            );
    }
}
