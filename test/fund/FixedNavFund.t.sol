// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {FixedNavFund} from "../../src/fund/FixedNavFund.sol";

contract FixedNavFundTest is Test, GenericTest {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    FixedNavFund public fund;

    constructor () {
        vm.startPrank(acc1);
        fund = new FixedNavFund();
        fund.addVerifier(acc1);
        fund.addVerified(acc2);
        fund.addVerified(acc3);
        vm.stopPrank();
    }

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event QueuedOrderActioned(
        address indexed buyer, 
        address indexed seller, 
        uint256 shares,
        uint256 price,
        bool partiallyExecuted,
        uint256 buyOrderId,
        uint256 sellOrderId
    );

    /// -----------------------------
    ///         Tests
    /// -----------------------------
    
    function testBuyOrderAdded() public {
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        (bool result, uint256 orderId) = fund.placeBuyNavOrder{ value : 1000 }({
            shares : 10,
            queueIfPartial : true
        });
        
        assertTrue(
            result == false,
            "Order falsely indicating fulfillment"
        );
        assertTrue(
            orderId == 1,
            "Incrementer not working as expected"
        );
        vm.prank(acc2);
        assertTrue(
            fund.myBrokerageAccountBalance() == 1000,
            "Funds not added to brokerage account"
        );
        (address enteredAddr, uint256 enteredShares) 
            = fund.getBuyNavOrderDetails(orderId);
        assertTrue(
            (enteredAddr == acc2) && (enteredShares == 10),
            "Order details not inputted properly to queue"
        );
        
        // Test for (unwanted) side effects
        assertTrue(
            fund.navPerShare() == 100,
            "Unwanted price change"
        );
        assertTrue(
            fund.totalSupply() == 1,
            "Unwanted supply change"
        );
    }

    function testDeleteBuyOrder() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        (bool result, uint256 orderId) 
            = fund.placeBuyNavOrder{ value : 1000 }({
                shares : 10,
                queueIfPartial : true
        });
        fund.cancelBuyNavOrder(orderId);
        (address addr, uint256 shares) = fund.getBuyNavOrderDetails(orderId);
        assertTrue(addr == address(0), "Order still exists");
        assertTrue(shares == 0, "Order still exists");
    }

    function testCloseBuyOrder() public {
        // Set up
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }({
            shares : 10,
            queueIfPartial : true
        });

        // Close
        vm.expectEmit(
            true, true, false, false,
            address(fund)
        );
        emit QueuedOrderActioned({
            buyer : acc2, 
            seller : address(fund), 
            shares : 10,
            price : 100,
            partiallyExecuted : false,
            buyOrderId : 1,
            sellOrderId : 0
        });
        vm.prank(acc1);
        fund.closeNavOrders();

        assertTrue(fund.balanceOf(acc2) == 10, "Order not closed");
        
        // Check state
        assertTrue(
            fund.navPerShare() == 9,
            "Incorrect price"
        );
        assertTrue(
            fund.totalSupply() == 11,
            "Incorrect supply"
        );
        vm.prank(acc2);
        assertTrue(
            fund.myBrokerageAccountBalance() == 0,
            "Funds not removed from brokerage account"
        );
    }

    function testSellOrderAdded() public {
        // Set up
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }({
            shares : 10,
            queueIfPartial : true
        });
        vm.prank(acc1);
        fund.closeNavOrders();
        
        // acc2 now has shares -> place sell order
        vm.prank(acc2);
        (bool result, uint256 orderId) = fund.placeSellNavOrder({
            shares : 10,
            queueIfPartial : true
        });

        // Check it was placed correctly
        assertTrue(
            result == false,
            "Order falsely indicating fulfillment"
        );
        assertTrue(
            orderId == 1,
            "Incrementer not working as expected"
        );

        // Check the custody mechanism works
        vm.prank(acc2);
        assertTrue(
            fund.myCustodyAccountBalance() == 10,
            "Funds not added to custody account"
        );
        assertTrue(
            fund.balanceOf(acc2) == 0,
            "Funds not removed from main account"
        );

        // Test for (unwanted) side effects
        assertTrue(
            fund.navPerShare() == 9,
            "Incorrect price"
        );
        assertTrue(
            fund.totalSupply() == 11,
            "Incorrect supply"
        );
    }

    function testSellOrderExecuted() public {
        // Set up
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }({
            shares : 10,
            queueIfPartial : true
        });
        vm.prank(acc1);
        fund.closeNavOrders();
        vm.prank(acc2);
        fund.placeSellNavOrder({
            shares : 10,
            queueIfPartial : true
        });

        // Buy the shares from the seller
        vm.deal(acc3, 91);
        vm.expectEmit(
            true, true, false, false,
            address(fund)
        );
        emit QueuedOrderActioned({
            buyer : acc3, 
            seller : acc2, 
            shares : 10,
            price : 9,
            partiallyExecuted : false,
            buyOrderId : 0,
            sellOrderId : 1
        });
        vm.prank(acc3);
        fund.placeBuyNavOrder{ value : 91 }({
            shares : 10,
            queueIfPartial : false
        });

        assertTrue(
            acc3.balance == 1,
            "Excess money in buy order not refunded"    
        );
        vm.prank(acc2);
        assertTrue(
            fund.myCustodyAccountBalance() == 0, 
            "Shares not taken out of custody account"
        );
        assertTrue(fund.balanceOf(acc3) == 10, "Order not closed");
        assertTrue(
            fund.navPerShare() == 9,
            "Price shouldn't have changed"
        );
        assertTrue(
            fund.totalSupply() == 11,
            "Supply shouldn't have changed"
        );
    }
}