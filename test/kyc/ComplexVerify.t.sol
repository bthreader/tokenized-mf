// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {ComplexVerify} from "../../src/kyc/ComplexVerify.sol";

contract ComplexVerifyTest is Test, GenericTest {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    ComplexVerify private verificationContract;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event VoteToAddPlaced(address indexed voter, address indexed candidate);

    /// -----------------------------
    ///         Setup
    /// -----------------------------

    /**
     * @dev acc1 becomes the first admin
     */
    function setUp() public {
        vm.prank(acc1);
        verificationContract = new ComplexVerify();
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------

    function testOneVoteAdd() public {
        vm.startPrank(acc1);
        vm.expectEmit(
            true, true, false, false, 
            address(verificationContract)
        );
        emit VoteToAddPlaced(acc1, acc2);
        verificationContract.voteToAdd(acc2);

        assertTrue(
            verificationContract.isAdmin(acc2),
            "acc1 not added to admins"
        );
        assertTrue(
            verificationContract.totalAdmins() == 2,
            "totalAdmins not updated"
        );
        vm.stopPrank();
    }

    function testTwoVotesToAdd() public {
        // Add acc2
        vm.prank(acc1);
        verificationContract.voteToAdd(acc2);
        
        // Add acc3 using acc1 and acc2
        vm.startPrank(acc1);
        verificationContract.voteToAdd(acc3);
        assertTrue(
            address(verificationContract.getElection(acc3)) != address(0), 
            "unfinished election doesn't persist"
        );
        vm.stopPrank();
        
        vm.startPrank(acc2);
        verificationContract.voteToAdd(acc3);
        assertTrue(
            verificationContract.isAdmin(acc2),
            "acc2 not added to admins"
        );
        assertTrue(
            verificationContract.totalAdmins() == 3,
            "totalAdmins not updated"
        );
        vm.stopPrank();
    }     

    function testProgressiveRemovalOfAdmins() public {
        // Build the state
        vm.prank(acc1);
        verificationContract.voteToAdd(acc2);
        vm.prank(acc1);
        verificationContract.voteToAdd(acc3);
        vm.prank(acc2);
        verificationContract.voteToAdd(acc3);
        
        // Place a removal vote to see if it works, and also to eventually
        // ensure it's removed after acc1 gets booted
        vm.startPrank(acc1);
        verificationContract.voteToRemove(acc2);
        assertTrue(
            verificationContract.getElection(acc2)._votes() == 1, 
            "acc1 removal vote not registered"
        );
        vm.stopPrank();

        vm.prank(acc2);
        verificationContract.voteToRemove(acc1);

        vm.prank(acc3);
        verificationContract.voteToRemove(acc1);

        vm.startPrank(acc2);
        assertTrue(
            verificationContract.isAdmin(acc1) == false,
            "acc1 not removed from admins"
        );
        assertTrue(
            verificationContract.totalAdmins() == 2,
            "totalAdmins not updated"
        );  
        assertTrue(
            verificationContract.getElection(acc2)._votes() == 0,
            "acc1 votes not removed"
        );
        vm.stopPrank;
    }
}
