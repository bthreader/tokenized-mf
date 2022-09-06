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

    /// -----------------------------
    ///         Setup
    /// -----------------------------

    function setUp() public {
        vm.prank(acc1);
        token = new ERC20();
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------

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