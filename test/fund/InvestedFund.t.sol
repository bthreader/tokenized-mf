// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {InvestedFund} from "../../src/fund/InvestedFund.sol";
import {Asset} from "../../src/asset/Asset.sol";

contract InvestedFundTest is Test, GenericTest {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    InvestedFund public fund;
    // Can't have dynamic memory arrays so put them in storage
    Asset[] public investments;
    uint256[] public weights;

    constructor () {
        //
        // Create some assets
        //

        // Asset A - price = 25
        Asset assetA = new Asset();
        vm.deal(acc1, 25);
        vm.prank(acc1);
        assetA.topUp{ value : 25 }();

        // Asset B - price = 50
        Asset assetB = new Asset();
        vm.deal(acc1, 50);
        vm.prank(acc1);
        assetB.topUp{ value : 50 }();

        //
        // Create a fund - price = 100
        //

        investments.push(assetA);
        investments.push(assetB);
        weights.push(50);
        weights.push(50);

        vm.deal(acc1,100);
        vm.startPrank(acc1);
        fund = new InvestedFund({
            investments : investments,
            weights : weights
        });
        fund.topUp{ value : 100 }();
        fund.addVerifier(acc1);
        fund.addVerified(acc2);
        fund.addVerified(acc3);
        vm.stopPrank();

        // acc2 buys a share
        vm.deal(acc2, 100);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 100 }({
            shares : 1,
            queueIfPartial : true
        });
        vm.prank(acc1);
        fund.closeNavOrders();
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------

    function testSetUpWasCorrect() public {
        assertTrue(
            fund.nav() == 200,
            "NAV not set correctly"
        );
    }

    function testAllocate() public {
        fund.rebalance();
        uint256[] memory ownedShares;
        ownedShares = fund.ownedShares();

        // 4 * 25 = 100
        assertTrue(
            ownedShares[0] == 4,
            "Allocation was wrong"
        );

        // 2 * 50 = 100
        assertTrue(
            ownedShares[1] == 2,
            "Allocation was wrong"
        );
    }

    function testTopUpThenRebalance() public {
        fund.rebalance();
        
        // Fund is now 400 total value
        fund.topUp{ value : 200 }();
        fund.rebalance();
        uint256[] memory ownedShares;
        ownedShares = fund.ownedShares();

        // 8 * 25 = 200
        assertTrue(
            ownedShares[0] == 8,
            "Re-allocation was wrong"
        );

        // 4 * 50 = 200
        assertTrue(
            ownedShares[1] == 4,
            "Re-allocation was wrong"
        );
    }

    // Another test to see what happens if the price of the underlying
    // asset changes
}