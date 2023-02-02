// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { OrderTypes } from "../libraries/OrderTypes.sol";

interface IStarExchange {
    function buy(OrderTypes.SellerOrder calldata sellerAsk) external payable;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);

    event Buy(
        bytes32 orderHash, // bid hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed buyer, // sender address for the taker ask order
        address indexed seller, // maker address of the initial bid order
        address currency, // currency address
        address collection, // collection address
        uint256 tokenId, // tokenId transferred
        uint256 price // final transacted price
    );
}
