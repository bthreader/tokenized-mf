// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/** 
 * @dev Doesn't define any methods for data insertion, as this is
 * implementation dependent.
 */
abstract contract AbstractOrderList {       
    
    /// -----------------------------
    ///         Types
    /// -----------------------------
    
    /** 
     * @dev Order representation, an id of 0 corresponds to null
     * e.g. a node with prevId = 0 is the head
     */
    struct Order {
        uint256 id;
        uint256 nextId;
        uint256 prevId;
        bytes data;
    }

    /// -----------------------------
    ///         State
    /// -----------------------------
    
    mapping(uint256 => Order) internal _orders;
    uint256 public _headId;
    uint256 public _tailId;
    uint256 internal _incrementer; // Index generator

    /// -----------------------------
    ///         External
    /// -----------------------------

    function dequeue() external {
        // Single order case
        if (_headId == _tailId) {
            delete _orders[_headId];
            _headId = _tailId = 0;
            return;
        }

        uint256 oldHeadId = _headId;

        // Over-write pointer
        _headId = _orders[_headId].nextId;
        _orders[_headId].prevId = 0;

        // Delete
        delete _orders[oldHeadId];
    }

    /**
     * @dev Delete order with id=`id`, used when we want to remove an order
     * but cannot assume it's at the head.
     */
    function deleteId(uint256 id) external {
        uint256 prevId = _orders[id].prevId;
        uint256 nextId = _orders[id].nextId;
        
        // Single order case
        if ((prevId == 0) && (nextId == 0)) {
            _headId = 0;
            _tailId = 0;
        }

        // Order is first entry
        else if (prevId == 0) {
            _orders[nextId].prevId = 0;
            _headId = _orders[nextId].id;
        }

        // Order is last entry
        else if (nextId == 0) {
            _orders[prevId].nextId = 0;
            _tailId = _orders[prevId].id;
        }

        // Sandwich case
        else {
            _orders[prevId].nextId = nextId;
            _orders[nextId].prevId = prevId;
        }
        
        delete _orders[id];
    }

    function next(uint256 id) external view returns (uint256) {
        return _orders[id].nextId;
    }

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    /**
     * @dev Modify the data of a queued order, setting data = `data`
     */
    function _changeData(uint256 id, bytes memory newData) internal {
        _orders[id].data = newData;
    }
}