// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "remix_tests.sol";
import "remix_accounts.sol";

import {NavOrderList} from "../contracts/order/NavOrderList.sol";
import {MatchingReport} from "../contracts/order/MatchingReport.sol";

contract NavOrderListTest {
    NavOrderList public buyList;
    address acc0;

    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
    }

    function beforeEach() public {
        buyList = new NavOrderList();
    }

    function orderAdded() public {
        uint256 orderId;
        orderId = buyList.queueOrder({addr : acc0, shares : 50});
        Assert.ok(buyList._headId() == orderId, "Order not inserted at head");
        Assert.ok(buyList._tailId() == orderId, "Single entry should also be tail");
    }

    function orderAddedThenDeleted() public {
        uint256 orderId;
        orderId = buyList.queueOrder({addr : acc0, shares : 50});
        buyList.deleteOrder(orderId);
        Assert.ok(buyList._headId() == 0, "LL not re-iniatilized");
        Assert.ok(buyList._tailId() == 0, "LL not re-iniatilized");
    }

    function orderAddedThenMatched() public {
        buyList.queueOrder({addr : acc0, shares : 50});
        MatchingReport result = buyList.matchOrder({sharesTo : 50});
        Assert.ok(result._matchedVolume() == 50, "order not matched");
    }
}