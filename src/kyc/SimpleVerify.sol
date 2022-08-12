// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractVerify} from "./AbstractVerify.sol";

contract SimpleVerify is AbstractVerify {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    address internal _admin;

    constructor() {
        _admin = msg.sender;
    }

    /// -----------------------------
    ///         Modifiers
    /// -----------------------------

    modifier onlyAdmin override {
        require(
            _admin == msg.sender,
            "You are not an admin"
        );
        _;
    }
}