// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractVerify} from "./AbstractVerify.sol";
import {Election} from "./Election.sol";

contract ComplexVerify is AbstractVerify {
    uint256 internal _totalAdmins;
    mapping(address => bool) internal _admins;
    mapping(address => Election) internal _elections;
    address[] private _candidates;

    constructor() {
        _admins[msg.sender] = true;
        _totalAdmins = 1;
    }
    
    /**
     *  @dev Emitted when admin(s) add an `admin` to the contract
     */
    event AdminAdded(
        address indexed admin
    );

    /**
     *  @dev Emitted when admin(s) remove an `admin` from the contract
     */
    event AdminRemoved(
        address indexed admin
    );
    
    modifier onlyAdmin override {
        require(
            _admins[msg.sender] == true,
            "You are not an admin"
        );
        _;
    }

    /// @param candidateAddr The election candidate being voted on
    /// @param voterAddr The address voting on the candidates election
    function vote(address candidateAddr, address voterAddr) private {
        if (address(_elections[candidateAddr]) == address(0x0)) {
            newElectionWithVote({
                candidateAddr: candidateAddr,
                voterAddr: voterAddr
            });
        }

        else {
            _elections[candidateAddr].vote(voterAddr);
        }
    }

    /// @param candidateAddr The candidate we're creating an election for
    /// @param voterAddr The address voting on the candidates election
    function newElectionWithVote(address candidateAddr, address voterAddr) private {
        // Create new election
        Election election = new Election();
        election.vote(voterAddr);
        
        // Save state
        _elections[candidateAddr] = election;
        _candidates.push(candidateAddr);
    }

    /// @param election The election we're comparing votes with #admins
    function majorityAchieved(Election election) private view returns (bool) {
        if (election.votes() > (_totalAdmins / 2)) {
            return true;
        }
        return false;
    }

    /// @param candidateAddr The candidate whose election we want to delete
    function deleteElection(address candidateAddr) private {
        delete _elections[candidateAddr];
        
        uint256 i = 0;
        while (_candidates[i] != candidateAddr) {
            i+=1; 
        }

        _candidates[i] = _candidates[_candidates.length - 1];
        _candidates.pop();
    }

    /// @param voterToRemove The address whose votes we want to remove
    function removeVoterFromElections(address voterToRemove) private { 
        uint256 i = 0;
        for (i; i<_candidates.length; i++) {
            if (_elections[_candidates[i]].hasVoted(voterToRemove) == true) {
                _elections[_candidates[i]].removeVote(voterToRemove);
            }
        }
    }

    /// @param candidateAddr The non-admin address we want to vote to add
    function voteToAdd(address candidateAddr) public onlyAdmin {
        require(
            _admins[candidateAddr] != true,
            "This address has already been added as an admin"
        );
        
        vote({candidateAddr: candidateAddr, voterAddr: msg.sender});

        if (majorityAchieved(_elections[candidateAddr])) { 
            _admins[candidateAddr] = true;
            _totalAdmins += 1;
            deleteElection(candidateAddr);
            emit AdminAdded(candidateAddr);
        }
    }

    /// @param candidateAddr The admin address we want to vote to remove
    function voteToRemove(address candidateAddr) public onlyAdmin {
        require(
            _admins[candidateAddr] == true,
            "Can't remove an address which is not an admin"
        );

        vote({candidateAddr: candidateAddr, voterAddr: msg.sender});

        if (majorityAchieved(_elections[candidateAddr])) { 
            _admins[candidateAddr] = false;
            _totalAdmins -= 1;
            deleteElection(candidateAddr);
            removeVoterFromElections(candidateAddr);
            emit AdminRemoved(candidateAddr);
        }
    }
}