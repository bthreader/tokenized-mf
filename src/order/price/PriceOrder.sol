// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Order} from "../Order.sol";

abstract contract PriceOrder is Order {
    uint256 public _price;

    // Over-write constructor to add price
    constructor (
        uint256 id,
        uint256 nextId,
        uint256 prevId,
        address addr,
        uint256 shares,
        uint256 price
    )
    {
        _id = id;
        _nextId = nextId;
        _prevId = prevId;
        _addr = addr;
        _shares = shares;
        _price = price;
    }
}