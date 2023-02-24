// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOraclesManager {
    /* ========== ERRORS ========== */

    error OracleAlreadyExist();
    error OracleNotFound();
    error LowThreshold();

    /* ========== EVENTS ========== */
    /// @dev Emitted when an oracles is added
    event AddOracles(address[] oracles);

    /// @dev Emitted when an oracle is removed
    event RemoveOracle(address oracle);

    /* ========== FUNCTIONS ========== */
    /// @param oracles_ Oracles' addresses.
    // function addOracles(address[] calldata oracles_) external;

    /// @param oracle_ Oracles' address.
    // function removeOracle(address oracle_) external;

    /// @param threshold_ Sets the minimum numbers of oracles for confirming a valid request
    // function setThreshhold(uint8 threshold_) external;

    /**
     * @notice Returns if an oracle is valid
     * @param oracle of the oracle
     */
    function isValidOracle(address oracle) external view returns (bool);

    /**
     * @notice View number of the oracles
     */
    function viewCountOracles() external view returns (uint256);

    /**
     * @notice See the list of oracles in the system
     */
    function viewOracles() external view returns (address[] memory, uint256);
}
