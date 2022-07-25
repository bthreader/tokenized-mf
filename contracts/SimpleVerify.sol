// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "contracts/Verify.sol";

contract SimpleVerify is Verify {
    address internal admin;

    constructor() {
        admin = msg.sender;
    }

    modifier senderIsAdmin override {
        require(
            admin == msg.sender,
            "You are not an admin"
        );
        _;
    }
}