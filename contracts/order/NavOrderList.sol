// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Match} from "./Match.sol";
import {MatchingReport} from "./MatchingReport.sol";

contract NavOrderList {
    uint public _headId;
    uint public _tailId;
    uint private _incrementer;
    mapping(uint => NavOrder) public _orders;

    constructor () {
        _headId = 0;
        _tailId = 0;
        _incrementer = 1;
    }
    
    /** 
     * @dev Representation of an order object, ID = 0 is the null 
     * representation
     *
     * @param id Order ID
     * @param nextId ID of an newer order or null (0) 
     * @param prevId ID of an older order or null (0)
     * @param addr Address placing the order
     * @param shares Number of shares for the order
     */ 
    struct NavOrder {
        uint id;
        uint nextId;
        uint prevId;
        address addr;
        uint shares;
    }

    /**
     * @param orderId ID of the order to delete
     */
    function deleteOrder(uint256 orderId) public {
        NavOrder storage prev = _orders[_orders[orderId].prevId];
        NavOrder storage next = _orders[_orders[orderId].nextId];

        // Single order case
        if (prev.id == 0 && next.id == 0) {
            _headId = 0;
            _tailId = 0;
        }

        // Order is first entry
        if (prev.id == 0) {
            next.prevId = 0;
            _headId = next.id;
        }

        // Order is last entry
        else if (next.id == 0) {
            prev.nextId = 0;
            _tailId = prev.id;
        }

        // Sandwich case
        else {
            prev.nextId = next.id;
            next.prevId = prev.id;
        }
        
        delete _orders[orderId];
    }

    /** 
     * @param addr Address placing the order
     * @param shares Number of shares for the order
     *
     * @return uint The id of the order for customer reference
     */
    function queueOrder(address addr, uint shares) public returns (uint) {
        uint newId;
        uint prevId;

        // Empty LL
        if (_headId == 0) {
            newId = _incrementer = 1;
            
            // Set the order as the head and tail
            _headId = _tailId = newId;
            
            prevId = 0;
        }

        // Non-empty LL
        else {
            newId = _incrementer;
            // Update the tail
            _orders[_tailId].nextId = newId;
            _tailId = newId;
            
            prevId = _tailId;
        }

        // Add the order information to LL
        _orders[newId] = NavOrder({
            id : newId,
            nextId : 0,
            prevId : prevId,
            addr : addr,
            shares : shares
        });

        return newId;
    }

    /**
     * @dev Performs order matching
     *
     * @param sharesToMatch Size of the order
     *
     * @return MatchingReport Record of shares bought or sold and who is owed what 
     * in terms of shares (shares or their equivalent in cash)
     */
    function matchOrder(uint sharesToMatch) public returns (MatchingReport) {        
        Match[] memory matches;
        MatchingReport report;
        
        if (_headId == 0) {
            // Empty array
            report = new MatchingReport({matchedVolume : 0, matches : matches});
            return report;
        }
        
        Match currentMatch;
        uint256 matchedVolume;
        uint256 currentOrderMatchedShares;
        address counterparty;
        uint256 i;
        NavOrder memory currentOrder;

        i = 0;
        currentOrder = _orders[_headId];

        while (sharesToMatch > 0) {
            // Record the counterparty 
            counterparty = currentOrder.addr;
            
            if (currentOrder.shares <= sharesToMatch) {
                // Match the full order
                currentOrderMatchedShares = currentOrder.shares;
                
                // Delete the order
                deleteOrder(currentOrder.id);
            }

            else {
                // Match part of the order
                currentOrderMatchedShares -= sharesToMatch;

                // Adjust the order
                currentOrder.shares -= currentOrderMatchedShares;
            }

            // Increment
            matchedVolume += currentOrderMatchedShares;
            sharesToMatch -= currentOrderMatchedShares;
            
            // Record the match
            currentMatch = new Match({
                counterparty : currentOrder.addr,
                shares : currentOrderMatchedShares
            });
            matches[i] = currentMatch;
            
            // Next match
            i += 1;

            // Go to the next order
        }
        
        report = new MatchingReport({matchedVolume : matchedVolume, matches : matches});
        
        return report;
    }
}
