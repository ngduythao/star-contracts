// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title ClaimTypes
 * @notice This library contains claim  types
 */
library ClaimTypes {
    // keccak256("Claim(uint256 nonce,uint256 deadline,address user,uint256[] amounts,address[] tokens)")
    bytes32 internal constant CLAIM_HASH =
        0xcabfb0e3a8d7a66441f25d7c0c8fd5180bf05942b71e56f775653ded5be5d5ca;

    struct Claim {
        uint256 nonce; // claim nonce (must be unique)
        uint256 deadline;
        address user; // address of the account who claim
        uint256[] amounts;
        address[] tokens; // currencies
    }

    function hash(Claim calldata order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIM_HASH,
                    order.nonce,
                    order.deadline,
                    order.user,
                    keccak256(abi.encodePacked(order.amounts)),
                    keccak256(abi.encodePacked(order.tokens))
                )
            );
    }
}
