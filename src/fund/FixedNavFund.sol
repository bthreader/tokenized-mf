// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";

contract FixedNavFund is AbstractFund {
    
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
        uint256 executableShares;
        uint256 amountToTransfer;

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

            // Cash the candidate needs                     
            uint256 requiredBalance = price * candidateShares;

            //
            // Check what we can potentially close
            //
            
            // Buyer cannot fulfill what they have placed
            if (balance < requiredBalance) {
                executableShares = balance / price;
                _navBuyOrders.changeSharesOnId({
                    id : head,
                    add : false,
                    shares : executableShares
                });

                // Move the head over to the next ID
                head = _navSellOrders.next(head);
                remainingSharesToExecute -= executableShares;
            }

            // Buyer can fulfill what they have placed
            else {
                executableShares = candidateShares;
                _navSellOrders.dequeue();
                head = _navSellOrders._headId();
            }

            //
            // Close
            //

            _transfer({
                from : msg.sender,
                to : candidateAddr,
                amount : executableShares
            });

            amountToTransfer = executableShares * price;
            _brokerageAccounts[candidateAddr] -= amountToTransfer;
            payable(msg.sender).transfer(amountToTransfer);
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

    function closeNavOrders()
        external
        override
        onlyAdmin
    {
        uint256 price = navPerShare();
        address clientAddr;
        uint256 clientShares;
        uint256 head;

        // Outstanding buy orders
        if (_navBuyOrders._headId() != 0) {
            head = _navBuyOrders._headId();
            while (head != 0) {
                (clientAddr, clientShares)
                    = _navBuyOrders.getOrderDetails(head);
                
                if (_brokerageAccounts[clientAddr] >= price) {
                    // Execute the maximum they can afford of the order
                    uint256 executableShares = _min(
                        _brokerageAccounts[clientAddr] / price,
                        clientShares
                    );
                    unchecked {
                        _brokerageAccounts[clientAddr] 
                            -= (executableShares * price);
                    }

                    _mint({addr : clientAddr, amount : executableShares});
                }
                
                _navBuyOrders.dequeue();
                head = _navBuyOrders._headId();
            }
        }

        // Outstanding sell orders
        else if (_navSellOrders._headId() != 0) {
            head = _navSellOrders._headId();
            while (head != 0) {
                (clientAddr, clientShares)
                    = _navSellOrders.getOrderDetails(head);

                payable(clientAddr).transfer(price * clientShares);
                _burn({addr : clientAddr, amount : clientShares});

                _navSellOrders.dequeue();
                head = _navSellOrders._headId();
            }
        }

        // Book is already balanced
        else {
            return;
        }
    }

    function myBrokerageAccountBalance() external view returns (uint256) {
        return _brokerageAccounts[msg.sender];
    }

    function getOrderDetails(uint256 id, bool buy) 
        external 
        view 
        returns (address addr, uint256 shares)
    {
        if (buy) {return _navBuyOrders.getOrderDetails(id);}
        else {return _navSellOrders.getOrderDetails(id);}
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

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
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
