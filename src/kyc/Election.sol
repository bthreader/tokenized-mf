// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Election {
   
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    uint256 public _votes;
    mapping(address => bool) public _hasVoted;

    /// -----------------------------
    ///         External
    /// -----------------------------

    /**
     *  @param voterAddr The address voting on the election
     */
    function vote(address voterAddr) external {
        require(
            _hasVoted[voterAddr] == false,
            "Election: Address has already voted"
        );
        
        _votes += 1;
        _hasVoted[voterAddr] = true;
    }

    /**
     * @param voterAddr The address voting on the election
     */ 
    function removeVote(address voterAddr) external {
        require(
            _hasVoted[voterAddr] == true,
            "Election: Address has not voted"
        );
        
        _votes -= 1;
        _hasVoted[voterAddr] = false;
    }
}