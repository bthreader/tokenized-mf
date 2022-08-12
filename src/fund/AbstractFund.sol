// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";
import {OrderList} from "../order/OrderList.sol";

abstract contract AbstractFund is ERC20 {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    OrderList internal _navBuyOrders;
    OrderList internal _navSellOrders;

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
     * @param shares The number of shares to buy
     * @param queueIfPartial If true adds non-bought shares to a queue to be 
     * executed later
     */
    function placeBuyNavOrder(uint256 shares, bool queueIfPartial)
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
     * @param queueIfPartial If true adds unsold shares to a queue to be 
     * executed later
     */
    function placeSellNavOrder(uint256 shares, bool queueIfPartial) 
        external 
        virtual;

    /**
     * @dev Moves shares from a users previous address to their new one
     */
    function burnAndReissue(address oldAddr, address newAddr) 
        external 
        onlyAdmin
    {
        require(isVerified(newAddr), "Fund: verify the new address first");
        _balances[newAddr] = _balances[oldAddr];
        _balances[oldAddr] = 0;
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
        return nav() / totalSupply();
    }
}