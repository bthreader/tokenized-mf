// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";
import {NavOrderQueue} from "../order/NavOrderQueue.sol";

abstract contract AbstractFund is ERC20 {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    NavOrderQueue internal _navSellOrders;
    mapping(address => uint256) internal _custodyAccounts;

    constructor() {
        _navSellOrders = new NavOrderQueue();
    }

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event QueuedOrderActioned(
        address indexed buyer, 
        address indexed seller, 
        uint256 shares,
        uint256 price,
        bool partiallyExecuted,
        uint256 sellOrderId
    );

    /// -----------------------------
    ///         Modifiers
    /// -----------------------------
    
    modifier sharesNotZero(uint256 shares) {
        require(
            shares != 0,
            "Cannot perform zero share operations"
        );
        _;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------
    
    /**
     * @dev Find out what msg.sender can afford to buy of what they've 
     * requested (`shares`), refund any extra money involved:
     *      1. Sent more money than required for `shares`
     *      2. Didn't send enough money for `shares` but more money than
     *         price * sharesTheyCanActually afford
     *
     * Attempts first to close any outstanding sell orders, mints shares
     * if there's no remaining sell orders
     * 
     * @param shares The number of shares to buy
     */
    function placeBuyNavOrder(uint256 shares)
        external
        payable
        virtual;

    /**
     * @dev Places a sell order of size `shares`, the price sold at will 
     * always equal NAV per share at the point of transaction. If the order
     * isn't fully executed, the client has the option of adding the order
     * to a queue. This is done using the a flag.
     * 
     * @param shares The number of shares to sell
     */
    function placeSellNavOrder(uint256 shares) 
        external
        virtual
        returns (uint256 orderId);

    /**
     * @dev Finds where the mismatch is in liquidity, then executes the orders.
     * 
     * If there are buy orders outstanding - take money from brokerage account
     * and mint shares.
     *
     * If there are sell orders outstanding - send money and burn shares.
     */
    function closeNavOrders()
        external
        virtual;

    function cancelSellNavOrder(uint256 id) external virtual;

    function myCustodyAccountBalance() 
        external 
        view 
        onlyVerified 
        returns (uint256) 
    {
        return _custodyAccounts[msg.sender];
    }

    function getQueuedSellNavOrderDetails(uint256 id) 
        external 
        view 
        returns (address addr, uint256 shares)
    {
        return _navSellOrders.getOrderDetails(id);
    }

    function fundCashPosition() 
        external
        view
        onlyAccountant
        returns (uint256 balance) 
    {
        balance = address(this).balance;
    }

    /**
     * @dev Allows the creator to set the share price in first instance.
     */
    function topUp() external payable {}

    /// -----------------------------
    ///         Public
    /// -----------------------------
    
    /**
     * @dev Computes the NAV.
     */ 
    function nav() public view virtual returns (uint256);

    /**
     * @dev Computes the NAV per share.
     */ 
    function navPerShare() public view returns (uint256) {
        return nav() / _totalShares;
    }
}
