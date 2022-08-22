// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";
import {NavOrderList} from "../order/NavOrderList.sol";

abstract contract AbstractFund is ERC20 {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    NavOrderList internal _navBuyOrders;
    NavOrderList internal _navSellOrders;
    mapping(address => uint256) internal _brokerageAccounts;
    mapping(address => uint256) internal _custodyAccounts;

    constructor() {
        _navBuyOrders = new NavOrderList();
        _navSellOrders = new NavOrderList();
    }

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event OrderQueued(
        address indexed addr,
        uint256 id
    );

    event QueuedOrderActioned(
        address indexed buyer, 
        address indexed seller, 
        uint256 shares,
        uint256 price,
        bool partiallyExecuted,
        uint256 queuedOrderId
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
     * @dev Places a buy order of size `shares`, the price bought at will 
     * always equal NAV per share at the point of transaction. If the order
     * isn't fully executed, the client has the option of adding the order
     * to a queue. This is done using the a flag.
     * 
     * SThe user should send the maximum amount they would be willing to pay 
     * for the shares. This gives some flexibility, which is important given 
     * NAV is dynamic.
     *
     * -> If the money is more than sufficient, the algo will attempt to 
     *    execute and if successful, it will immediately extra refund the 
     *    money. If it cannot:
     *    -> queueIfPartail = true; move remaining funds to a brokerage 
     *       account, queue order of: shares - shares executed.
     *    -> queueIfPartial = false; refund extra money.
     *
     * -> If the money is insufficient
     *    -> queueIfPartail = true; move remaining funds to a brokerage 
     *       account, queue order of: shares - shares executed.
     *    -> queueIfPartial = false; refund extra money.
     * 
     * @param shares The number of shares to buy
     * @param queueIfPartial If true adds non-bought shares to a queue to be 
     * executed later
     */
    function placeBuyNavOrder(uint256 shares, bool queueIfPartial)
        external
        payable
        virtual
        returns (bool success, uint256 orderId);
    
    /**
     * @dev Places a sell order of size `shares`, the price sold at will 
     * always equal NAV per share at the point of transaction. If the order
     * isn't fully executed, the client has the option of adding the order
     * to a queue. This is done using the a flag.
     * 
     * @param shares The number of shares to sell
     * @param queueIfPartial If true adds unsold shares to a queue to be 
     * executed later
     */
    function placeSellNavOrder(uint256 shares, bool queueIfPartial) 
        external 
        virtual
        returns (bool success, uint256 orderId);

    /**
     * @dev Finds where the mismatch is in liquidity, then executes the orders,
     * 
     * If there are buy orders outstanding - take money from brokerage account
     * and mint shares.
     *
     * If there are sell orders outstanding - send money and burn shares.
     */
    function closeNavOrders()
        external
        virtual;

    /// -----------------------------
    ///         Public
    /// -----------------------------
    
    /**
     * @dev Computes the NAV (Wei)
     */ 
    function nav() public view virtual returns (uint256);

    /**
     * @dev Computes the NAV per share (Wei)
     */ 
    function navPerShare() public view returns (uint256) {
        return nav() / _totalShares;
    }

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    function _burnFromCustodyAccount(address addr, uint256 shares) internal {
        _custodyAccounts[addr] -= shares;
        _totalShares -= shares;
        emit Transfer(addr, address(0), shares);
    }
}
