// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";

import "contracts/issue/FixedNavFund.sol";

/// #sender: account-0
contract PotTest is FixedNavFund {
    address acc0;
    address acc1;
    address acc2;
    uint balanceBefore;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// #sender: account-0
    function verifyOne() public {
        addVerifier(acc0);
        addVerified(acc1);
    }

    /// #value: 50
    /// #sender: account-1
    function accountOneBuysFiveShares() payable public {
        balanceBefore = acc1.balance;
        
        buyShares(5);
        Assert.ok(
            balances[acc1] == 5, 
            "correct shares not added to acc1"
        );
        Assert.ok(
            address(this).balance == 50,
            "correct value not added to the pot"
        );
        Assert.ok(
            (balanceBefore - 50) < acc1.balance,
            "Wei has not come out of account"
        );
    }

    /// #sender: account-1
    function accountOneRedeemsFiveShares() public {
        balanceBefore = acc1.balance;
        
        redeemShares(5);
        Assert.ok(
            balances[acc1] == 0, 
            "shares not removed account"
        );
        Assert.ok(
            (balanceBefore + 50) == acc1.balance,
            "Money not returned"
        );
    }

    // /// Use acc1 to redeem shares they don't have
    // function oneRedeemsBad() public {
    //     Assert.redeemShares(5);
    // }
}