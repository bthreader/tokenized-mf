// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract AbstractOrderList {       
    uint256 public _headId;
    uint256 public _tailId;
    uint256 internal _incrementer; // Index generator

    /** 
     * @param addr Address placing the order
     * @param shares Number of shares for the order
     *
     * @return uint256 The id of the order for customer reference
     */
    function enqueue(address addr, uint256 shares) 
        public 
        virtual 
        returns (uint) {}

    function dequeue() public virtual {}
    
    /**
     * @dev Delete order with ID `id` for when we don't know
     * where the node is
     */
    function deleteId(uint256 id) public virtual {}

    /**
     * @dev Modify a queued order, allows orders to be adjusted
     * if they are partially executed
     * 
     * @param id Order ID
     * @param add Flag for indicating add (true) or remove (false)
     * @param shares Delta
     */
    function changeSharesOnId(uint256 id, bool add, uint256 shares) 
        public
        virtual {}
}