// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract AbstractVerify {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    mapping(address => bool) private _verifiedAddresses;
    mapping(address => bool) private _verifiers;
    mapping(address => uint256) internal _balances;

    /// -----------------------------
    ///         Events
    /// -----------------------------

    /**
     *  @dev Emitted when `admin` adds a `verifier` to the contract
     */
    event VerifierAdded(
        address indexed verifier,
        address indexed admin
    );

    /**
     *  @dev Emitted when `admin` removes `verifier` from contract
     */
    event VerifierRemoved(
        address indexed verifier,
        address indexed admin
    );

    /**
     *  @dev Emitted when a `verifier` verifies an address `addr`
     */
    event VerifiedAddressAdded(
        address indexed addr,
        address indexed verifier
    );

    /**
     *  @dev Emitted when a `verifier` removes an address `addr` from
     *  the verified addresses
     */
    event VerifiedAddressRemoved(
        address indexed addr,
        address indexed verifier
    );

    /// -----------------------------
    ///         Modifiers
    /// -----------------------------
    
    modifier onlyAdmin virtual;
    
    modifier onlyVerifier {
        require(
            _verifiers[msg.sender] == true,
            "Verify: you are not a verifier"
        );
        _;
    }

    modifier onlyVerified {
        require(
            _verifiedAddresses[msg.sender] == true,
            "Verify: you are not verified"
        );
        _;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------    

    /**
     * @param addr The address to add as a verifier
     */ 
    function addVerifier(address addr) external onlyAdmin {
        require(
            addr != address(0),
            "Verify: zero address cannot be a verifier"
        );
        
        require(
            _verifiers[addr] != true,
            "Verify: address is already a verififer"
        );

        _verifiers[addr] = true;
        emit VerifierAdded({verifier : addr, admin : msg.sender});
    }

    /**
     * @param addr The address to remove from verifiers
     */
    function removeVerifier(address addr) external onlyAdmin {
        require(
            _verifiers[addr] == true,
            "Verify: cannot remove non-verifier address"
        );

        _verifiers[addr] = false;
        emit VerifierRemoved({verifier : addr, admin : msg.sender});
    }

    /**
     * @param addr The address to verify
     */
    function addVerified(address addr) external onlyVerifier {
        require(
            addr != address(0),
            "Verify: cannot verify zero address"
        );

        require(
            _verifiedAddresses[addr] != true,
            "Verify: address already verified"
        );
            
        _verifiedAddresses[addr] = true;
        emit VerifiedAddressAdded({addr : addr, verifier : msg.sender});
    }

    /**
     * @param addr The address to remove from verified
     */
    function removeVerified(address addr) external onlyVerifier {
        require(
            _balances[addr] == 0,
            "Verify: cannot remove an address that has tokens"
        );
        
        _verifiedAddresses[addr] = false;
        emit VerifiedAddressRemoved({addr : addr, verifier : msg.sender});
    }

    /// -----------------------------
    ///         Public
    /// -----------------------------

    function isVerified(address addr) public view returns (bool) {
        return _verifiedAddresses[addr];
    }

    function isVerifier(address addr) public view returns (bool) {
        return _verifiers[addr];
    }
}