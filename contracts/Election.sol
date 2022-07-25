// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Election {
    uint public votesToAdd;
    uint public votesToRemove;
    mapping(address => bool) public hasVoted;

    modifier notVoted(address voterAddr) {
        require(
            hasVoted[voterAddr] == false,
            "Admin has already voted"
        );
        _;
    }

    function voteToAdd(address voterAddr) notVoted(voterAddr) public {
        votesToAdd += 1;
        hasVoted[voterAddr] = true;
    }

    function voteToRemove(address voterAddr) notVoted(voterAddr) public {
        votesToRemove += 1;
        hasVoted[voterAddr] = true;
    } 
}