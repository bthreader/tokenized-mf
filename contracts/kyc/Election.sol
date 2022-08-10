// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Election {
    uint256 public votes;
    mapping(address => bool) public hasVoted;

    /// @param voterAddr The address voting on the election
    function vote(address voterAddr) public {
        require(
            hasVoted[voterAddr] == false,
            "Admin has already voted"
        );
        
        votes += 1;
        hasVoted[voterAddr] = true;
    }

    /// @param voterAddr The address voting on the election
    function removeVote(address voterAddr) public {
        require(
            hasVoted[voterAddr] == true,
            "Admin has not voted"
        );
        
        votes -= 1;
        hasVoted[voterAddr] = false;
    }
}