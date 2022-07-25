// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/Verify.sol";
import "contracts/Election.sol";

// Instantiate verify with zero address
// Doesn't matter because we're overriding admins anyway
contract ComplexVerify is Verify {
    uint internal totalAdmins;
    mapping(address => bool) internal admins;
    
    mapping(address => bool) internal hasElection;
    mapping(address => Election) internal elections;

    constructor(address firstAdmin) {
        admins[firstAdmin] = true;
        totalAdmins = 1;
    }
    
    modifier senderIsAdmin override {
        require(
            admins[msg.sender] == true,
            "You are not an admin"
        );
        _;
    }

    function voteToAdd(address addr) senderIsAdmin public {
        require(
            admins[addr] != true,
            "This address has already been added as an admin"
        );
        
        if (hasElection[addr] == false) {
            elections[addr] = new Election();
            hasElection[addr] = true;
            elections[addr].voteToAdd(msg.sender);
        }

        else {
            elections[addr].voteToAdd(msg.sender);
        }

        // Check the election in relation to the majority
        if (elections[addr].votesToAdd() > (totalAdmins / 2)) {
            // The majority have voted in favour
            // Add address as an admin
            admins[addr] = true;
            totalAdmins += 1;
            
            // Election has ended
            delete elections[addr];
            hasElection[addr] = false;
        }
    }

    function voteToRemove(address addr) senderIsAdmin public {
        require(
            admins[addr] == true,
            "Can't remove an address which is not an admin"
        );

        if (hasElection[addr] == false) {
            elections[addr] = new Election();
            hasElection[addr] = true;
            elections[addr].voteToRemove(msg.sender);
        }

        else {
            elections[addr].voteToRemove(msg.sender);
        }

        // Check the election in relation to consensus
        if (elections[addr].votesToRemove() > (totalAdmins / 2)) {
            admins[addr] = true;
            totalAdmins -= 1;
            
            // We don't need to store the election anymore
            delete elections[addr];
            hasElection[addr] = false;
        }
    }
}