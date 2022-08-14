// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {ComplexVerify} from "../kyc/ComplexVerify.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract ERC20 is ComplexVerify, IERC20 {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    uint256 public _totalShares;
    mapping(address => mapping(address => uint256)) internal _allowances;

    /// ----------------------------
    ///         External
    /// ----------------------------

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 amount) 
        external 
        onlyVerified 
        returns (bool)
    {
        require(
            isVerified(to),
            "ERC20: can only transfer to verified customers"
        );
        require(
            _balances[msg.sender] >= amount,
            "ERC20: insufficient funds to make transfer"
        );

        _transfer({from : msg.sender, to : to, amount : amount});
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount)
        external 
        onlyVerified 
        returns (bool)
    {
        require(
            isVerified(spender),
            "ERC20: can only provide allowances to verified customers"
        );
        
        _approve({
            owner : msg.sender,
            spender : spender,
            amount : amount
        });
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the
     * caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) 
        external 
        onlyVerified 
        returns (bool)
    {
        require(
            isVerified(spender),
            "ERC20: cannot modify the allowance of a non-verified customer"
        );
        
        _approve({
            owner : msg.sender,
            spender : spender,
            amount : _allowances[msg.sender][spender] + addedValue
        });
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the 
     * caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) 
        external 
        onlyVerified 
        returns (bool)
    {
        require(
            isVerified(spender),
            "ERC20: cannot modify the allowance of a non-verified customer"
        );
        
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: cannot decrease allowance below zero"
        );


        _approve({
            owner : msg.sender,
            spender : spender,
            amount : currentAllowance - subtractedValue
        });
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external onlyVerified returns (bool) {
        require(
            isVerified(to),
            "ERC20: can only provide allowances to verified customers"
        );
        require(
            _allowances[from][msg.sender] >= amount,
            "ERC20: insufficient allowance to transfer"
        );
        require(
            _balances[from] >= amount,
            "ERC20: owner has insufficient funds"
        );

        unchecked {
            _allowances[from][msg.sender] -= amount;
        }
        _transfer({from : from, to: to, amount : amount});
        return true;
    }

     /**
     * @dev Moves shares from a users previous address to their new one
     */
    function burnAndReissue(address oldAddr, address newAddr) 
        external 
        onlyAdmin
    {
        require(isVerified(oldAddr), "Fund: old address isn't verified");
        require(
            isVerified(newAddr),
            "Fund: verify the new address first"
        );        
        
        uint256 oldBalance = _balances[oldAddr];

        _burn(oldAddr, oldBalance);
        _mint(newAddr, oldBalance);
    }

    /// ----------------------------
    ///         Public
    /// ----------------------------

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) 
        public 
        view
        returns (uint256) 
    {
        return _allowances[owner][spender];
    }


    /// -----------------------------
    ///         Internal
    /// ----------------------------

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s 
     * tokens.
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        _allowances[owner][spender] = amount;
        emit Approval({owner : owner, spender : spender, value : amount});
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s 
     * tokens.
     *
     *
     * Emits an {Transfer} event.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        unchecked {
            _balances[from]-= amount;
            _balances[to] += amount;
        }
        emit Transfer({from : from, to : to, value : amount});
    }

    /**
     * @dev Sets `shares` and assigns them to `addr`
     */
    function _mint(address addr, uint256 shares) internal {
        _balances[addr] += shares;
        _totalShares += shares;
        emit Transfer(address(0), addr, shares);
    }

    /**
     * @dev Removes `shares` from the balance of `addr` and takes them out of
     * circulation.
     */
    function _burn(address addr, uint256 shares) internal {
        require(
            _balances[addr] >= shares,
            "ERC20: burn amount exceeds balance"
        );
        _balances[addr] -= shares;
        _totalShares -= shares;
        emit Transfer(addr, address(0), shares);
    }
}