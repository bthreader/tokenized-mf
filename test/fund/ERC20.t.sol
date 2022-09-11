// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {ERC20} from "../../src/fund/ERC20.sol";

contract ERC20Test is Test, GenericTest {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    ERC20 public token;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event AccountantAdded(
        address indexed accountant,
        address indexed admin
    );

    event AccountantRemoved(
        address indexed accountant,
        address indexed admin
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// -----------------------------
    ///         Setup
    /// -----------------------------

    function setUp() public {
        vm.startPrank(acc1);
        token = new ERC20();
        token.addVerifier(acc1);
        token.addVerified(acc2);
        token.addVerified(acc3);
        vm.stopPrank();
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------

    function testApprove() public {
        vm.prank(acc2);
        vm.expectEmit(true, true, false, false);
        emit Approval({owner : acc2, spender : acc3, value : 10});
        token.approve({spender : acc3, amount : 10});
        assertTrue(
            token.allowance({owner : acc2, spender : acc3}) == 10,
            "Allowance not added"
        );
    }

    function testApproveFails() public {
        vm.prank(acc2);
        vm.expectRevert(bytes(
            "ERC20: can only provide allowances to verified customers"
        ));
        token.approve({spender: address(0x66), amount: 10});
    }

    function testChangeAllowance() public {
        vm.startPrank(acc2);
        token.approve({spender: acc3, amount: 10});
        token.increaseAllowance({spender : acc3, addedValue : 5});
        assertTrue(
            token.allowance({owner : acc2, spender : acc3}) == 15,
            "Allowance not added"
        );
        token.decreaseAllowance({spender : acc3, subtractedValue : 15});
        assertTrue(
            token.allowance({owner : acc2, spender : acc3}) == 0,
            "Allowance not removed"
        );
        vm.stopPrank();
    }

    function testChangeAllowanceFails() public {
        vm.prank(acc2);
        vm.expectRevert(bytes(
            "ERC20: cannot modify the allowance of a non-verified customer"
        ));
        token.increaseAllowance({spender: address(0x66), addedValue : 10});
    }

    function testAddAccountant() public {
        vm.expectEmit(true, true, false, false);
        emit AccountantAdded(acc2, acc1);
        vm.prank(acc1);
        token.addAccountant(acc2);
        assertTrue(
            token.isAccountant(acc2),
            "Accountant not added"
        );
    }

    function testRemoveAccountant() public {
        vm.prank(acc1);
        token.addAccountant(acc2);
        vm.expectEmit(true, true, false, false);
        emit AccountantRemoved(acc2, acc1);
        vm.prank(acc1);
        token.removeAccountant(acc2);
        assertTrue(
            !token.isAccountant(acc2),
            "Accountant not removed"
        );
    }
}