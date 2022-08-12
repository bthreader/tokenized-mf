// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractOrderList} from "./AbstractOrderList.sol";

/** 
 * @dev Implementation of an order list where we store the address of the
 * placer and the size of the order. 
 * 
 * Data encoded as (placer address, size).
 * 
 * Used for NAV based orders where there is no bid-ask associated with the
 * order. 
 */ 
contract OrderList is AbstractOrderList {
    
    /// -----------------------------
    ///         External
    /// -----------------------------
    
    /** 
     * @dev Adds order from `addr` of size `shares` to the back of the queue.
     * 
     * @return newId The assigned id of the order
     */   
    function enqueue(address addr, uint256 shares) 
        external
        returns (uint256 newId) 
    {
        // Prepare other elements in the LL
        // uint256 newId;
        uint256 prevId;

        // Case 1: empty LL
        if (_headId == 0) {
            newId = _incrementer = 1;
            
            // Set the order as the head and tail
            _headId = _tailId = newId;
            
            prevId = 0;
        }

        // Case 2: non-empty LL 
        else {
            newId = _incrementer;
            // Update the tail
            _orders[_tailId].nextId = newId;
            _tailId = newId;
            
            prevId = _tailId;
        }

        // Encode the data
        bytes memory data = abi.encodePacked(addr, shares);

        // Add the order information to LL
        _orders[newId] = Order({
            id : newId,
            nextId : 0,
            prevId : prevId,
            data : data
        });

        return newId;
    }

    function changeSharesOnId(uint256 id, bool add, uint256 shares) external {
        uint256 currentShares;
        address addr;
        uint256 newShares;

        (addr, currentShares) = decode(_orders[id].data);
        
        if (add) {
            newShares = currentShares + shares;
        }
        else {
            require(
                currentShares >= shares,
                "Can't remove more shares than are in the order"
            );

            newShares = currentShares - shares;
        }

        changeData({id : id, newData : abi.encodePacked(addr, newShares)});
    }

    /// -----------------------------
    ///         Public
    /// -----------------------------

    function decode(bytes memory data) 
        public 
        pure 
        returns (address addr, uint256 shares) 
    {
        (addr, shares) = abi.decode(data, (address, uint256));
    }
}
