// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Verify {
    mapping(address => bool) internal verifiedAddresses;
    mapping(address => bool) internal verifiers;
       
    /**
     * @dev Check if the sender has the right role.
     */
    
    modifier onlyAdmin virtual {
        // Everyone is an admin
        require(
            true,
            "You are not an admin"
        );
        _;
    }
    
    modifier onlyVerifier {
        require(
            verifiers[msg.sender] == true,
            "You are not a verifier"
        );
        _;
    }

    modifier onlyVerified {
        require(
            verifiedAddresses[msg.sender] == true,
            "You are not verified"
        );
        _;
    }

    /**
     * @dev Add verifier to the contract.
     */
    function addVerifier(address addr) onlyAdmin public {       
        require(
            addr != address(0),
            "Zero address cannot be a verifier"
        );
        
        require(
            verifiers[addr] != true,
            "Address is already a verififer"
        );

        verifiers[addr] = true;
    }

    /**
     * @dev Remove verifier from the contract.
     */
    function removeVerifier(address addr) onlyAdmin public {
        require(
            verifiers[addr] == true,
            "Cannot remove an address that is not already a verifier"
        );

        verifiers[addr] = false;
    }

    /**
     * @dev Adds verified address to the contract.
     */
    function addVerified(address addr) onlyVerifier public {
        require(
            addr != address(0),
            "Cannot verify the zero address"
        );

        require(
            verifiedAddresses[addr] != true,
            "Address is already verified"
        );
            
        verifiedAddresses[addr] = true;
    }

    /**
     * @dev Removes verified address from the contract.
     */
    function removeVerified(address addr) onlyVerifier public {      
        verifiedAddresses[addr] = false;
    }
    
    /**
     * @dev Checks if a address is verified
     */
    function isVerified(address addr) public view returns (bool) {
        if (verifiedAddresses[addr] == true) {
            return true;
        }

        return false;
    }

    /**
     * @dev Checks if an address is a verifier
     */
    function isVerifier(address addr) public view returns (bool) {
        if (verifiers[addr] == true) {
            return true;
        }

        return false;
    }
}