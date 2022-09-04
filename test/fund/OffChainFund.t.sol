// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {OffChainFund} from "../../src/fund/OffChainFund.sol";

contract OffChainFundTest is Test, GenericTest {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    OffChainFund public fund;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    event QueuedOrderActioned(
        address indexed buyer, 
        address indexed seller, 
        uint256 shares,
        uint256 price,
        bool partiallyExecuted,
        uint256 sellOrderId
    );

    /// -----------------------------
    ///         Setup
    /// -----------------------------

    function setUp() public {
        vm.startPrank(acc1);
        fund = new OffChainFund();
        // Add accountants
        fund.addAccountant(acc1);
        // Set price = 100
        fund.setNav(100);
        // Add verifiers
        fund.addVerifier(acc1);
        fund.addVerified(acc2);
        // Add verified
        fund.addVerified(acc3);
        vm.stopPrank();
    }

    /// -----------------------------
    ///         Tests
    /// -----------------------------
    
    function testBuyOrder() public {
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        // 10 * 100 Wei = 1000
        fund.placeBuyNavOrder{ value : 1000 }();
        assertTrue(
            fund.balanceOf(acc2) == 10,
            "Shares not added to account"
        );
        assertTrue(
            fund.totalSupply() == 11,
            "Supply not changed"
        );
    }

    function testSellOrderQueued() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        fund.placeSellNavOrder(10);
        assertTrue(
            fund.myCustodyAccountBalance() == 10,
            "Funds not added to custody account"
        );
        assertTrue(
            fund.balanceOf(acc2) == 0,
            "Funds not removed from main account"
        );
        assertTrue(
            fund.totalSupply() == 11,
            "(False) change to supply"
        );
        vm.stopPrank();
    }

    function testDeleteQueuedSellOrder() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        uint256 orderId = fund.placeSellNavOrder(10);
        fund.cancelQueuedSellNavOrder(orderId);
        (address addr, uint256 shares) 
            = fund.getQueuedSellNavOrderDetails(orderId);
        assertTrue(addr == address(0), "Order still exists");
        assertTrue(
            fund.myCustodyAccountBalance() == 0,
            "Shares not removed from custody account"
        );
        assertTrue(
            fund.balanceOf(acc2) == 10,
            "Shares not put back into main account"
        );
        vm.stopPrank();
    }

    function testSellOrderExecuted() public {
        // Set up
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        fund.placeSellNavOrder(10);
        vm.stopPrank();

        // Set NAV per share == 100
        vm.prank(acc1);
        fund.setNav(1100);

        assertTrue(
            fund.navPerShare() == 100,
            "NAV per share not updated"
        );

        // Buy the shares from the seller
        vm.deal(acc3, 1001);
        vm.expectEmit(
            true, true, false, false,
            address(fund)
        );
        emit QueuedOrderActioned({
            buyer : acc3, 
            seller : acc2, 
            shares : 10,
            price : 100,
            partiallyExecuted : false,
            sellOrderId : 1
        });
        vm.prank(acc3);
        fund.placeBuyNavOrder{ value : 1001 }();

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
            fund.totalSupply() == 11,
            "Supply shouldn't have changed"
        );
    }
}