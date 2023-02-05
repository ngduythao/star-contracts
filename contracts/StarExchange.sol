// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// external
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { BitMapsUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/BitMapsUpgradeable.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// internal
import { EIP712Upgradeable } from "./internal-upgradeable/EIP712Upgradeable.sol";
import { CurrencyManagerUpgradeable } from "./internal-upgradeable/CurrencyManagerUpgradeable.sol";
import { FeeManagerUpgradeable } from "./internal-upgradeable/FeeManagerUpgradeable.sol";

// interfaces
import { IERC721Upgradeable } from "./internal-upgradeable/interfaces/IERC721Upgradeable.sol";
import { IERC4494Upgradeable } from "./internal-upgradeable/interfaces/IERC4494Upgradeable.sol";
import { IStarExchange } from "./interfaces/IStarExchange.sol";

// libraries
import { OrderTypes } from "./libraries/OrderTypes.sol";

/**
 * @title Star Marketplace
 * .----------------.  .----------------.  .----------------.  .----------------.
 * | .--------------. || .--------------. || .--------------. || .--------------. |
 * | |    _______   | || |  _________   | || |      __      | || |  _______     | |
 * | |   /  ___  |  | || | |  _   _  |  | || |     /  \     | || | |_   __ \    | |
 * | |  |  (__ \_|  | || | |_/ | | \_|  | || |    / /\ \    | || |   | |__) |   | |
 * | |   '.___`-.   | || |     | |      | || |   / ____ \   | || |   |  __ /    | |
 * | |  |`\____) |  | || |    _| |_     | || | _/ /    \ \_ | || |  _| |  \ \_  | |
 * | |  |_______.'  | || |   |_____|    | || ||____|  |____|| || | |____| |___| | |
 * | |              | || |              | || |              | || |              | |
 * | '--------------' || '--------------' || '--------------' || '--------------' |
 * '----------------'  '----------------'  '----------------'  '----------------'
 */

contract StarExchange is
    IStarExchange,
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    CurrencyManagerUpgradeable,
    FeeManagerUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable
{
    using BitMapsUpgradeable for BitMapsUpgradeable.BitMap;
    using OrderTypes for OrderTypes.SellerOrder;

    /// @dev value is equal to keccak256("OPERATOR_ROLE")
    bytes32 private constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
    /// @dev value is equal to keccak256("UPGRADER_ROLE")
    bytes32 private constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;
    /// @dev value is equal to keccak256("CURRENCY_ROLE")
    bytes32 private constant CURRENCY_ROLE = 0xf05d08f52b65664f2d8334187e35158d45f068d9d83ac572adc3840604b088aa;
    /// @dev value is equal to keccak256("COLLECTION_ROLE")
    bytes32 private constant COLLECTION_ROLE = 0x40a5c770eee7730548a6335e1f372e76bf4759f6fda1a932bd9cfc33106f0b4c;

    mapping(address => uint256) public minNonce;
    mapping(address => BitMapsUpgradeable.BitMap) private _isNonceExecutedOrCancelled;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata version_) public initializer {
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __EIP712_init_unchained(name_, version_);

        bytes32 operatorRole = OPERATOR_ROLE;
        bytes32 currencyRole = CURRENCY_ROLE;
        bytes32 collectionRole = COLLECTION_ROLE;

        _setRoleAdmin(currencyRole, operatorRole);
        _setRoleAdmin(collectionRole, operatorRole);

        _grantRole(currencyRole, address(0));
        _grantRole(collectionRole, 0xAd7a0B3f744f177E3f1fe6b315Dbd79b3ce89668);

        address sender = _msgSender();
        _grantRole(operatorRole, sender);
        _grantRole(UPGRADER_ROLE, sender);
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
    }

    /**
     * @notice Cancel all pending orders for a sender
     * @param minNonce_ minimum user nonce
     */
    function cancelAllOrders(uint256 minNonce_) external {
        bytes32 nonceKey;
        uint256 nonce;
        assembly {
            mstore(0, caller())
            mstore(32, minNonce.slot)
            nonceKey := keccak256(0, 64)
            nonce := sload(nonceKey)
        }

        require(minNonce_ > nonce && minNonce_ < nonce + 10000, "!N");
        assembly {
            sstore(nonceKey, minNonce_)
        }

        emit CancelAllOrders(_msgSender(), minNonce_);
    }

    /**
     * @notice Cancel maker orders
     * @param nonces_ array of order nonces
     */
    function cancelSellOrders(uint256[] calldata nonces_) external {
        uint256 length = nonces_.length;

        require(length != 0, "EMP");

        address sender = _msgSender();

        uint256 _minNonce = minNonce[sender];
        BitMapsUpgradeable.BitMap storage map = _isNonceExecutedOrCancelled[sender];

        for (uint256 i; i < length; ) {
            require(nonces_[i] >= _minNonce, "LN");
            map.set(nonces_[i]);
            unchecked {
                ++i;
            }
        }

        emit CancelMultipleOrders(sender, nonces_);
    }

    /**
     * @notice Match ask using native coin
     * @param sellerAsk seller ask order
     */
    function buy(OrderTypes.SellerOrder calldata sellerAsk) external payable override nonReentrant {
        bytes32 orderHash = sellerAsk.hash();

        // Check the maker ask order
        _validateOrder(sellerAsk, orderHash);

        // prevents replay
        _isNonceExecutedOrCancelled[sellerAsk.signer].set(sellerAsk.nonce);

        address buyer = _msgSender();
        // Execute transfer currency
        _transferFeesAndFunds(sellerAsk.currency, buyer, sellerAsk.signer, sellerAsk.price);

        // Execute transfer token collection
        _transferNonFungibleToken(sellerAsk.collection, sellerAsk.signer, buyer, sellerAsk.tokenId, sellerAsk.endTime, sellerAsk.permit);

        emit Buy(orderHash, sellerAsk.nonce, buyer, sellerAsk.signer, sellerAsk.currency, sellerAsk.collection, sellerAsk.tokenId, sellerAsk.price);
    }

    /**
     * @notice Update protocol fee and recipient
     * @param newProtocolFeeRecipient_ new recipient for protocol fees
     * @param newProtocolFee_ protocol fee
     */
    function setProtocolFee(address newProtocolFeeRecipient_, uint256 newProtocolFee_) external onlyRole(OPERATOR_ROLE) {
        _setProtocolFee(newProtocolFeeRecipient_, newProtocolFee_);
    }

    /**
     * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isNonceExecutedOrCancelled[user].get(orderNonce);
    }

    /**
     * @notice Transfer fees and funds to royalty recipient, protocol, and seller
     * @param currency_ currency being used for the purchase (e.g., WETH/USDC)
     * @param from_ sender of the funds
     * @param to_ seller's recipient
     * @param amount_ amount being transferred (in currency)
     */
    function _transferFeesAndFunds(address currency_, address from_, address to_, uint256 amount_) internal {
        if (currency_ == NATIVE_TOKEN) {
            _receiveNative(amount_);
        }

        // Initialize the final amount that is transferred to seller
        uint256 finalSellerAmount = amount_;

        // 1. Protocol fee
        {
            uint256 protocolFeeAmount = _calculateProtocolFee(amount_);

            address feeRecipient = _protocolFeeRecipient;
            // Check if the protocol fee is different than 0
            if (protocolFeeAmount != 0 && feeRecipient != address(0)) {
                _transferCurrency(currency_, from_, feeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        // 2. Creator fee
        {

        }

        // 3. Transfer final amount (post-fees) to seller
        {
            _transferCurrency(currency_, from_, to_, finalSellerAmount);
        }
    }

    /* solhint-disable no-empty-blocks */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @notice Calculate protocol fee
     * @param amount_ amount to transfer
     */
    function _calculateProtocolFee(uint256 amount_) private view returns (uint256) {
        return (amount_ * _protocolFee) / HUNDER_PERCENT;
    }

    /**
     * @notice Verify the validity of the maker order
     * @param order seller order
     */
    function _validateOrder(OrderTypes.SellerOrder calldata order, bytes32 orderHash) private view {
        // Verify the price is not 0
        require(order.price != 0, "!Price");

        // Verify order timestamp
        require(order.startTime <= block.timestamp && order.endTime >= block.timestamp, "!Time");

        // Verify whether the currency is whitelisted
        require(hasRole(CURRENCY_ROLE, order.currency), "!Currency");
        require(hasRole(COLLECTION_ROLE, order.collection), "!Collection");

        (address recoveredAddress, ) = ECDSAUpgradeable.tryRecover(_hashTypedDataV4(orderHash), order.v, order.r, order.s);

        // Verify the validity of the signature
        require(recoveredAddress != address(0) && recoveredAddress == order.signer, "!Signer");

        // Verify whether order nonce has expired
        require((order.nonce >= minNonce[order.signer]) && (!_isNonceExecutedOrCancelled[order.signer].get(order.nonce)), "!Nonce");
    }
}
