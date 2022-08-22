// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {SimpleVerify} from "../../src/kyc/SimpleVerify.sol";

contract SimpleVerifyTest is Test, GenericTest {
    SimpleVerify private verificationContract;
    
    /**
     * @dev acc1 becomes the first admin
     */
    function setUp() public {
        vm.prank(acc1);
        verificationContract = new SimpleVerify();
    }

    function testOneAddsTwoAsVerifier() public {
        // Analysed action
        vm.prank(acc1);
        verificationContract.addVerifier(acc2);
        assertTrue(
            verificationContract.isVerifier(acc2), 
            "address not a verifier"
        );
    }

    function testTwoVerifiesThree() public {
        // Set up
        vm.prank(acc1);
        verificationContract.addVerifier(acc2);
        
        // Analysed action
        vm.prank(acc2);
        verificationContract.addVerified(acc3);
        assertTrue(
            verificationContract.isVerified(acc3),
            "address not verified"
        );
    }

    function testOneRemovesTwoFromVerifiers() public {
        // Set up
        vm.prank(acc1);
        verificationContract.addVerifier(acc2);
        vm.prank(acc2);
        verificationContract.addVerified(acc3);
        
        // Analysed action
        vm.prank(acc1);
        verificationContract.removeVerifier(acc2);
        
        assertTrue(
            !verificationContract.isVerifier(acc2),
            "address is still a verifier"
        );
    }
}