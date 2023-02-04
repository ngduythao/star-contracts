// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { ClaimTypes } from "../libraries/ClaimTypes.sol";

interface IStarClaim {
    /* ========== STRUCT ========== */
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function nextNonce(address account_) external view returns (uint256);

    function claim(ClaimTypes.Claim calldata order_, Signature[] calldata signs_) external;

    /* ========== ERRORS ========== */
    error InvalidSender();
    error LengthMismatch();
    error InvalidNonce();

    /* ========== ERRORS ========== */
    error NotEnoughOracles();
    error InvalidOracle();
    error ExpiredSignature();
    error ReplaySignature();
    error DuplicateSignatures();

    /* ========== EVENTS ========== */
    /// @dev Emitted once the submission is confirmed by min required amount of oracles.
    event Claim(address user, bytes32 claimId);
}
