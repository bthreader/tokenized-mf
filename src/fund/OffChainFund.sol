// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Fund} from "./Fund.sol";

contract OffChainFund is Fund {

    uint256 private _nav;

    /// -----------------------------
    ///         External
    /// -----------------------------

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

    function setNav(uint256 value) external onlyAccountant {
        _nav = value;
    }

    function withdraw(uint256 amount) external onlyAccountant {
        payable(msg.sender).transfer(amount);
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
    ///         Internal
    /// -----------------------------

    /**
     * @dev See {Fund-_createCashPosition}
     */
    function _createCashPosition(uint256 amount) internal view override {
        require(
            amount <= address(this).balance,
            "Fund: run out of money to close sell orders"
        );
    }
}
