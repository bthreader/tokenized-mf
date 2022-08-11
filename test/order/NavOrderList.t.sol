// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {OrderList} from "../../src/order/nav/OrderList.sol";

contract ContractTest is Test {
    OrderList private buyList;
    address private acc1 = address(0x1);
    address private acc2 = address(0x2);

    function setUp() public {
        buyList = new OrderList();
    }

    function testOrderAdded() public {
        uint256 orderId;
        orderId = buyList.enqueue({addr : acc1, shares : 50});
        assertTrue(
            buyList._headId() == orderId,
            "Order not inserted at head"
        );
        assertTrue(
            buyList._tailId() == orderId,
            "Single entry should also be tail"
        );
    }

    function testOrderAddedThenDeque() public {
        uint256 orderId;
        orderId = buyList.enqueue({addr : acc1, shares : 50});
        buyList.dequeue();
        assertTrue(buyList._headId() == 0, "LL not re-iniatilized");
        assertTrue(buyList._tailId() == 0, "LL not re-iniatilized");
    }

    function testOrderAddedThenDeleted() public {
        uint256 firstOrderId;
        uint256 secondOrderId;

        firstOrderId = buyList.enqueue({addr : acc1, shares : 50});
        secondOrderId = buyList.enqueue({addr : acc2, shares : 50});
        assertTrue(buyList._headId() == firstOrderId, "head id set wrong");
        assertTrue(buyList._tailId() == secondOrderId, "tail id set wrong");
    
        buyList.deleteId(secondOrderId);
        assertTrue(
            buyList._headId() == buyList._tailId(),
            "LL not re-iniatilized"
        );
    }
}
