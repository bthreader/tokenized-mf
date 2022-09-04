// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAsset} from "./IAsset.sol";

contract Asset is IAsset {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    mapping(address => uint256) private _balances;
    uint256 private _totalShares;

    constructor () {
        _balances[msg.sender] = 1;
        _totalShares = 1;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------
    
    function buy() external payable {
        // Calculate the price
        uint256 price = (address(this).balance - msg.value) / _totalShares;
        uint256 shares = msg.value / price;
        _totalShares += shares;
        _balances[msg.sender] += shares;
    }

    function sell(uint256 shares) external {   
        require(
            _balances[msg.sender] >= shares,
            "Asset: cannot sell more shares than you own"
        );
        payable(msg.sender).transfer(shares * pricePerShare());
        _totalShares -= shares;
        _balances[msg.sender] -= shares;
    }

    function balanceOf(address addr) external view returns (uint256) {
        return _balances[addr];
    }

    function topUp() external payable {}

    function withdraw(uint256 amount) external {
        require(
            amount <= address(this).balance,
            "Asset: cannot withdraw more that is within the contract"
        );
        
        payable(msg.sender).transfer(amount);
    }

    /// -----------------------------
    ///         Public
    /// -----------------------------

    function pricePerShare() public view returns (uint256) {
        return address(this).balance / _totalShares;
    }
}
