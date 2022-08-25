// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";

abstract contract Fund is AbstractFund {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    constructor () {
        _balances[msg.sender] = 1;
        _totalShares += 1;
    }

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
        require(
            msg.value > 0,
            "Fund: msg.value must be greater than zero to place buy order"    
        );
        uint256 price = navPerShare();
    
        //
        // Prep to traverse sell queue
        //
        
        // Define
        address candidateAddr;
        uint256 candidateShares;
        uint256 sharesToExecute = _min(shares, (msg.value / price));
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

                _transferFromCustodyAccount({
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
                    buyOrderId : 0,
                    sellOrderId : head
                });

                remainingSharesToExecute = 0;
                break;
            }
            
            // Fully execute sell and potentially buy
            else {
                // Send the money and add shares
                payable(candidateAddr).transfer(candidateShares * price);

                _transferFromCustodyAccount({
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
                    buyOrderId : 0,
                    sellOrderId : head
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
        sharesNotZero(shares)
        returns (bool success, uint256 orderId) 
    {
        require(
            _balances[msg.sender] >= shares,
            "Fund: insufficient balance to place sell order"
        );

        uint256 price = navPerShare();
    
        //
        // Prep to traverse buy queue
        //
        
        // Define
        address candidateAddr;
        uint256 candidateShares;
        uint256 remainingSharesToExecute = shares;
        uint256 head = _navSellOrders._headId();
        uint256 actionableCandidateShares;

        //
        // Traverse buy queue
        //

        /**
         * @dev While there are
         * -> outstanding shares in the order 
         * -> buyers to buy them
         */
        while ((remainingSharesToExecute > 0) && (head != 0)) {
            (candidateAddr, candidateShares)
                = _navBuyOrders.getOrderDetails(head);

            // Cash the candidate has
            uint256 balance = _brokerageAccounts[candidateAddr];
            
            // Skip
            if (balance == 0) {
                head = _navSellOrders.next(head);
                continue;
            }

            actionableCandidateShares = _min(
                candidateShares, 
                balance / price
            );

            // Shares we're interested in
            uint256 sharesToExecute = _min(
                remainingSharesToExecute,
                actionableCandidateShares
            );

            // Skip
            if (sharesToExecute == 0) {
                head = _navSellOrders.next(head);
                continue;
            }

            // Action some of the shares then move on
            if (sharesToExecute < candidateShares) {
                _handleShareSale({
                    from : msg.sender,
                    to : candidateAddr,
                    amount : sharesToExecute,
                    price : price
                });
                _navBuyOrders.changeSharesOnId({
                    id : head,
                    add : false,
                    shares : candidateShares - sharesToExecute
                });

                // Log
                emit QueuedOrderActioned({
                    buyer : candidateAddr,
                    seller : msg.sender,
                    shares : sharesToExecute,
                    price : price,
                    partiallyExecuted : true,
                    buyOrderId : head,
                    sellOrderId : 0
                });

                head = _navSellOrders.next(head);
                remainingSharesToExecute -= sharesToExecute;
            }

            // Action full amount then dequeue the order
            else {
                _handleShareSale({
                    from : msg.sender,
                    to : candidateAddr,
                    amount : candidateShares,
                    price : price
                });
                _navSellOrders.dequeue();

                // Log
                emit QueuedOrderActioned({
                    buyer : candidateAddr,
                    seller : msg.sender,
                    shares : candidateShares,
                    price : price,
                    partiallyExecuted : false,
                    buyOrderId : head,
                    sellOrderId : 0
                });

                head = _navSellOrders._headId();
                remainingSharesToExecute -= candidateShares;
            }
        }
        
        //
        // Finish - decide action
        //

        if (remainingSharesToExecute > 0) {
            if (queueIfPartial) {
                orderId = _navSellOrders.enqueue({
                    addr : msg.sender,
                    shares : remainingSharesToExecute
                });

                _balances[msg.sender] -= remainingSharesToExecute;
                _custodyAccounts[msg.sender] += remainingSharesToExecute;
                return (false, orderId);
            }
            else {
                return (false, 0);
            }
        }
        
        return (true, 0);
    }

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {return a;}
        return b;
    }

    /// -----------------------------
    ///         Private
    /// -----------------------------

    function _handleShareSale(
        address from,
        address to,
        uint256 amount,
        uint256 price
    ) 
        private 
    {
        _transfer({
            from : from,
            to : to,
            amount : amount
        });

        uint256 amountToTransfer = amount * price;
        _brokerageAccounts[to] -= amountToTransfer;
        payable(from).transfer(amountToTransfer);
    }

    function _burnFromCustodyAccount(address addr, uint256 shares) private {
        _custodyAccounts[addr] -= shares;
        _totalShares -= shares;
        emit Transfer(addr, address(0), shares);
    }
}
