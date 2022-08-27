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
    function placeBuyNavOrder(uint256 shares)
        external
        payable
        override
        onlyVerified
        sharesNotZero(shares)
    {
        require(
            msg.value > 0,
            "Fund: msg.value must be greater than zero to place buy order"    
        );
        uint256 price = navPerShare();
    
        //
        // Prep to traverse sell queue
        //
        
        address candidateAddr;
        uint256 candidateShares;
        uint256 sharesToExecute = _min(shares, (msg.value / price));
        
        // Refund is in order
        if ((sharesToExecute * price) < msg.value) {
            payable(msg.sender).transfer(
                msg.value - (sharesToExecute * price)
            );
        }

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

        // Finished with the sell queue
        // Mint remaining if necessary
        if (remainingSharesToExecute != 0) {
            _mint({addr : msg.sender, amount : remainingSharesToExecute});
        }
    }

    /**
     * @dev See {AbstractFund-placeSellNavOrder}.
     */
    function placeSellNavOrder(uint256 shares) 
        external 
        override
        onlyVerified
        sharesNotZero(shares)
        returns (uint256 orderId) 
    {
        require(
            _balances[msg.sender] >= shares,
            "Fund: insufficient balance to place sell order"
        );
        unchecked{
            _balances[msg.sender] -= shares;
            _custodyAccounts[msg.sender] += shares;
        }
        
        orderId = _navSellOrders.enqueue({
            addr : msg.sender,
            shares : shares
        });
    }

    /**
     * @dev See {AbstractFund-closeNavOrders}.
     */
    function closeNavOrders()
        external
        override
        onlyAccountant
    {
        uint256 price = navPerShare();
        address clientAddr;
        uint256 clientShares;
        uint256 head;

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
                    sellOrderId : head
                });

                _navSellOrders.dequeue();
                head = _navSellOrders._headId();
            }
        }

        // Book is already balanced
        return;
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
