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

    event Transfer(address indexed from, address indexed to, uint256 value);

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

    function testCancelQueuedSellOrderFailsNotPlacer() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        uint256 orderId = fund.placeSellNavOrder(10);
        vm.stopPrank();

        vm.expectRevert(bytes("Fund: must be the order placer to cancel the order"));
        vm.prank(acc3);
        fund.cancelQueuedSellNavOrder(orderId);
    }

    function testCancelQueuedSellOrderFailsNoOrder() public {
        vm.expectRevert(bytes("Fund: order not in queue"));
        vm.prank(acc2);
        fund.cancelQueuedSellNavOrder(11111);
    }

    function testSellOrderExecutedViaBuyOrder() public {
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
        assertTrue(fund.balanceOf(acc3) == 10, "Order not executed");

        assertTrue(
            fund.totalSupply() == 11,
            "Supply shouldn't have changed"
        );
    }

    function testSellOrderExecutedViaClose() public {
        // Set up
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        fund.placeSellNavOrder(10);
        vm.stopPrank();

        // Set NAV per share == 100
        vm.startPrank(acc1);
        fund.setNav(1100);
        fund.closeSellNavOrders();
    }

    function testCloseFailsDueToLackOfCash() public {
        // Set up
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        fund.placeSellNavOrder(10);
        vm.stopPrank();

        // Set NAV per share == 100
        vm.startPrank(acc1);
        fund.setNav(1100);

        // Remove the cash needed to close the sell orders
        fund.withdraw(1000);
        
        vm.expectRevert(bytes(
            "Fund: run out of money to close sell orders"
        ));
        fund.closeSellNavOrders();
        vm.stopPrank();
    }

    //
    // ERC20 tests continued
    //

    function testTransfer() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        vm.expectEmit(true, true, false, false);
        emit Transfer({from : acc2, to : acc3, value : 10});
        fund.transfer({to : acc3, amount : 10});
        assertTrue(
            fund.balanceOf(acc3) == 10,
            "Shares not transferred"
        );
    }

    function testTransferFail() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        
        vm.expectRevert(bytes(
            "ERC20: can only transfer to verified customers"
        ));
        fund.transfer({to : address(0x66), amount : 10});
        assertTrue(
            fund.balanceOf(acc2) == 10,
            "Shares shouldn't have been transferred"
        );

        vm.expectRevert(bytes(
            "ERC20: insufficient funds to make transfer"
        ));
        fund.transfer({to : acc3, amount : 66});
    }

    function testTransferFrom() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        fund.approve({spender : acc3, amount: 10});
        address acc4 = address(0x14);
        vm.stopPrank();
        vm.prank(acc1);
        fund.addVerified(acc4);
        vm.prank(acc3);
        fund.transferFrom({from : acc2, to : acc4, amount : 10});
        assertTrue(
            fund.balanceOf(acc4) == 10,
            "Funds not transferred"
        );
    }

    function testTransferFromFail() public {
        vm.deal(acc2, 1000);
        vm.startPrank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        fund.approve({spender : acc3, amount: 10});
        vm.stopPrank();
        
        vm.startPrank(acc3);
        vm.expectRevert(bytes(
            "ERC20: can only transfer to verified customers"
        ));
        fund.transferFrom({from : acc2, to : address(0x66), amount : 10});
        
        vm.expectRevert(bytes(
            "ERC20: insufficient allowance to transfer"
        ));
        fund.transferFrom({from : acc2, to : acc3, amount : 66});
        vm.stopPrank();
        
        vm.prank(acc2);
        fund.increaseAllowance({spender : acc3, addedValue : 10});
        vm.expectRevert(bytes(
            "ERC20: owner has insufficient funds"
        ));
        vm.prank(acc3);
        fund.transferFrom({from : acc2, to : acc3, amount : 20});
    }

    function testBurnAndReissue() public {
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }();
        vm.prank(acc1);
        fund.burnAndReissue({oldAddr : acc2, newAddr : acc3});
        assertTrue(fund.balanceOf(acc3) == 10);
    }
}
