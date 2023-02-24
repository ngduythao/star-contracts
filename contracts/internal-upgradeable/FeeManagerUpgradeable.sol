// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OrderTypes } from "../libraries/OrderTypes.sol";

/**
 * @title FeeManagerUpgradeable
 * @notice Protocol fee management
 */
contract FeeManagerUpgradeable is Initializable {
    // Event if the protocol fee changes
    event NewProtocolFee(address protocolRecipient, uint256 protocolFee);

    uint256 public constant HUNDER_PERCENT = 10_000; // 100%

    // Protocol fee
    uint256 internal _protocolFee;
    address internal _protocolFeeRecipient;

    function __FeeManager_init() internal onlyInitializing {
        __FeeManager_init_unchained();
    }

    function __FeeManager_init_unchained() internal onlyInitializing {}

    function _setProtocolFee(address newProtocolFeeRecipient_, uint256 newProtocolFee_) internal {
        _protocolFeeRecipient = newProtocolFeeRecipient_;
        _protocolFee = newProtocolFee_;

        emit NewProtocolFee(newProtocolFeeRecipient_, newProtocolFee_);
    }

    /**
     * @notice Return protocol fee for this strategy
     * @return protocol fee
     */
    function viewProtocolFeeInfo() external view returns (address, uint256) {
        return (_protocolFeeRecipient, _protocolFee);
    }
}
