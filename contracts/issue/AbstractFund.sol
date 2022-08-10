// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ComplexVerify} from "contracts/kyc/ComplexVerify.sol";

abstract contract AbstractFund is ComplexVerify {
    uint256 public _totalShares;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    modifier sharesNotZero(uint256 shares) {
        require(
            shares != 0,
            "Cannot perform zero share operations"
        );
        _;
    }
    
    function price() public view virtual returns (uint);
    
    function placeBuyNavOrder(uint256 shares)
        public
        payable
        virtual
        onlyVerified
        sharesNotZero(shares) {}
    
    function placeSellNavOrder(uint256 shares) 
        public 
        virtual
        onlyVerified 
        sharesNotZero(shares) {}

    function burnAndReissue(address oldAddr, address newAddr) 
        public 
        onlyAdmin 
    {
        transferFrom({from : oldAddr, to : newAddr, amount : _balances[oldAddr]});
    }

    /**
     * @dev Returns the amount of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) private returns (bool) {
        _balances[to] = amount;
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens
     *
     * @return boolean success or failure
     */
    function approve(address spender, uint256 amount) private returns (bool) {
        require(isVerified(spender), "Can only provide allowances to verified customers");

        _allowances[msg.sender][spender] = amount;
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) 
        public 
        onlyVerified 
        returns (bool)
    {
        return approve({
            spender : spender,
            amount : allowance(msg.sender, spender) + addedValue
        });
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) 
        public 
        onlyVerified 
        returns (bool)
    {
        return approve({
            spender : spender,
            amount : allowance(msg.sender, spender) - subtractedValue
        });
    }

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        require(isVerified(from), "Can only provide allowances to verified customers");
        require(isVerified(to), "Can only provide allowances to verified customers");
        require(_balances[from] >= amount, "Insufficient balance to transfer");

        _balances[to] += amount;
        _balances[from] -= amount; 
        return true;
    }
}