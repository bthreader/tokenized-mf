// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";

abstract contract FixedNavFund is AbstractFund {
    function price() public pure override returns (uint) {
        return 10;
    }
    
    function placeBuyNavOrder(uint256 shares) 
        public
        payable
        override
        onlyVerified 
        sharesNotZero(shares) 
    {
        // require(
        //     msg.value == (shares * price()),
        //     "Insufficient funds to invest, transaction rejected"
        // );

        // balances[msg.sender] += shares;
        // totalShares += shares;
    }

    function placeSellNavOrder(uint256 shares) 
        public 
        override
        sharesNotZero(shares) 
    {
        // require(
        //     balances[msg.sender] >= shares,
        //     "Insufficient shares to sell, transaction rejected"
        // );
        // payable(msg.sender).transfer(price() * shares);

        // balances[msg.sender] -= shares;
        // totalShares -= shares;
    }
}