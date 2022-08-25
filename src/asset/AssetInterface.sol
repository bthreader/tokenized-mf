// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface AssetInterface {
    function buy(uint256 shares) external payable;
    function sell(uint256 shares) external;
    function balanceOf(address addr) external view returns (uint256);
    function topUp() external payable;
    function withdraw(uint256 amount) external;
    function pricePerShare() external view returns (uint256);
}