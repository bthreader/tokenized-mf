// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractFund} from "./AbstractFund.sol";
import {Asset} from "../asset/Asset.sol";

contract InvestedFund is AbstractFund {
    
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
    ///         Events
    /// -----------------------------

    event Rebalance(uint256[] newShares, address caller);

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
        uint256 oldNav = nav() - msg.value;
        uint256 price = oldNav / _totalShares;
        uint256 sharesToExecute = _handleBuyCash({
            addr : msg.sender,
            money : msg.value,
            price : price
        });
        _mint({addr : msg.sender, amount : sharesToExecute});
        _allocate(nav());
    }

    /**
     * @dev Burns shares and pays seller. Creates a cash position 
     * where necessary.
     */
    function placeSellNavOrder(uint256 shares) 
        external 
        onlyVerified
        sharesNotZero(shares) 
    {
        require(
            _balances[msg.sender] >= shares,
            "Fund: insufficient balance to place sell order"
        );
        uint256 price = navPerShare();
        uint256 money = price * shares;
        _createCashPosition(money);
        payable(msg.sender).transfer(money);
        _burn({addr : msg.sender, amount : shares});
    }

    /**
     * @dev External entry point to rebalance the fund. For use when there
     * is no buy / sell activity and the value of the underlying investments
     * have changed.
     */
    function rebalance() external {
        _allocate(nav());
        emit Rebalance(ownedShares(), msg.sender);
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

    fallback() external payable {}

    /// -----------------------------
    ///         Internal
    /// -----------------------------

    /**
     * @dev Ensures there is `amount` of cash available in the contract.
     * Won't do anything if required position alread exists.
     */
    function _createCashPosition(uint256 amount) internal {
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

    /// -----------------------------
    ///         Private
    /// -----------------------------
    
    /**
     * @dev Invests `amount` according to the weightings. Analyses existing
     * investments to determine what changes need to be made.
     */
    function _allocate(uint256 amount) private {
        // Get current allocation
        uint256[] memory actualShares = ownedShares();
        
        // Decide some new allocation
        uint256[] memory proposedShares = new uint256[](_nInvestments);
        for (uint i = 0; i < _nInvestments; ++i) {
            uint256 targetAmount = (amount * _weights[i]) / 100;
            uint256 price = _investments[i].pricePerShare();
            proposedShares[i] = targetAmount / price;
        }
        
        // Iterate through each investments
        // Action sell orders on investments that need adjustmenting down
        // Save the buy adjustments to memory for later
        
        uint256[] memory buyIndices = new uint256[](_nInvestments);
        uint256 buyIndex = 0;
        
        for (uint256 i = 0; i < _nInvestments; ++i) {
            if (proposedShares[i] < actualShares[i]) {
                _investments[i].sell(actualShares[i] - proposedShares[i]);
            }
            else if (proposedShares[i] > actualShares[i]) {
                buyIndices[buyIndex] = i;
                buyIndex += 1;
            }
            else {continue;}
        }

        // Do the buy adjustments
        for (uint256 i = 0; i < buyIndex; ++i) {
            uint256 index = buyIndices[i];
            uint256 sharesToBuy = proposedShares[index] - actualShares[index];
            uint256 amountToSend = 
                _investments[index].pricePerShare() * sharesToBuy;
            unchecked{
                _investments[i].buy{ value : amountToSend }();
            }
        }
    }

    function _sum(uint256[] memory array) private pure returns (uint256 sum) {
        for (uint256 i = 0; i < array.length; ++i) {
            sum += array[i];
        }
    }
}
