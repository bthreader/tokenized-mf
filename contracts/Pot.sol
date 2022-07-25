// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/ComplexVerify.sol";

contract Pot is ComplexVerify(msg.sender) {
    mapping(address => uint) public balances;
    uint public price;
    uint public totalShares;

    constructor() {
        price = 10;
    }

    modifier sharesNotZero(uint shares) {
        require(
            shares != 0,
            "Cannot perform zero share operations"
        );
        _;
    }

    function buyTokens(uint shares) senderIsVerified sharesNotZero(shares) public payable {
        require(
            msg.value == (shares*price),
            "You have insufficient funds, transaction rejected"
        );
        balances[msg.sender] += shares;    
    }

    // function fillPot(uint) {
    //     ;
    // }

    function withdrawFromPot(uint shares) sharesNotZero(shares) public {
        // Get the balance of the account
        uint total = address(this).balance;

        // Work out what the redeemer is entitled to (Wei)
        uint redeemable = (total / shares) * balances[msg.sender];
        
        // Transfer them that amount
        payable(msg.sender).transfer(redeemable);
    }
}