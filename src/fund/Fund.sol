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
        sharesNotZero(shares)
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

    /**
     * @dev See {AbstractFund-closeNavOrders}.
     */
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
                    
                    // Log
                    emit QueuedOrderActioned({
                        buyer : clientAddr,
                        seller : address(this),
                        shares : executableShares,
                        price : price,
                        partiallyExecuted : clientShares != executableShares,
                        buyOrderId : head,
                        sellOrderId : 0
                    });
                }
                
                _navBuyOrders.dequeue();
                head = _navBuyOrders._headId();
            }
        }

        // Outstanding sell orders
        if (_navSellOrders._headId() != 0) {
            head = _navSellOrders._headId();
            while (head != 0) {
                (clientAddr, clientShares)
                    = _navSellOrders.getOrderDetails(head);

                uint256 owedCash = price * clientShares;
                _createCashPosition(owedCash);
                payable(clientAddr).transfer(owedCash);
                _burn({addr : clientAddr, amount : clientShares});

                // Log
                emit QueuedOrderActioned({
                    buyer : address(this),
                    seller : clientAddr,
                    shares : clientShares,
                    price : price,
                    partiallyExecuted : false,
                    buyOrderId : 0,
                    sellOrderId : head
                });

                _navSellOrders.dequeue();
                head = _navSellOrders._headId();
            }
        }

        // Book is already balanced
        return;
    }

    function cancelBuyNavOrder(uint256 id) external override onlyVerified {
        // Make sure it was the sender who owns the order
        (address addr, uint256 shares) = _navBuyOrders.getOrderDetails(id);
        require(
            msg.sender == addr,
            "Fund: must be the order placer to cancel the order"
        );
        _navBuyOrders.deleteId(id);
    }

    function cancelSellNavOrder(uint256 id) external override onlyVerified {
        // Make sure it was the sender who owns the order
        (address addr, uint256 shares) = _navSellOrders.getOrderDetails(id);
        require(
            msg.sender == addr,
            "Fund: must be the order placer to cancel the order"
        );
        _navSellOrders.deleteId(id);
        _transferFromCustodyAccount({
            from : msg.sender,
            to : msg.sender, 
            amount : shares
        });
    }

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {return a;}
        return b;
    }
    
    /**
     * @dev Ensures there is `amount` of cash available in the contract.
     * Won't do anything if required position alread exists.
     */
    function _createCashPosition(uint256 amount) internal virtual;

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

    function _transferFromCustodyAccount(
        address from,
        address to, 
        uint256 amount
    ) 
        private 
    {
        unchecked {
            _custodyAccounts[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer({from : from, to : to, value : amount});
    }
}
