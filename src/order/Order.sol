// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Order {
    uint256 public _id;
    uint256 public _nextId;
    uint256 public _prevId;
    address public _addr;
    uint256 public _shares;

    constructor (
        uint256 id,
        uint256 nextId,
        uint256 prevId,
        address addr,
        uint256 shares
    )
    {
        _id = id;
        _nextId = nextId;
        _prevId = prevId;
        _addr = addr;
        _shares = shares;
    }

    function setNextId(uint256 id) public {
        _nextId = id;
    }

    function setPrevId(uint256 id) public {
        _prevId = id;
    }

    function setShares(uint256 shares) public {
        _shares = shares;
    }
}