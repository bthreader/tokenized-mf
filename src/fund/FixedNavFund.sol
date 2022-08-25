// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Fund} from "./Fund.sol";

contract FixedNavFund is Fund {
    
    /// -----------------------------
    ///         External
    /// -----------------------------

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

                payable(clientAddr).transfer(price * clientShares);
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

    /// -----------------------------
    ///         Public
    /// -----------------------------
    
    /**
     * @dev See {AbstractFund-nav}.
     */
    function nav() public pure override returns (uint256) {
        return 100;
    }
}
