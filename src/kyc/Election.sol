// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Election {
   
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    uint256 public votes;
    mapping(address => bool) public hasVoted;

    /// -----------------------------
    ///         External
    /// -----------------------------

    /**
     *  @param voterAddr The address voting on the election
     */
    function vote(address voterAddr) external {
        require(
            hasVoted[voterAddr] == false,
            "Address has already voted"
        );
        
        votes += 1;
        hasVoted[voterAddr] = true;
    }

    /**
     * @param voterAddr The address voting on the election
     */ 
    function removeVote(address voterAddr) external {
        require(
            hasVoted[voterAddr] == true,
            "Address has not voted"
        );
        
        votes -= 1;
        hasVoted[voterAddr] = false;
    }
}