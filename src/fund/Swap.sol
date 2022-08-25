// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {FixedNavFund} from "./FixedNavFund.sol";

contract Swap {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    FixedNavFund public _assetA;
    FixedNavFund public _assetB;

    constructor (FixedNavFund assetA, FixedNavFund assetB) {
        _assetA = assetA;
        _assetB = assetB;
    }

    /// -----------------------------
    ///         External
    /// -----------------------------

    /**
     * @dev Called when some criteria is met
     */
    function swap(
        address counterpartyA, 
        address counterpartyB, 
        uint256 amountAssetA,
        uint256 amountAssetB
    )
        external 
    {
        _assetA.transferFrom({
            from: counterpartyA, 
            to: counterpartyB,
            amount: amountAssetA
        });

        _assetB.transferFrom({
            from: counterpartyB, 
            to: counterpartyA,
            amount: amountAssetB
        });
    }
}
