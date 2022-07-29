// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/kyc/ComplexVerify.sol";

abstract contract AbstractFund is ComplexVerify {
    uint public totalShares;
    mapping(address => uint) public balances;
    
    modifier sharesNotZero(uint shares) {
        require(
            shares != 0,
            "Cannot perform zero share operations"
        );
        _;
    }
    
    function price() public virtual returns (uint) {}
    function buyShares(uint shares) onlyVerified sharesNotZero(shares) payable public virtual {}
    function redeemShares(uint shares) onlyVerified sharesNotZero(shares) public virtual {}
}