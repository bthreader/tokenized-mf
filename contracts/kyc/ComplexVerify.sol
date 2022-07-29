// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/kyc/Verify.sol";
import "contracts/kyc/Election.sol";

// Instantiate verify with zero address
// Doesn't matter because we're overriding admins anyway
contract ComplexVerify is Verify {
    uint internal totalAdmins;
    mapping(address => bool) internal admins;
    mapping(address => bool) internal hasElection;
    mapping(address => Election) internal elections;
    address[] private candidates;

    constructor() {
        admins[msg.sender] = true;
        totalAdmins = 1;
    }
    
    modifier onlyAdmin override {
        require(
            admins[msg.sender] == true,
            "You are not an admin"
        );
        _;
    }

    function vote(address candidateAddr, address voterAddr) private {
        if (hasElection[candidateAddr] == false) {
            newElectionWithVote(candidateAddr,voterAddr);
        }

        else {
            elections[candidateAddr].vote(voterAddr);
        }
    }

    function newElectionWithVote(address candidateAddr, address voterAddr) private {
        // Create new election
        Election election = new Election();
        election.vote(voterAddr);
        
        // Save state
        elections[candidateAddr] = election;
        candidates.push(candidateAddr);
        hasElection[candidateAddr] = true;
    }

    function majorityAchieved(Election election) private view returns (bool) {
        if (election.votes() > (totalAdmins / 2)) {
            return true;
        }
        return false;
    }

    function deleteElection(address candidateAddr) private {
        hasElection[candidateAddr] = false;
        delete elections[candidateAddr];
        
        uint i = 0;
        while (candidates[i] != candidateAddr) {
            i+=1; 
        }

        candidates[i] = candidates[candidates.length - 1];
        candidates.pop();
    }

    function removeVoterFromElections(address voterToRemove) private { 
        uint i = 0;
        for (i; i<candidates.length; i++) {
            if (elections[candidates[i]].hasVoted(voterToRemove) == true) {
                elections[candidates[i]].removeVote(voterToRemove);
            }
        }
    }

    function voteToAdd(address candidateAddr) onlyAdmin public {
        require(
            admins[candidateAddr] != true,
            "This address has already been added as an admin"
        );
        
        vote(candidateAddr, msg.sender);

        if (majorityAchieved(elections[candidateAddr])) { 
            admins[candidateAddr] = true;
            totalAdmins += 1;
            deleteElection(candidateAddr);
        }
    }

    function voteToRemove(address candidateAddr) onlyAdmin public {
        require(
            admins[candidateAddr] == true,
            "Can't remove an address which is not an admin"
        );

        vote(candidateAddr, msg.sender);

        if (majorityAchieved(elections[candidateAddr])) { 
            admins[candidateAddr] = false;
            totalAdmins -= 1;
            deleteElection(candidateAddr);
            removeVoterFromElections(candidateAddr);
        }
    }
}