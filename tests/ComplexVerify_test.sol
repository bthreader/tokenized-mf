// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";

import "../contracts/ComplexVerify.sol";

// Start with account-0 as the admin
contract ComplexVerifyTest is ComplexVerify(TestsAccounts.getAccount(0)) {
    // Define some different accounts for testing purposes
    address acc0;
    address acc1;
    address acc2;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// Check zero address not an admin
    /// We instantiated earlier
    /// #sender: account-0
    function testZeroNotAdmin() public {
        Assert.ok(admins[address(0)] == false, "zero address should not be admin");
    }

    /// Add an admin (acc1) using the only admin (acc0)
    /// #sender: account-0
    function testAddOneAsAdmin() public {
        voteToAdd(acc1);
        Assert.ok(admins[acc1],"admin not added");
    }

    /// Vote to add acc2 using acc0
    /// #sender: account-0
    function zeroVotesToAddTwo() public {
        voteToAdd(acc2);
    }

    /// Vote to add acc2 using acc1
    /// #sender: account-1
    function oneVotesToAddTwo() public {
        voteToAdd(acc2);
    }

    /// acc2 now an admin
    /// #sender: account-0
    function testAddTwoAsAdmin() public {        
        Assert.ok(admins[acc2], "admin not added");
    }
}