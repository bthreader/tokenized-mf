// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";
import {NavOrderQueue} from "../order/NavOrderQueue.sol";

abstract contract AbstractFund is ERC20 {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    constructor () {
        _balances[msg.sender] = 1;
        _totalShares += 1;
    }

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
     * @dev Executes the maximum amount of shares the buyer can afford.
     * must use_handleBuyCash to handle msg.value.
     */
    function placeBuyNavOrder()
        external
        payable
        virtual;

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

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    /**
     * @dev Ensures clients are refunded any cash which is not used for buying
     * shares.
     *
     * @param addr The address of the buy order caller.
     * @param money The msg.value sent by the caller, throws for zero or less
     * than price
     * @param price The price at the point of call.
     *
     * @return sharesToExecute The shares the customer can afford to execute.
     */
    function _handleBuyCash(address addr, uint256 money, uint256 price) 
        internal
        returns (uint256 sharesToExecute)
    {
        require(
            money > 0,
            "Fund: msg.value must be greater than zero to place buy order"    
        );
        if (money < price) {
            // Refund
            payable(addr).transfer(money);
            // Throw
            require(
                false,
                "Fund: msg.value must be greater than or equal to price"
            );
        }
        sharesToExecute = money / price;
        // Client will spend less than they sent -> refund
        if ((sharesToExecute * price) < money) {
            payable(addr).transfer(
                money - (sharesToExecute * price)
            );
        }
    }
}
