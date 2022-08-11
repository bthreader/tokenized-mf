// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ERC20} from "./ERC20.sol";

abstract contract AbstractFund is ERC20 {
    modifier sharesNotZero(uint256 shares) {
        require(
            shares != 0,
            "Cannot perform zero share operations"
        );
        _;
    }
    
    /**
     * @dev Computes the NAV (Wei)
     */ 
    function nav() public view virtual returns (uint) {}

    /**
     * @dev Computes the NAV per share (Wei)
     */ 
    function navPerShare() public view returns (uint) {
        nav() / totalSupply();
    }
    
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
        public
        payable
        virtual
        onlyVerified
        sharesNotZero(shares) {}
    
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
        public 
        virtual
        onlyVerified 
        sharesNotZero(shares) {}

    function burnAndReissue(address oldAddr, address newAddr) 
        public 
        onlyAdmin 
    {
        transferFrom({from : oldAddr, to : newAddr, amount : _balances[oldAddr]});
    }
}