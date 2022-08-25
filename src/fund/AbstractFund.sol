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

    event QueuedOrderActioned(
        address indexed buyer, 
        address indexed seller, 
        uint256 shares,
        uint256 price,
        bool partiallyExecuted,
        uint256 buyOrderId,
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

    function cancelBuyNavOrder(uint256 id) external onlyVerified {
        // Make sure it was the sender who owns the order
        (address addr, uint256 shares) = _navBuyOrders.getOrderDetails(id);
        require(
            msg.sender == addr,
            "Fund: must be the order placer to cancel the order"
        );
        _navBuyOrders.deleteId(id);
    }
    
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

    function cancelSellNavOrder(uint256 id) external onlyVerified {
        // Make sure it was the sender who owns the order
        (address addr, uint256 shares) = _navSellOrders.getOrderDetails(id);
        require(
            msg.sender == addr,
            "Fund: must be the order placer to cancel the order"
        );
        _navSellOrders.deleteId(id);
        _transferFromCustodyAccount({
            from : msg.sender,
            to : msg.sender, 
            amount : shares
        });
    }

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

    function myBrokerageAccountBalance() 
        external 
        view 
        onlyVerified 
        returns (uint256) 
    {
        return _brokerageAccounts[msg.sender];
    }

    function increaseMyBrokerageAccountBalance() 
        external 
        onlyVerified 
        payable
    {
        _brokerageAccounts[msg.sender] += msg.value;
    }

    function decreaseMyBrokerageAccountBalance(uint256 amount) 
        external 
        onlyVerified
    {
        require(
            amount <= _brokerageAccounts[msg.sender],
            "Fund: amount to decrease bigger than the brokerage account"
        );
        unchecked{
            _brokerageAccounts[msg.sender] -= amount;
        }
        payable(msg.sender).transfer(amount);
    }

    function myCustodyAccountBalance() 
        external 
        view 
        onlyVerified 
        returns (uint256) 
    {
        return _custodyAccounts[msg.sender];
    }

    function getBuyNavOrderDetails(uint256 id) 
        external 
        view 
        returns (address addr, uint256 shares)
    {
        return _navBuyOrders.getOrderDetails(id);
    }

    function getSellNavOrderDetails(uint256 id) 
        external 
        view 
        returns (address addr, uint256 shares)
    {
        return _navSellOrders.getOrderDetails(id);
    }

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

    function _transferFromCustodyAccount(
        address from,
        address to, 
        uint256 amount
    ) 
        internal 
    {
        unchecked {
            _custodyAccounts[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer({from : from, to : to, value : amount});
    }
}
