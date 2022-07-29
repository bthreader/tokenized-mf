// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/issue/AbstractFund.sol";

contract FixedNavFund is AbstractFund {
    function price() public pure override returns (uint) {
        return 10;
    }
    
    function buyShares(uint shares) 
        onlyVerified 
        sharesNotZero(shares) 
        payable 
        public 
        override 
    {
        require(
            msg.value == (shares * price()),
            "Insufficient funds to invest, transaction rejected"
        );

        balances[msg.sender] += shares;
        totalShares += shares;
    }

    function redeemShares(uint shares) 
        sharesNotZero(shares) 
        public 
        override 
    {
        require(
            balances[msg.sender] >= shares,
            "Insufficient shares to sell, transaction rejected"
        );
        payable(msg.sender).transfer(price() * shares);

        balances[msg.sender] -= shares;
        totalShares -= shares;
    }
}