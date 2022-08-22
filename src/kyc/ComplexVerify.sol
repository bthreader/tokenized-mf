// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractVerify} from "./AbstractVerify.sol";
import {Election} from "./Election.sol";

contract ComplexVerify is AbstractVerify {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    uint256 private _totalAdmins;
    mapping(address => bool) private _admins;
    mapping(address => Election) private _elections;
    address[] private _candidates;

    constructor() {
        _admins[msg.sender] = true;
        _totalAdmins = 1;
    }

    /// -----------------------------
    ///         Events
    /// -----------------------------
    
    /**
     * @dev Emitted when admin(s) add an `admin` to the contract
     */
    event AdminAdded(address indexed admin);

    /**
     * @dev Emitted when admin(s) remove an `admin` from the contract
     */
    event AdminRemoved(address indexed admin);

    /**
     * @dev Emitted when admin(s) remove an `admin` from the contract
     */
    event VoteToAddPlaced(address indexed voter, address indexed candidate);

    /**
     * @dev Emitted when admin(s) remove an `admin` from the contract
     */
    event VoteToRemovePlaced(
        address indexed voter,
        address indexed candidate
    );

    /// -----------------------------
    ///         Modifiers
    /// -----------------------------
        
    modifier onlyAdmin override {
        require(
            _admins[msg.sender] == true,
            "Verify: you are not an admin"
        );
        _;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------    

    /**
     * @param candidateAddr The non-admin address we want to vote to add
     */
    function voteToAdd(address candidateAddr) external onlyAdmin {
        require(
            _admins[candidateAddr] != true,
            "Verify: this address has already been added as an admin"
        );
        
        _vote({candidateAddr: candidateAddr, voterAddr: msg.sender});
        emit VoteToAddPlaced({voter : msg.sender, candidate: candidateAddr});

        if (_majorityAchieved(_elections[candidateAddr])) { 
            _admins[candidateAddr] = true;
            _totalAdmins += 1;
            _deleteElection(candidateAddr);
            emit AdminAdded(candidateAddr);
        }
    }

    /**
     * @param candidateAddr The admin address we want to vote to remove
     */
    function voteToRemove(address candidateAddr) external onlyAdmin {
        require(
            _admins[candidateAddr] == true,
            "Verify: can't remove an address which is not an admin"
        );

        _vote({candidateAddr: candidateAddr, voterAddr: msg.sender});
        emit VoteToRemovePlaced({
            voter : msg.sender,
            candidate: candidateAddr
        });

        if (_majorityAchieved(_elections[candidateAddr])) { 
            _admins[candidateAddr] = false;
            _totalAdmins -= 1;
            _deleteElection(candidateAddr);
            _removeVoterFromElections(candidateAddr);
            emit AdminRemoved(candidateAddr);
        }
    }

    function totalAdmins() 
        external
        view 
        onlyAdmin 
        returns (uint256) 
    {
        return _totalAdmins;
    }
    
    function isAdmin(address addr) 
        external
        view 
        onlyAdmin 
        returns (bool) 
    {
        return _admins[addr];
    }

    function getElection(address addr)
        external
        view
        onlyAdmin
        returns (Election)
    {
        return _elections[addr];
    }

    function getCandidates() 
        external
        view
        onlyAdmin
        returns (address[] memory)
    {
        return _candidates;
    }
    
    /// -----------------------------
    ///         Private
    /// ----------------------------- 
    
    /**
     * @param candidateAddr The election candidate being voted on
     * @param voterAddr The address voting on the candidates election
     */
    function _vote(address candidateAddr, address voterAddr) private {
        if (address(_elections[candidateAddr]) == address(0x0)) {
            _newElection(candidateAddr);
        }

        _elections[candidateAddr].vote(voterAddr);
    }

    /**
     * @param candidateAddr The candidate we're creating an election for
     */
    function _newElection(address candidateAddr)
        private
    {
        // Create new election
        Election election = new Election();
        
        // Save state
        _elections[candidateAddr] = election;
        _candidates.push(candidateAddr);
    }

    /**
     * @param election The election we're comparing votes with #admins
     */
    function _majorityAchieved(Election election) private view returns (bool) {
        if (election._votes() > (_totalAdmins / 2)) {
            return true;
        }
        return false;
    }

    /**
     * @param candidateAddr The candidate whose election we want to delete
     */ 
    function _deleteElection(address candidateAddr) private {
        delete _elections[candidateAddr];
        
        uint256 i = 0;
        while (_candidates[i] != candidateAddr) {
            i+=1; 
        }

        _candidates[i] = _candidates[_candidates.length - 1];
        _candidates.pop();
    }

    /**
     * @param voterToRemove The address whose votes we want to remove
     */ 
    function _removeVoterFromElections(address voterToRemove) private { 
        uint256 i = 0;
        for (i; i<_candidates.length; i++) {
            if (_elections[_candidates[i]]._hasVoted(voterToRemove) == true) {
                _elections[_candidates[i]].removeVote(voterToRemove);
            }
        }
    }
}
