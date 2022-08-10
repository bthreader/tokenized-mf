// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Match {
    address public _counterparty;
    uint public _shares;

    constructor (address counterparty, uint256 shares) {
        _counterparty = counterparty;
        _shares = shares;
    }
}