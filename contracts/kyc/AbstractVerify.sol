// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

abstract contract AbstractVerify {
    mapping(address => bool) private _verifiedAddresses;
    mapping(address => bool) private _verifiers;

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
    
    modifier onlyAdmin virtual;
    
    modifier onlyVerifier {
        require(
            _verifiers[msg.sender] == true,
            "You are not a verifier"
        );
        _;
    }

    modifier onlyVerified {
        require(
            _verifiedAddresses[msg.sender] == true,
            "You are not verified"
        );
        _;
    }

    /// @param addr The address to add as a verifier
    function addVerifier(address addr) public onlyAdmin {
        require(
            addr != address(0),
            "Zero address cannot be a verifier"
        );
        
        require(
            _verifiers[addr] != true,
            "Address is already a verififer"
        );

        _verifiers[addr] = true;
        emit VerifierAdded({verifier : addr, admin : msg.sender});
    }

    /// @param addr The address to remove from verifiers
    function removeVerifier(address addr) public onlyAdmin {
        require(
            _verifiers[addr] == true,
            "Cannot remove an address that is not already a verifier"
        );

        _verifiers[addr] = false;
        emit VerifierRemoved({verifier : addr, admin : msg.sender});
    }

    /// @param addr The address to verify
    function addVerified(address addr) public onlyVerifier {
        require(
            addr != address(0),
            "Cannot verify the zero address"
        );

        require(
            _verifiedAddresses[addr] != true,
            "Address is already verified"
        );
            
        _verifiedAddresses[addr] = true;
        emit VerifiedAddressAdded({addr : addr, verifier : msg.sender});
    }

    /// @param addr The address to remove from verified
    function removeVerified(address addr) public onlyVerifier {
        _verifiedAddresses[addr] = false;
        emit VerifiedAddressRemoved({addr : addr, verifier : msg.sender});
    }
    
    /// @dev Public view of verified addresses for auditing purposes
    function isVerified(address addr) public view returns (bool) {
        return _verifiedAddresses[addr];
    }

    /// @dev Public view of verified addresses for auditing purposes
    function isVerifier(address addr) public view returns (bool) {
        return _verifiers[addr];
    }
}