// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Fund} from "./Fund.sol";
import {Asset} from "../asset/Asset.sol";

contract InvestedFund is Fund {
    
    /// -----------------------------
    ///         State
    /// -----------------------------

    Asset[] private _investments;
    uint256[] private _weights;
    uint256 private _nInvestments;

    constructor (Asset[] memory investments, uint256[] memory weights) {
        require(
            investments.length == weights.length,
            "Fund: length mismatch between investments and weights"
        );
        require(
            _sum(weights) == 100,
            "Fund: weights must add to 100"
        );
        
        _investments = investments;
        _nInvestments = investments.length;
        _weights = weights;
    }

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

    /**
     * @dev Allows the creator to set the share price in first instance.
     */
    function topUp() external payable {}

    /**
     * @dev Entry point to rebalance the fund using _allocate
     */
    function rebalance() external onlyAdmin {
        _allocate(nav());
    }

    /// -----------------------------
    ///         Public
    /// -----------------------------

    function valueOfInvestments() public view returns (uint256) {
        uint256 total;
        uint256 shares;
        uint256 price;

        for (uint i = 0; i < _nInvestments; ++i) {
            shares = _investments[i].balanceOf(address(this));
            price = _investments[i].pricePerShare();
            total += shares * price;
        }

        return total;
    } 

    function nav() public view override returns (uint256) {
        return valueOfInvestments() + address(this).balance;
    }

    function ownedShares() 
        public 
        view 
        returns (uint256[] memory shares) 
    {
        shares = new uint256[](_nInvestments);
        for (uint256 i = 0; i < _nInvestments; ++i) {
            shares[i] = _investments[i].balanceOf(address(this));
        }
    }

    /// -----------------------------
    ///         Private
    /// -----------------------------
    
    /**
     * @dev Invests `amount` according to the weightings. Analyses existing
     * investments to determine what changes need to be made.
     */
    function _allocate(uint256 amount) private {
        // Decide some allocation
        uint256[] memory proposedShares = new uint256[](_nInvestments);
        
        for (uint i = 0; i < _nInvestments; ++i) {
            uint256 targetAmount = (amount * _weights[i]) / 100;
            uint256 price = _investments[i].pricePerShare();
            proposedShares[i] = targetAmount / price;
        }

        uint256[] memory actualShares = ownedShares();

        //
        // Check existing positions - liquidate or buy where necessary
        //
        
        // Iterate through all adjustments
        // Action the sell adjustments
        // Save the buy adjustments to memory for later
        uint256[] memory buyIndices = new uint256[](_nInvestments);
        uint256 buyIndex = 0;

        for (uint256 i = 0; i < _nInvestments; ++i) {
            if (proposedShares[i] < actualShares[i]) {
                unchecked{
                    _investments[i].sell(actualShares[i] - proposedShares[i]);
                }
            }

            else if (proposedShares[i] > actualShares[i]) {
                buyIndices[buyIndex] = i;
                buyIndex += 1;
            }
            
            else {
                continue;
            }
        }

        // Do the buy adjustments
        for (uint256 i = 0; i < buyIndex; ++i) {
            uint256 index = buyIndices[i];
            uint256 sharesToBuy = proposedShares[index] - actualShares[index];
            uint256 amountToSend = _investments[index].pricePerShare() * sharesToBuy;
            unchecked{
                _investments[i].buy{ value : amountToSend }(sharesToBuy);
            }
        }
    }

    /**
     * @dev Ensures there is `amount` of cash available in the contract.
     * Won't do anything if required position alread exists.
     */
    function _createCashPosition(uint256 amount) private {
        if (address(this).balance >= amount) {
            return;
        }

        // Free up the cash
        else {
            uint256 requiredCash = amount - address(this).balance;
            uint256 investableCash = valueOfInvestments() - requiredCash;
            _allocate(investableCash);
            return;
        }
    }

    function _sum(uint256[] memory array) private pure returns (uint256 sum) {
        for (uint256 i = 0; i < array.length; ++i) {
            sum += array[i];
        }
    }
}
