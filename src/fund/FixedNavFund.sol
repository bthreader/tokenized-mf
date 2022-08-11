// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";

abstract contract FixedNavFund is AbstractFund {
    // function price() public pure override returns (uint) {
    //     return 10;
    // }
    
    // function placeBuyNavOrder(uint256 shares) 
    //     public
    //     payable
    //     override
    //     onlyVerified 
    //     sharesNotZero(shares) 
    // {}
    
    /**
     * @dev Performs order matching
     *
     * @param sharesToMatch Size of the order
     *
     * @return MatchingReport Record of shares bought or sold and who is owed what 
     * in terms of shares (shares or their equivalent in cash)
     */
    //function matchOrder(uint256 sharesToMatch) public returns (MatchingReport) {        
        // Match[] memory matches;
        // matches = new Match[]();
        // MatchingReport report;
        
        // // No orders in the queue
        // if (_headId == 0) {
        //     report = new MatchingReport({matchedShares : 0, matches : matches});
        //     return report;
        // }
        
        // // Temporary pointers for traversing queue
        // Match result;
        // uint256 matchedShares;
        // uint256 i;
        // uint256 candidateOrderId;

        // // Pointer for our report array
        // i = 0;

        // // Pointer for the LL
        // candidateOrderId = _headId;

        // while (sharesToMatch > 0) {
        //     // No more orders to evaluate
        //     if (candidateOrderId == 0) {break;}
 
        //     // Handle the order
        //     result = handleOrder({
        //         queuedOrder : _orders[candidateOrderId],
        //         sharesToMatch : sharesToMatch
        //     });

        //     // Update pointers
        //     matches[i] = result;
        //     matchedShares += result._shares();
        //     sharesToMatch -= matchedShares;

        //     // Check if order fulfilled
        //     if (sharesToMatch == 0) {break;}
            
        //     // Next match
        //     candidateOrderId = _orders[candidateOrderId].nextId;
        //     i += 1;
        // }
        
        // report = new MatchingReport({matchedShares : matchedShares, matches : matches});
        
        // return report;
    //}

    /**
     * @dev Evaluates an existing order `queuedOrder` against the currently executing  
     * order which at maximum would like to transact `sharesToMatch`
     */
    // function handleOrder(NavOrder memory queuedOrder, uint256 sharesToMatch) 
    //     public 
    //     returns (Match) 
    // {
    // //     uint256 matchedShares;
    //     Match result;
    //     address counterparty = queuedOrder.addr;

    //     if (queuedOrder.shares <= sharesToMatch) {
    //         // Match the full order
    //         matchedShares = queuedOrder.shares;
            
    //         // Delete the order
    //         deleteOrder(queuedOrder.id);
    //     }

    //     else {
    //         // Match part of the order
    //         matchedShares = sharesToMatch;

    //         // Adjust the order
    //         modifyOrder({id : queuedOrder.id, add : false, shares : sharesToMatch});
    //     }

    //     result = new Match({
    //         counterparty : counterparty,
    //         shares : matchedShares
    //     });

    //     return (result);
    // }
    // }

    // function placeSellNavOrder(uint256 shares) 
    //     public 
    //     override
    //     sharesNotZero(shares) 
    // {
    //     // require(
    //     //     balances[msg.sender] >= shares,
    //     //     "Insufficient shares to sell, transaction rejected"
    //     // );
    //     // payable(msg.sender).transfer(price() * shares);

    //     // balances[msg.sender] -= shares;
    //     // totalShares -= shares;
    // }
}