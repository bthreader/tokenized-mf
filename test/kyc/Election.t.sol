// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {Election} from "../../src/kyc/Election.sol";

contract ElectionTest is Test, GenericTest {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    Election private election;
    
    /// -----------------------------
    ///         Setup
    /// -----------------------------

    function setUp() public {
        election = new Election();
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------

    function testAddVote() public {
        election.vote(acc1);
        assertTrue(
            election._hasVoted(acc1),
            "Vote not registered"
        );
        assertTrue(
            election._votes() == 1,
            "Total votes not incremented"
        );
    }

    function testDoubleVoteFail() public {
        election.vote(acc1);
        vm.expectRevert(bytes("Election: Address has already voted"));
        election.vote(acc1);
        assertTrue(
            election._votes() == 1,
            "Total votes not correct"
        );
    }

    function testRemoveVote() public {
        election.vote(acc1);
        election.removeVote(acc1);
        assertTrue(
            election._votes() == 0,
            "Total votes not decremented"
        );
    }

    function testRemoveVoteFail() public {
        vm.expectRevert(bytes("Election: Address has not voted"));
        election.removeVote(acc1);
    }
}