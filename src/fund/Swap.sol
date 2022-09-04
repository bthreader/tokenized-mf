// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {OffChainFund} from "./OffChainFund.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Swap {
    
    /// -----------------------------
    ///         State
    /// -----------------------------
    
    address public _assetA;
    address public _assetB;

    constructor (address assetA, address assetB) {
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
        IERC20(_assetA).transferFrom({
            from: counterpartyA, 
            to: counterpartyB,
            amount: amountAssetA
        });

        IERC20(_assetB).transferFrom({
            from: counterpartyB, 
            to: counterpartyA,
            amount: amountAssetB
        });
    }
}
