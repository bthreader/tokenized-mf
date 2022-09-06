// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";
import {NavOrderQueue} from "../order/NavOrderQueue.sol";

contract OffChainFund is AbstractFund {

    /// -----------------------------
    ///         State
    /// -----------------------------
    
    NavOrderQueue internal _navSellOrders;
    mapping(address => uint256) internal _custodyAccounts;
    uint256 private _nav;

    constructor() {
        _navSellOrders = new NavOrderQueue();
    }
    
    /// -----------------------------
    ///         Events
    /// -----------------------------

    event NavUpdated(uint256 value);
    event Withdrawal(uint256 amount, address to);
    event QueuedOrderActioned(
        address indexed buyer, 
        address indexed seller, 
        uint256 shares,
        uint256 price,
        bool partiallyExecuted,
        uint256 sellOrderId
    );

    /// -----------------------------
    ///         External
    /// -----------------------------
    
    /**
     * @dev See {AbstractFund-placeBuyNavOrder}.
     */
    function placeBuyNavOrder()
        external
        payable
        override
        onlyVerified
    {
        uint256 price = navPerShare();

        uint256 remainingSharesToExecute = _handleBuyCash({
            addr : msg.sender,
            money : msg.value,
            price : price
        });
    
        //
        // Traverse sell queue
        //
        
        address candidateAddr;
        uint256 candidateShares;
        uint256 head = _navSellOrders._headId();

        /**
         * @dev While there are
         * -> Outstanding shares in the order
         * -> Sellers to sell them
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

                // Update the sell order details
                _navSellOrders.changeSharesOnId({
                    id : head, 
                    add : false,
                    shares : remainingSharesToExecute 
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
     * @dev Queues a sell order.
     */
    function placeSellNavOrder(uint256 shares) 
        external
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
     * @dev Removes a sell order (with id=`id`) from the queue if it exists
     * and the caller is the owner of the order. This ensures clients can't
     * cancel other clients orders.
     */
    function cancelQueuedSellNavOrder(uint256 id) 
        external  
        onlyVerified 
    {
        // Make sure it was the sender who owns the order
        (address addr, uint256 shares) = _navSellOrders.getOrderDetails(id);
        require(
            addr != address(0),
            "Fund: order not in queue"
        );
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

    function getQueuedSellNavOrderDetails(uint256 id) 
        external 
        view 
        returns (address addr, uint256 shares)
    {
        return _navSellOrders.getOrderDetails(id);
    }

    function myCustodyAccountBalance() 
        external 
        view 
        onlyVerified 
        returns (uint256) 
    {
        return _custodyAccounts[msg.sender];
    }

    function cashNeededToCloseSellOrders() external view returns (uint256) {
        uint256 price = navPerShare();
        uint256 total;
        
        uint256 head = _navSellOrders._headId();
        uint256 clientShares;
        address clientAddr;
        
        while (head != 0) {
            (clientAddr, clientShares) = _navSellOrders.getOrderDetails(head);
            total += clientShares;
            head = _navSellOrders.next(head);
        }

        return total * price;
    }

    /**
     * @dev Closes sell orders in the queue, will throw when out of cash.
     */
    function closeSellNavOrders()
        external
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
                require(
                    owedCash <= address(this).balance,
                    "Fund: run out of money to close sell orders"
                );
                payable(clientAddr).transfer(owedCash);
                _burnFromCustodyAccount({
                    addr : clientAddr,
                    amount : clientShares
                });

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

        // No sell orders outstanding
        return;
    }

    function setNav(uint256 value) external onlyAccountant {
        _nav = value;
        emit NavUpdated(value);
    }

    function withdraw(uint256 amount) external onlyAccountant {
        payable(msg.sender).transfer(amount);
        emit Withdrawal({amount : amount, to : msg.sender});
    }

    /// -----------------------------
    ///         Public
    /// -----------------------------
    
    /**
     * @dev See {AbstractFund-nav}.
     */
    function nav() public view override returns (uint256) {
        return _nav;
    }

    /// -----------------------------
    ///         Private
    /// -----------------------------

    function _burnFromCustodyAccount(address addr, uint256 amount) private {
        _custodyAccounts[addr] -= amount;
        _totalShares -= amount;
        emit Transfer(addr, address(0), amount);
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
