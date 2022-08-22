// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {FixedNavFund} from "../../src/fund/FixedNavFund.sol";

contract SetUpFund is Test, GenericTest {
    FixedNavFund public fund;

    constructor () {
        vm.startPrank(acc1);
        fund = new FixedNavFund();
        fund.addVerifier(acc1);
        fund.addVerified(acc2);
        fund.addVerified(acc3);
        vm.stopPrank();
    }
}

contract FixedNavFundTest is SetUpFund {
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

        assertTrue(
            fund.navPerShare() == 100,
            "Unwanted price change"
        );

        assertTrue(
            fund.totalSupply() == 1,
            "Unwanted supply change"
        );

        vm.prank(acc2);
        assertTrue(
            fund.myBrokerageAccountBalance() == 1000,
            "Funds not added to brokerage account"
        );

        (address enteredAddr, uint256 enteredShares) = fund.getOrderDetails({
            id : orderId, 
            buy : true
        });

        assertTrue(
            (enteredAddr == acc2) && (enteredShares == 10),
            "Order details not inputted properly to queue"
        );
    }

    function testCloseBuyOrder() public {
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        fund.placeBuyNavOrder{ value : 1000 }({
            shares : 10,
            queueIfPartial : true
        });

        vm.prank(acc1);
        fund.closeNavOrders();

        assertTrue(fund.balanceOf(acc2) == 10, "Couldn't close orders");

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
}