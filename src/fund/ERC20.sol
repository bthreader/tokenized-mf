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
    mapping(address => bool) private _accountants;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    /**
     *  @dev Emitted when `admin` adds a `verifier` to the contract
     */
    event AccountantAdded(
        address indexed accountant,
        address indexed admin
    );

    /**
     *  @dev Emitted when `admin` removes `verifier` from contract
     */
    event AccountantRemoved(
        address indexed accountant,
        address indexed admin
    );

    /// -----------------------------
    ///         Modifiers
    /// -----------------------------

    modifier onlyAccountant() {
        require(
            _accountants[msg.sender],
            "ERC20: you are not an accountant"
        );
        _;
    }

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
    )
        external 
        onlyVerified 
        returns (bool) 
    {
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
        onlyAccountant
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

    /**
     * @dev Returns the amount of tokens in existence
     */
    function totalSupply() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Returns the amount of tokens owned by `account`
     */
    function balanceOf(address account) external view returns (uint256) {
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
        external 
        view
        returns (uint256) 
    {
        return _allowances[owner][spender];
    }

    function addAccountant(address addr) external onlyAdmin {
        require(
            _accountants[addr] == false,
            "ERC20: accountant already added"
        );
        
        _accountants[addr] = true;
        emit AccountantAdded({accountant : addr, admin : msg.sender});
    }

    function removeAccountant(address addr) external onlyAdmin {
        require(
            _accountants[addr],
            "ERC20: address is not an accountant"
        );
        
        _accountants[addr] = false;
        emit AccountantRemoved({accountant : addr, admin : msg.sender});
    }

    function isAccountant(address addr) external view returns (bool) {
        return _accountants[addr];
    }

    /// ----------------------------
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
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 amount) internal {
        unchecked {
            _balances[from]-= amount;
            _balances[to] += amount;
        }
        emit Transfer({from : from, to : to, value : amount});
    }

    /**
     * @dev Mints shares and assigns them to `addr`
     *
     * Emits a {Transfer} event.
     */
    function _mint(address addr, uint256 amount) internal {
        _balances[addr] += amount;
        _totalShares += amount;
        emit Transfer(address(0), addr, amount);
    }

    /**
     * @dev Removes `amount` from the balance of `addr` and takes them out of
     * circulation.
     *
     * Emits a {Transfer} event.
     */
    function _burn(address addr, uint256 amount) internal {
        require(
            _balances[addr] >= amount,
            "ERC20: burn amount exceeds balance"
        );
        _balances[addr] -= amount;
        _totalShares -= amount;
        emit Transfer(addr, address(0), amount);
    }
}