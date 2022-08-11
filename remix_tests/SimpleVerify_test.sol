// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";

import "../contracts/kyc/SimpleVerify.sol";

/// #sender: account-0
contract SimpleVerifyTest is SimpleVerify {
    address private acc0;
    address private acc1;
    address private acc2;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
    }

    /// #sender: account-0
    function accountZeroaddsAccountOneAsVerifier() public {
        addVerifier(acc1);
        Assert.ok(isVerifier(acc1), "address not a verifier");
    }

    /// #sender: account-1
    function accountOneVerifiesAccountTwo() public {
        addVerified(acc2);
        Assert.ok(isVerified(acc2), "address not verified");
    }

    /// #sender: account-0
    function accountZeroRemovesAccountOneFromVerifiers() public {
        removeVerifier(acc1);
        Assert.ok(!isVerifier(acc1), "address is still a verifier");
    }
}