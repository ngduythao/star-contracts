// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurrencyManager {
    /* ========== ERRORS ========== */
    error Zero();

    /* ========== EVENTS ========== */
    event TreasuryUpdated(address previousTreasury, address newTreasury);
}
