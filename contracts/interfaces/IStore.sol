//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStore {
    /* ========== ERRORS ========== */

    error ZeroAddress();
    error LengthMismatch();
    error AlreadyUsed();
    error NotOwner();

    struct Metadata {
        string name;
    }

    event TreasuryUpdated(address oldTreasury, address newTreasury);

    event SetMetadata(address user, uint256 tokenId, Metadata metadata);

    event Registered(uint256 uid, address user, uint256 tokenId, Metadata metadata);

    function pause() external;

    function unpause() external;

    function setBaseURI(string memory uri_) external;

    function exists(uint256 tokenId_) external view returns (bool);

    function setMetadata(uint256 tokenId_, Metadata memory metadatas_) external;
}
