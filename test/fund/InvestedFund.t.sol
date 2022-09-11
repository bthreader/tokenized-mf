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
    address[] public investments;
    uint256[] public weights;
    Asset public assetA;
    Asset public assetB;

    /// -----------------------------
    ///         Setup
    /// -----------------------------

    function setUp() public {
        //
        // Create some assets
        //

        // Asset A - price = 25
        assetA = new Asset();
        vm.deal(acc1, 25);
        vm.prank(acc1);
        assetA.topUp{ value : 25 }();

        // Asset B - price = 50
        assetB = new Asset();
        vm.deal(acc1, 50);
        vm.prank(acc1);
        assetB.topUp{ value : 50 }();

        //
        // Create a fund - price = 100
        //

        investments.push(address(assetA));
        investments.push(address(assetB));
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
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------

    function testWrongLengthsInputs() public {
        delete weights;
        weights.push(49);
        weights.push(49);
        weights.push(2);
        vm.expectRevert(bytes(
            "Fund: length mismatch between investments and weights"
        ));
        fund = new InvestedFund({
            investments : investments,
            weights : weights
        });
    }
    
    function testBadWeights() public {        
        delete weights;
        weights.push(50);
        weights.push(51);

        vm.expectRevert(bytes(
            "Fund: weights must add to 100"
        ));
        fund = new InvestedFund({
            investments : investments,
            weights : weights
        });
    }

    function testBuy() public {
        vm.deal(acc2, 100);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 100 }();
        assertTrue(
            fund.balanceOf(acc2) == 1,
            "Balance not added"
        );
        assertTrue(
            fund.navPerShare() == 100,
            "Unexpected price change"
        );
        assertTrue(
            fund.valueOfInvestments() == 200,
            "New cash not invested"
        );
        uint256[] memory ownedShares = fund.ownedShares();
        // 100 / 25 = 4
        assertTrue(
            ownedShares[0] == 4,
            "Asset A not re-allocated"
        );
        // 100 / 50 = 2
        assertTrue(
            ownedShares[1] == 2,
            "Asset B not re-allocated"
        );
    }

    function testSell() public {
        vm.deal(acc2, 100);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 100 }();
        vm.prank(acc2);
        fund.placeSellNavOrder(1);
        assertTrue(
            acc2.balance == 100,
            "Money not transferred"
        );
        assertTrue(
            fund.valueOfInvestments() == 100,
            "Value of investments not adjusted"
        );
        uint256[] memory ownedShares = fund.ownedShares();
        // 50 / 25 = 2
        assertTrue(
            ownedShares[0] == 2,
            "Asset A not re-allocated"
        );
        // 50 / 50 = 1
        assertTrue(
            ownedShares[1] == 1,
            "Asset B not re-allocated"
        );
    }

    function testSellFail() public {
        vm.prank(acc2);
        vm.expectRevert("Fund: insufficient balance to place sell order");
        fund.placeSellNavOrder(666);
    }

    function testAssetPriceIncrease() public {
        fund.rebalance();
        assertTrue(
            fund.valueOfInvestments() == 100,
            "Value of investments not updated"
        );
        // Increase Asset A price to 50
        // Currently 3 shares @ 25 = 75 (2 owned by fund)
        // Double the price => add 75
        vm.deal(acc1, 75);
        vm.prank(acc1);
        assetA.topUp{ value : 75 }();
        assertTrue(
            assetA.pricePerShare() == 50,
            "Asset A price increase not successful"
        );
        // (50 * 2) + (50 * 1) = 150
        assertTrue(
            fund.valueOfInvestments() == 150,
            "Value of investments not updated"
        );
        fund.rebalance();
        // (50 * 1) + (50 * 1) = 100
        assertTrue(
            fund.valueOfInvestments() == 100,
            "Value of investments not updated"
        );
        uint256[] memory ownedShares = fund.ownedShares();
        // 150 floor div 50 = 1
        assertTrue(
            ownedShares[0] == 1,
            "Asset A not re-allocated"
        );
        // 150 floor div 50 = 1
        assertTrue(
            ownedShares[1] == 1,
            "Asset B not re-allocated"
        );
    }
}
