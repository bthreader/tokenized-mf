// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";

import "../contracts//kyc/ComplexVerify.sol";

/// #sender: account-0
contract ComplexVerifyTest is ComplexVerify {
    address acc0;
    address acc1;
    address acc2;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// #sender: account-0
    function accountZeroAddsAccountOneAsAdmin() public {
        voteToAdd(acc1);
        Assert.ok(admins[acc1],"acc1 not added to admins");
        Assert.ok(totalAdmins == 2, "totalAdmins not updated");
    }

    /// #sender: account-0
    function accountZeroVotesToAddTwoAsAdmin() public {
        voteToAdd(acc2);
        Assert.ok(hasElection[acc2] == true, "unfinished election doesn't persist");
    }

    /// #sender: account-1
    function accountOneVotesToAddTwoAsAdmin() public {
        voteToAdd(acc2);
        Assert.ok(admins[acc2], "acc2 not added to admins");
        Assert.ok(totalAdmins == 3, "totalAdmins not updated");  
    }

    /// #sender: account-0
    function accountZeroVotesToRemoveOneFromAdmins() public {
        voteToRemove(acc1);
        Assert.ok(elections[acc1].votes() == 1, "zeros removal vote not registered");
    }

    /// #sender: account-1
    function u() public {
        voteToRemove(acc0);
    }

    /// #sender: account-2
    function accountTwoRemovesAccountOneFromAdmins() public {
        voteToRemove(acc0);
        Assert.ok(admins[acc0] == false, "acc0 not removed from admins");
        Assert.ok(totalAdmins == 2, "totalAdmins not updated");  
        Assert.ok(elections[acc1].votes() == 0, "acc0 votes not removed");
    }
}