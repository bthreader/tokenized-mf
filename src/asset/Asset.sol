// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {AssetInterface} from "./AssetInterface.sol";

contract Asset is AssetInterface {
    
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
    
    function buy(uint256 shares) external payable {
        // Calculate the price
        uint256 price = (address(this).balance - msg.value) / _totalShares;
        
        // Wrong amount sent, send a refund then throw
        if (msg.value != price * shares) {
            payable(msg.sender).transfer(msg.value);
            require(
                false,
                "Asset: didn't send the right amount of money"
            );
        }
        
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