// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract AbstractOrderList {       
    uint256 public _headId;
    uint256 public _tailId;
    uint256 internal _incrementer; // Index generator

    /**
     * @dev Deleted order with ID `id` for when we don't know
     * where the node is
     */
    function deleteOrderById(uint256 id) public virtual {}
}