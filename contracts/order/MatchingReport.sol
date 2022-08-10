// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Match} from "./Match.sol";

contract MatchingReport {
    uint public _matchedVolume;
    Match[] public _matches;

    constructor (Match[] memory matches, uint matchedVolume) {
        _matches = matches;
        _matchedVolume = matchedVolume;
    }
}