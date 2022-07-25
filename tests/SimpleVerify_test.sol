// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";

import "../contracts/SimpleVerify.sol";

/// #sender: account-0
contract SimpleVerifyTest is SimpleVerify {
    // Define some different accounts for testing purposes
    address acc0;
    address acc1;
    address acc2;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// Added the 
    /// #sender: account-0
    function vvs() public {
        Assert.ok(admin == acc0, "wrong admin added");
    }

    /// Add a verifier (acc1) using the admin (acc0)
    /// #sender: account-0
    function testAddVerifier() public {
        addVerifier(acc1);
        Assert.ok(isVerifier(acc1), "address not a verifier");
    }

    /// Add a verified address (acc2) using the new verifier (acc1)
    /// #sender: account-1
    function testAddVerifiedAddress() public {
        addVerified(acc2);
        Assert.ok(isVerified(acc2), "address not verified");
    }

    /// Remove a verifier (acc1) using the admin (acc0)
    /// #sender: account-0
    function testRemoveVerifier() public {
        removeVerifier(acc1);
        Assert.equal(
            isVerifier(acc1), 
            false, 
            "address is still a verifier"
        );
    }
}