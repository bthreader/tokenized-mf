// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";

contract FixedNavFund is AbstractFund {
    
    /// -----------------------------
    ///         External
    /// -----------------------------
    
    /**
     * @dev See {AbstractFund-placeBuyNavOrder}.
     */
    function placeBuyNavOrder(uint256 shares, bool queueIfPartial)
        external
        payable
        override
        onlyVerified
        returns (bool success, uint256 orderId)
    {
        uint256 price = navPerShare();
    
        //
        // Prep to traverse sell queue
        //
        
        // Define
        address candidateAddr;
        uint256 candidateShares;
        uint256 sharesToExecute = min(shares, (msg.value / price));
        uint256 remainingSharesToExecute = sharesToExecute;
        uint256 head = _navSellOrders._headId();

        //
        // Traverse sell queue
        //

        /**
         * @dev While there are
         * -> outstanding shares in the order which the buyer can afford 
         * -> sellers to sell them
         */
        while ((remainingSharesToExecute > 0) && (head != 0)) {
            (candidateAddr, candidateShares)
                = _navSellOrders.getOrderDetails(head);
            
            // Fully execute buy and partially execute sell
            if (candidateShares > remainingSharesToExecute) {
                // Send the money and add shares
                payable(candidateAddr).transfer(
                    remainingSharesToExecute * price
                );

                _transferFromCustody({
                    from : candidateAddr,
                    to : msg.sender,
                    amount : remainingSharesToExecute
                });

                // Log
                emit QueuedOrderActioned({
                    buyer : msg.sender,
                    seller : candidateAddr,
                    shares : remainingSharesToExecute,
                    price : price,
                    partiallyExecuted : true,
                    queuedOrderId : head
                });

                remainingSharesToExecute = 0;
                break;
            }
            
            // Fully execute sell and potentially buy
            else {
                // Send the money and add shares
                payable(candidateAddr).transfer(candidateShares * price);

                _transferFromCustody({
                    from : candidateAddr,
                    to : msg.sender,
                    amount : candidateShares
                });

                // Log
                emit QueuedOrderActioned({
                    buyer : msg.sender,
                    seller : candidateAddr,
                    shares : candidateShares,
                    price : price,
                    partiallyExecuted : false,
                    queuedOrderId : head
                });

                if (candidateShares == remainingSharesToExecute) {
                    remainingSharesToExecute = 0;
                    break;
                }

                else {
                    unchecked{
                        remainingSharesToExecute -= candidateShares;
                    }

                    _navSellOrders.dequeue();
                    head = _navSellOrders._headId();
                    continue;
                }  
            }
        }

        //
        // Workout where that leaves us
        //

        // Executed what we could
        if (remainingSharesToExecute == 0) {
            // Full order executed - may need a refund
            if (sharesToExecute == shares) {
                payable(msg.sender).transfer(msg.value - (price * shares));
                return (true, 0); 
            }

            // Order partially executed but we executed what we could
            else if (sharesToExecute < shares) {
                if (queueIfPartial) {
                    // Put any remaining cash in brokerage account
                    _brokerageAccounts[msg.sender] 
                        += msg.value - (sharesToExecute * price);

                    // Queue the remaining shares
                    orderId = _navBuyOrders.enqueue({
                        addr : msg.sender,
                        shares : (shares - sharesToExecute)
                    });

                    return (false, orderId);
                }                
                else {
                    return (false, 0);
                }
            }
        }

        else {
            uint256 boughtShares = sharesToExecute - remainingSharesToExecute;
            
            if (queueIfPartial) {
                // Put remaining cash in the broker account
                unchecked {
                    _brokerageAccounts[msg.sender] += 
                        (msg.value - (boughtShares * price));
                }

                // Work out total outstanding
                uint256 outstanding = 
                    remainingSharesToExecute + (shares - sharesToExecute);

                // Queue the outstanding
                orderId = _navBuyOrders.enqueue({
                    addr : msg.sender,
                    shares : outstanding
                });

                return (false, orderId);
            }

            else {
                payable(msg.sender).transfer(
                    msg.value - (boughtShares * price)
                );
                return (false, 0);
            }
        }
    }

    /**
     * @dev See {AbstractFund-placeSellNavOrder}.
     */
    function placeSellNavOrder(uint256 shares, bool queueIfPartial) 
        external 
        override
        onlyVerified
        returns (bool success, uint256 orderId) 
    {
        // Complicated part is ensuring buy order placer has sufficient funds in brokerage account
        return (true, 0);
    }

    function closeNavOrders()
        external
        override
        onlyAdmin
    {
        uint256 price = navPerShare();
        address clientAddr;
        uint256 clientShares;

        // Close the buy orders
        if (_navBuyOrders._headId() != 0) {
            while (_navBuyOrders._headId() != 0) {
                continue;
            }
        }

        else if (_navSellOrders._headId() != 0) {
            uint256 head = _navSellOrders._headId();
            while (head != 0) {
                (clientAddr, clientShares)
                    = _navSellOrders.getOrderDetails(head);

                payable(clientAddr).transfer(price * clientShares);
                
                unchecked {
                    _custodyAccounts[clientAddr] -= clientShares;
                }
            }
        }

        else {
            return;
        }
    }

    /// -----------------------------
    ///         Public
    /// -----------------------------
    
    /**
     * @dev See {AbstractFund-nav}.
     */
    function nav() public pure override returns (uint256) {
        return 100;
    }

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {return a;}
        return b;
    }

    function _transferFromCustody(address from, address to, uint256 amount) 
        internal 
    {
        unchecked {
            _custodyAccounts[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer({from : from, to : to, value : amount});
    }
}
