// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Order} from "../Order.sol";

abstract contract PriceOrder is Order {
    uint256 public _price;
}